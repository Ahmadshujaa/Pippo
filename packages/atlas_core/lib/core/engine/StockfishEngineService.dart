import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'package:atlas_core/core/async/isolate_worker.dart';
import 'package:atlas_core/core/async/perf_trace.dart';
import 'package:atlas_core/core/engine/StockfishApiService.dart';
import 'package:atlas_core/core/engine/engine_handle.dart';
import 'package:atlas_core/core/engine/engine_models.dart';
import 'package:atlas_core/core/engine/stockfish_output_parser.dart';
import 'package:atlas_core/core/engine/stockfish_worker.dart';

export 'package:atlas_core/core/engine/engine_models.dart'
    show AnalysisLine, AnalysisResult;

class StockfishEngineService implements EngineHandle {
  static StockfishEngineService? _instance;
  Process? _process;
  bool _isReady = false;
  String? _lastFen;

  // -------------------------------------------------------------------------
  // Background parsing worker.
  //
  // All Stockfish output parsing (FEN checks, PV -> SAN conversion, throttle
  // bookkeeping) happens inside a dedicated isolate so the UI isolate never
  // generates legal moves while the engine searches. When isolate spawning is
  // unavailable (unexpected platform restriction), the service transparently
  // falls back to a pure-Dart in-place parser with identical behaviour.
  // -------------------------------------------------------------------------
  IsolateWorker? _worker;
  StockfishOutputParser? _fallbackParser;
  bool _workerMode = false;

  // Resolves once the engine has answered `readyok` after being started,
  // so callers can await startup before issuing a search. See start().
  Completer<void>? _readyCompleter;
  Completer<void>? _uciCompleter;
  Future<void>? _startFuture;

  // Search Synchronization
  bool _isSynchronizing = false;
  String? _pendingFen;
  int? _pendingDepth;
  int? _pendingSearchGeneration;

  // Each search owns a generation. Results and completion messages from an
  // older generation are ignored even if they arrive after a new search has
  // already started in the parser isolate.
  int _nextSearchGeneration = 0;
  int? _activeSearchGeneration;

  // Publishing Throttle
  int _minDepth = 6;
  int _depthInterval = 3;

  final _resultController = StreamController<AnalysisResult>.broadcast();
  @override
  Stream<AnalysisResult> get analysisStream => _resultController.stream;

  final _outputController = StreamController<String>.broadcast();
  @override
  Stream<String> get outputStream => _outputController.stream;

  final _exclusiveAvailabilityController = StreamController<void>.broadcast();
  Stream<void> get exclusiveAvailabilityStream =>
      _exclusiveAvailabilityController.stream;

  StockfishEngineService();

  /// Lazily-created shared instance. The Analysis screen, PippoPlayScreen and
  /// GameReview all drive this one process. Background puzzle generation
  /// creates its OWN instance via `StockfishEngineService()` so two engine
  /// processes can run side by side without their searches interleaving.
  static StockfishEngineService get instance {
    _instance ??= StockfishEngineService();
    return _instance!;
  }

  @override
  bool get isReady => _isReady;

  bool get hasExclusiveOwner => _exclusiveOwner != null;

  /// Acquires the shared-engine lease for [owner]. Re-entrant acquisition by
  /// the same owner is supported so nested flows can clean up independently.
  bool tryAcquireExclusive(String owner) {
    if (_exclusiveOwner != null && _exclusiveOwner != owner) return false;
    _exclusiveOwner ??= owner;
    _exclusiveLeaseCount++;
    return true;
  }

  /// Releases one lease held by [owner]. A different owner cannot release it.
  void releaseExclusive(String owner) {
    if (_exclusiveOwner != owner) return;
    _exclusiveLeaseCount--;
    if (_exclusiveLeaseCount <= 0) {
      _exclusiveLeaseCount = 0;
      _exclusiveOwner = null;
      _exclusiveAvailabilityController.add(null);
    }
  }

  // -------------------------------------------------------------------------
  // Engine performance knobs (tunable per device class).
  //
  // Exynos 7884-class phones (Galaxy A20e) have only two fast Cortex-A73
  // cores; the other six are slow A53 efficiency cores. A depth-24 search
  // never completes on this hardware, so with two threads the engine pins
  // BOTH fast cores at 100% forever, leaving the Flutter UI thread to fight
  // for scraps on the same cores. That is the root cause of the lag spikes
  // every time the user makes a move or navigates: the UI thread is starved.
  //
  // One thread keeps one fast core entirely free for the UI. The search is
  // ~30% slower, but the app stays buttery-smooth, which matters far more on
  // a low-end device. This mirrors what Chess.com/Lichess do for on-device
  // analysis.
  // -------------------------------------------------------------------------
  static const int _hashSizeMb = 32;
  bool _searchActive = false;
  int? _activeDepth;

