import 'dart:async';
import 'dart:developer' as dev;

import 'package:atlas_core/core/analysis/MoveClassificationService.dart';
import 'package:atlas_core/core/analysis/classification_worker.dart';
import 'package:atlas_core/core/async/isolate_worker.dart';

/// Runs [MoveClassificationService] classification jobs on a background
/// isolate so the expensive brilliancy / sacrifice computation never stalls
/// the UI thread.
///
/// When the isolate cannot be spawned (or dies), it transparently falls back
/// to computing inline on the caller's isolate — behaviour degrades to the
/// original synchronous path rather than erroring.
class ClassificationScheduler {
  ClassificationScheduler._();

  static ClassificationScheduler? _instance;
  static ClassificationScheduler get instance =>
      _instance ??= ClassificationScheduler._();

  IsolateWorker? _worker;
  bool _starting = false;
  int _nextId = 0;
  final Map<Object, Completer<ClassificationResult>> _pending = {};

  /// Schedules a single classification job and awaits its result.
  Future<ClassificationResult> classify({
    required String fenBefore,
    required String moveUci,
    required PositionAnalysis analysisBefore,
    required PositionAnalysis analysisAfter,
    PositionAnalysis? analysisPrevious,
  }) async {
    final worker = await _ensureWorker();
    if (worker == null) {
      // Fallback: compute on the caller's isolate (the pre-isolate behaviour).
      return MoveClassificationService.instance.classifyWithData(
        fenBefore: fenBefore,
        moveUci: moveUci,
        analysisBefore: analysisBefore,
        analysisAfter: analysisAfter,
        analysisPrevious: analysisPrevious,
      );
    }

    final id = _nextId++;
    final completer = Completer<ClassificationResult>();
    _pending[id] = completer;
    worker.send([
      id,
      fenBefore,
      moveUci,
      analysisBefore,
      analysisAfter,
      analysisPrevious,
    ]);
    return completer.future;
  }

  Future<IsolateWorker?> _ensureWorker() async {
    if (_worker?.isReady ?? false) return _worker;

    // Serialize concurrent lazy-start requests.
    while (_starting) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    _starting = true;
    try {
      _worker = await IsolateWorker.start(
        classificationWorkerEntry,
        onMessage: _onMessage,
        debugName: 'move-classifier',
      );
    } catch (e) {
      _worker = null;
      dev.log('Move-classification isolate unavailable; running inline: $e');
    } finally {
      _starting = false;
    }
    return _worker;
  }

  void _onMessage(Object? message) {
    if (message is! List || message.length < 3) return;
    final Object tag = message[0];
    final Object id = message[1];
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;

    if (tag == kClassificationWorkerTagOk) {
      completer.complete(message[2] as ClassificationResult);
    } else {
      completer.completeError(
        StateError('Classification job failed: ${message[2]}'),
      );
    }
  }

  void dispose() {
    _worker?.dispose();
    _worker = null;
    final failures = _pending.values.toList();
    _pending.clear();
    for (final c in failures) {
      if (!c.isCompleted) {
        c.completeError(StateError('Classification scheduler disposed'));
      }
    }
  }
}