  // Full-game analysis can outlive its screen, so it holds an exclusive lease
  // on this shared engine. Interactive screens use [hasExclusiveOwner] to
  // avoid interrupting that run.
  String? _exclusiveOwner;
  int _exclusiveLeaseCount = 0;

  /// Explicit thread override (0 = automatic, device-aware default).
  int _threadsOverride = 0;

  @override
  Future<void> start() async {
    if (_process != null && _isReady) return;
    if (_startFuture != null) return _startFuture!;
    _startFuture = _startInternal();
    try {
      await _startFuture;
    } finally {
      _startFuture = null;
    }
  }

  Future<void> _startInternal() async {
    if (_process != null && _isReady) return;

    try {
      dev.log('Starting Stockfish engine...');
      // Spawn the output-parsing worker first so no engine line is ever lost
      // to an un-ready parser; a platform restriction falls back to in-isolate
      // parsing via [_dispatchParseLine].
      await _ensureWorker();
      // Set up the completer before spawning the process so awaiting start()
      // guarantees `readyok` has been received, and an immediate analyze()
      // is not dropped because the engine is not marked ready yet.
      _isReady = false;
      _uciCompleter = Completer<void>();
      _readyCompleter = Completer<void>();
      await StockfishApiService.prepareBinary();
      final binaryPath = await StockfishApiService.getInternalBinaryPath();

      final file = File(binaryPath);
      if (!await file.exists()) {
        throw Exception('Engine binary not found at $binaryPath');
      }

      dev.log('Executing process: $binaryPath');
      _process = await Process.start(binaryPath, []).catchError((e) {
        dev.log('Process.start error: $e');
        throw e;
      });
      final process = _process!;

      // Listen to stdout
      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            // Always parse internally: readyok drives the search
            // synchronization below.
            _onEngineLine(line);
          });

      // Listen to stderr for debugging
      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            dev.log('Stockfish STDERR: $line');
          });

      process.exitCode.then((code) {
        if (identical(_process, process)) {
          dev.log('Stockfish exited with code $code');
          _process = null;
          _isReady = false;
          _searchActive = false;
        }
      });

      _sendCommand('uci');
      await _uciCompleter!.future.timeout(const Duration(seconds: 10));
      // Keep one core available for Flutter, while allowing newer phones to
      // use more than the old universal one-thread setting. Stockfish itself
      // scales this safely across the device's CPU count.
      final threadCount = _effectiveThreadCount;
      _sendCommand('setoption name Threads value $threadCount');
      _sendCommand('setoption name Hash value $_hashSizeMb');
      setLines(2);
      _sendCommand('isready');

      dev.log('Stockfish process started.');
    } catch (e) {
      dev.log('Failed to start Stockfish: $e');
      _process?.kill();
      _process = null;
      // Drop the ready completer so a failed start does not leave callers
      // permanently awaiting readiness.
      _readyCompleter = null;
      _uciCompleter = null;
      rethrow;
    }

    // Wait until the engine acknowledges `readyok` before returning, so the
    // caller (e.g. the analysis screen's start button) can safely issue a
    // search right away without it being gated out by the isReady flag.
    final ready = _readyCompleter?.future;
    if (ready != null) {
      // A bounded failure timeout prevents a broken native process from
      // blocking the UI forever; readiness is still accepted only by readyok.
      await ready.timeout(const Duration(seconds: 10));
    }
  }

  @override
  void send(String command) {
    _sendCommand(command);
  }

  @override
  void setOption(String name, String value) {
    _sendCommand('setoption name $name value $value');
  }

  /// snake_case alias kept for callers that use it (e.g.
  /// MoveClassificationService.analyzePosition).
  // ignore: non_constant_identifier_names
  void set_option(String name, String value) => setOption(name, value);

  void _sendCommand(String command) {
    if (_process == null) {
      dev.log('Attempted to send command "$command" but process is null.');
      return;
    }
    _process!.stdin.writeln(command);
  }

  @override
  void setLines(int lines) {
    _configuredLines = lines.clamp(1, 3);
    // Classification only needs the top 2 candidates (the great/brilliant
    // gap logic reads the second line), so always search at least 2 lines
    // even when the UI shows one; honor 3 only when the user selects it.
    final internalLines = math.max(_configuredLines, 2);
    _sendCommand('setoption name MultiPV value $internalLines');
    _pushParserConfig();
  }

  void setThrottle({int minDepth = 6, int depthInterval = 3}) {
    _minDepth = minDepth;
    _depthInterval = depthInterval;
    _pushParserConfig();
  }

  /// Overrides the Stockfish worker-thread count (0 = automatic).
  ///
  /// The automatic default keeps one fast core free for the Flutter UI on
  /// low-end Androids; individual device classes can tune this further from
  /// settings without restarting the engine.
  void setThreads(int threads) {
    _threadsOverride = threads > 0 ? threads : 0;
    if (_isReady) {
      _sendCommand('setoption name Threads value $_effectiveThreadCount');
    }
  }

  /// Recommended thread count for this device.
  ///
  /// Stockfish scales `Threads` safely, but on phones the render thread shares
  /// the CPU with the engine. Phones with up to 6 cores (including the common
  /// 2-fast + 4/6-slow big.LITTLE layouts) get at most 2 engine threads so a
  /// fast core stays free for the UI; larger devices can afford 4.
  int _recommendedThreadCount() {
    if (!Platform.isAndroid) {
      return math.max(1, math.min(4, Platform.numberOfProcessors - 1));
    }
    final cores = Platform.numberOfProcessors;
    final available = (cores - 1).clamp(1, 4);
    return cores <= 6 ? math.min(available, 2) : math.min(available, 4);
  }

  int get _effectiveThreadCount =>
      _threadsOverride > 0 ? _threadsOverride : _recommendedThreadCount();

  @override
  void analyze(String fen, {int depth = 24}) {
    if (_process == null) return;

    // Board notifications and classification reflow can arrive more than
    // once for the same position. Restarting an identical search throws away
    // the depth it just reached (the visible symptom is depth 10 -> 0 -> 10)
    // and can prevent classification from ever receiving its result.
    if (_isSynchronizing && _pendingFen == fen && _pendingDepth == depth) {
      return;
    }
    if (!_isSynchronizing &&
        _searchActive &&
        _lastFen == fen &&
        _activeDepth == depth) {
      return;
    }

    // Invalidate the previous search before sending the stop command. This
    // prevents its tail output from changing active-search bookkeeping while
    // the new position is being synchronized.
    _searchActive = false;
    _activeDepth = null;
    _activeSearchGeneration = null;

    final generation = ++_nextSearchGeneration;

    // Delegate state reset + PV legality bookkeeping to the parser (isolate or
    // in-place). The parser is authoritative about how many PV lines to wait
    // for from this position.
    _beginSearch(fen, generation: generation, targetDepth: depth);

    // Begin synchronization: stop the previous search, set the new position,
    // and wait for readyok before sending go. This is the UCI acknowledgement
    // boundary; never replace it with a sleep or elapsed-time guess.
    _isSynchronizing = true;
    _pendingFen = fen;
    _pendingDepth = depth;
    _pendingSearchGeneration = generation;
    _lastFen = null; // Don't tag output until sync is complete

    _sendCommand('stop');
    _sendCommand('position fen $fen');
    _sendCommand('isready');
  }

  void _startPendingSearch() {
    final fen = _pendingFen;
    final depth = _pendingDepth;
    final generation = _pendingSearchGeneration;
    if (fen != null && depth != null && generation != null) {
      _lastFen = fen;
      _searchActive = true;
      _activeDepth = depth;
      _activeSearchGeneration = generation;
      _isSynchronizing = false;
      _pendingFen = null;
      _pendingDepth = null;
      _pendingSearchGeneration = null;

      // Resume the parser before `go` so the first info line cannot beat the
      // worker's resume message and get discarded as synchronization noise.
      _resumeSearch(fen, generation: generation);
      _sendCommand('go depth $depth');
    }
  }

  @override
  void stop() {
    _searchActive = false;
    _activeDepth = null;
    _activeSearchGeneration = null;
    _pendingFen = null;
    _pendingDepth = null;
    _pendingSearchGeneration = null;
    _isSynchronizing = false;
    _lastFen = null;
    _sendCommand('stop');
  }

  void dispose() {
    if (_process != null) _sendCommand('quit');
    _process?.kill();
    _process = null;
    _isReady = false;
    _pendingFen = null;
    _pendingDepth = null;
    _pendingSearchGeneration = null;
    _isSynchronizing = false;
    _activeSearchGeneration = null;
    _exclusiveOwner = null;
    _exclusiveLeaseCount = 0;
    _worker?.dispose();
    _worker = null;
    _workerMode = false;
    _resultController.close();
    _outputController.close();
    _exclusiveAvailabilityController.close();
  }

  int _configuredLines = 3;

  // -------------------------------------------------------------------------
  // Engine line routing.
  // -------------------------------------------------------------------------

  /// Handles every raw line from the engine's stdout.
  ///
  /// `uciok` / `readyok` stay here (they drive readiness and the search
  /// synchronization handshake); everything else is handed to the parser,
  /// which runs in a worker isolate when possible.
  void _onEngineLine(String line) {
    line = line.trim();
    if (line == 'uciok') {
      final completer = _uciCompleter;
      if (completer != null && !completer.isCompleted) completer.complete();
      if (!_isSynchronizing) _outputController.add(line);
      return;
    }
    if (line == 'readyok') {
      _isReady = true;
      dev.log('Stockfish engine ready.');

      // Signal any awaiters (e.g. first engine start on the analysis screen)
      // that the engine is now ready to accept a search.
      final completer = _readyCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
        _readyCompleter = null;
      }

      if (_isSynchronizing) {
        _startPendingSearch();
      }

      if (!_isSynchronizing) _outputController.add(line);
      return;
    }

    if (line.startsWith('info ') || line.startsWith('bestmove ')) {
      // The process can emit tail lines after `stop`, and it can emit the old
      // search's tail while the replacement position is waiting for readyok.
      // Neither belongs to a live parser session.
      if (_isSynchronizing || !_searchActive) return;
      _dispatchParseLine(line);
      _outputController.add(line);
      return;
    }

    // Raw broadcast gating: while a previous search is being stopped and a
    // new one synchronized (_isSynchronizing), the engine still emits tail
    // "info" lines for the OLD position. Raw-listener consumers (e.g. move
    // classification) cannot tell which position a line belongs to, so that
    // window must never reach them.
    if (!_isSynchronizing) {
      _outputController.add(line);
    }
  }

  /// Routes parser work to the worker isolate, or to the in-place parser when
  /// no worker is available (spawn failure / fallback mode).
  void _dispatchParseLine(String line) {
    final worker = _worker;
    if (_workerMode && worker != null && worker.isReady) {
      worker.send([kStockfishWorkerCmdLine, line]);
      return;
    }
    _handleParserOutcome(_fallbackParser?.handleLine(line));
  }

  void _handleParserOutcome(StockfishParseOutcome? outcome) {
    PerfTrace.start('sf-parse');
    if (outcome == null) return;
    final publish = outcome.publish;
    if (publish != null &&
        _searchActive &&
        publish.generation == _activeSearchGeneration) {
      _resultController.add(publish);
    }
    if (outcome.searchEnded && outcome.generation == _activeSearchGeneration) {
      _searchActive = false;
      _activeDepth = null;
      _activeSearchGeneration = null;
    }
    PerfTrace.end('sf-parse');
  }

  /// Inbound messages from the [IsolateWorker]. Both event kinds are simple
  /// tagged lists so the protocol stays stable across refactors.
  void _handleWorkerMessage(Object? message) {
    if (message is! List || message.isEmpty) return;
    switch (message[0]) {
      case kStockfishWorkerTagPublish:
        final result = message[1];
        if (result is AnalysisResult &&
            _searchActive &&
            result.generation == _activeSearchGeneration) {
          _resultController.add(result);
        }
        break;
      case kStockfishWorkerTagEnded:
        final generation = message.length > 1 ? message[1] : null;
        if (generation is int && generation == _activeSearchGeneration) {
          _searchActive = false;
          _activeDepth = null;
          _activeSearchGeneration = null;
        }
        break;
    }
  }

  /// Spawns the parsing worker. Failures are non-fatal: the service falls
  /// back to the in-place [StockfishOutputParser].
  Future<void> _ensureWorker() async {
    if (_workerMode && _worker != null) return;
    final worker = _worker;
    if (worker != null) {
      worker.dispose();
      _worker = null;
    }
    try {
      _worker = await IsolateWorker.start(
        stockfishWorkerEntry,
        onMessage: _handleWorkerMessage,
        debugName: 'stockfish-parser',
      );
      _workerMode = true;
      _pushParserConfig();
      dev.log('Stockfish parser running in a background isolate.');
    } catch (e) {
      _workerMode = false;
      _worker = null;
      _fallbackParser ??= StockfishOutputParser();
      _pushParserConfig();
      dev.log(
        'Isolate unavailable for stockfish parsing, using in-place parser: $e',
      );
    }
  }

  void _beginSearch(
    String fen, {
    required int generation,
    required int targetDepth,
  }) {
    final worker = _worker;
    if (_workerMode && worker != null && worker.isReady) {
      worker.send([
        kStockfishWorkerCmdBegin,
        fen,
        generation,
        targetDepth,
      ]);
      return;
    }
    _fallbackParser?.beginSearch(
      fen,
      generation: generation,
      targetDepth: targetDepth,
    );
  }

  void _resumeSearch(String fen, {required int generation}) {
    final worker = _worker;
    if (_workerMode && worker != null && worker.isReady) {
      worker.send([kStockfishWorkerCmdResume, fen, generation]);
      return;
    }
    _fallbackParser?.resumeSearch(fen, generation: generation);
  }

  void _pushParserConfig() {
    final worker = _worker;
    if (_workerMode && worker != null && worker.isReady) {
      worker.send([
        kStockfishWorkerCmdConfigure,
        _configuredLines,
        _minDepth,
        _depthInterval,
      ]);
      return;
    }
    _fallbackParser?.configure(
      lines: _configuredLines,
      minDepth: _minDepth,
      depthInterval: _depthInterval,
    );
  }
}
