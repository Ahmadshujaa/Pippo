import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:atlas_core/atlas_core.dart';
import 'package:atlas_ui/shared/widgets/ChessboardMotion.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettingsDialog.dart';
import 'package:atlas_ui/shared/widgets/ChessboardTransitions.dart';

import 'package:atlas_ui/features/analysis/widgets/MoveClassificationUI.dart';

/// Yellow arrow drawn from the best move's origin square to its destination
/// square (the "show me the best move" marker on the analysis / review view).
const Color _kBestMoveArrowColor = Color(0xE6F5C518);

/// Fraction of one square's size used as the arrow shaft width.
const double _kBestMoveArrowWidthFactor = 0.22;

/// Fraction of one square's size the shaft is shortened at each end so the
/// arrow visually connects piece centres without fully covering them.
const double _kBestMoveArrowInsetFactor = 0.3;

/// Fraction of one square's size used as the arrowhead length.
const double _kBestMoveArrowHeadFactor = 0.4;

/// The 12 piece asset codes (color prefix + piece letter) used to render a
/// full piece set. Used by asset warm-up and the per-square piece lookup.
const List<String> _kPieceCodes = [
  'wK', 'wQ', 'wR', 'wB', 'wN', 'wP',
  'bK', 'bQ', 'bR', 'bB', 'bN', 'bP',
];

/// Paints the yellow best-move arrow over the board.
///
/// Square coordinates are mapped exactly like the board's own squares
/// (`_buildSquare`): for White orientation fileIndex 0..7 is 'a'..'h' with
/// rankIndex 0..7 = rank 8..1, mirrored for Black.
class _BestMoveArrowPainter extends CustomPainter {
  final String fromSquare;
  final String toSquare;
  final bool isBlack;

  _BestMoveArrowPainter({
    required this.fromSquare,
    required this.toSquare,
    required this.isBlack,
  });

  Offset _squareCenter(String square, Size size) {
    if (square.length < 2) return Offset.zero;
    final file = square.codeUnitAt(0) - 97; // 'a' -> 0
    final rank = int.tryParse(square.substring(1, 2)) ?? 1;

    final col = isBlack ? 7 - file : file;
    final row = isBlack ? rank - 1 : 8 - rank;
    final cell = size.width / 8;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = _squareCenter(fromSquare, size);
    final end = _squareCenter(toSquare, size);
    if (start == end) return;

    final cell = size.width / 8;
    final shaftWidth = cell * _kBestMoveArrowWidthFactor;
    final headLength = cell * _kBestMoveArrowHeadFactor;
    final inset = cell * _kBestMoveArrowInsetFactor;

    final direction = (end - start) / (end - start).distance;
    final shaftStart = start + direction * inset;
    // The arrowhead tip stays on the destination centre; the shaft stops
    // where the head begins so the head is a clean triangle.
    final shaftEnd = end - direction * (inset + headLength);
    if ((shaftEnd - shaftStart).distance <= 0) return;

    final paint = Paint()
      ..color = _kBestMoveArrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = shaftWidth
      ..strokeCap = StrokeCap.round;

    // Shaft.
    canvas.drawLine(shaftStart, shaftEnd, paint);

    // Arrowhead: a filled triangle perpendicular to the direction of travel.
    final perpendicular = Offset(-direction.dy, direction.dx);
    final halfHead = shaftWidth * 1.1;
    final tip = end - direction * inset;
    final baseLeft = shaftEnd + perpendicular * halfHead;
    final baseRight = shaftEnd - perpendicular * halfHead;

    final headPaint = Paint()
      ..color = _kBestMoveArrowColor
      ..style = PaintingStyle.fill;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();
    canvas.drawPath(head, headPaint);
  }

  @override
  bool shouldRepaint(_BestMoveArrowPainter oldDelegate) =>
      oldDelegate.fromSquare != fromSquare ||
      oldDelegate.toSquare != toSquare ||
      oldDelegate.isBlack != isBlack;
}

/// Paints one red capture arrow for a material-winning threat.
class _ThreatArrowPainter extends CustomPainter {
  final String fromSquare;
  final String toSquare;
  final bool isBlack;

  _ThreatArrowPainter({
    required this.fromSquare,
    required this.toSquare,
    required this.isBlack,
  });

  Offset _squareCenter(String square, Size size) {
    if (square.length < 2) return Offset.zero;
    final file = square.codeUnitAt(0) - 97;
    final rank = int.tryParse(square.substring(1, 2)) ?? 1;
    final col = isBlack ? 7 - file : file;
    final row = isBlack ? rank - 1 : 8 - rank;
    final cell = size.width / 8;
    return Offset((col + 0.5) * cell, (row + 0.5) * cell);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = _squareCenter(fromSquare, size);
    final end = _squareCenter(toSquare, size);
    if (start == end) return;

    final cell = size.width / 8;
    final shaftWidth = cell * 0.17;
    final headLength = cell * 0.34;
    final inset = cell * 0.24;
    final direction = (end - start) / (end - start).distance;
    final shaftStart = start + direction * inset;
    final shaftEnd = end - direction * (inset + headLength);
    if ((shaftEnd - shaftStart).distance <= 0) return;

    final color = const Color(0xE6E53935);
    final shaftPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = shaftWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shaftStart, shaftEnd, shaftPaint);

    final perpendicular = Offset(-direction.dy, direction.dx);
    final halfHead = shaftWidth * 1.15;
    final tip = end - direction * inset;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        shaftEnd.dx + perpendicular.dx * halfHead,
        shaftEnd.dy + perpendicular.dy * halfHead,
      )
      ..lineTo(
        shaftEnd.dx - perpendicular.dx * halfHead,
        shaftEnd.dy - perpendicular.dy * halfHead,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ThreatArrowPainter oldDelegate) =>
      oldDelegate.fromSquare != fromSquare ||
      oldDelegate.toSquare != toSquare ||
      oldDelegate.isBlack != isBlack;
}

/// Tint laid over the square holding the selected piece.
const Color _kSelectionTint = Color(0x8CFFD54F);

/// Tint laid over the square a hint points at.
const Color _kHintTint = Color(0x99FF9800);

/// Light red tint briefly flashed on the square of the king in check.
const Color _kCheckTint = Color(0x59E03A3A);

/// How long the check flash stays visible before fading away.
const Duration _kCheckFlashDuration = Duration(milliseconds: 750);

/// Yellowish fill laid over the origin and destination squares of the most
/// recently played move (the board's built-in last-move marker). A received
/// classification colour rewrites it on those squares.
const Color _kLastMoveColor = Color(0xFFFFD54F);

/// How strongly a marked square's base colour is blended toward its marker
/// colour. Shared by the yellowish last-move fill and the classification
/// colour that rewrites it, so the swap looks seamless.
const double _kMarkerTintAmount = 0.4;

/// `chess.Chess.BITS` flag values used to special-case moves (castling and
/// en-passant captures) when deriving the animated flight from a `Move`.
const int _kFlagKsCastle = 32; // BITS['KSIDE_CASTLE']
const int _kFlagQsCastle = 64; // BITS['QSIDE_CASTLE']
const int _kFlagEpCapture = 8; // BITS['EP_CAPTURE']

class ChessBoard extends StatefulWidget {
  final ChessboardController controller;
  final ChessboardSettings settings;
  final ValueChanged<ChessboardSettings>? onSettingsChanged;
  final void Function(String from, String to)? onMove;
  final bool enableFreeMove;
  final bool classificationEnabled;
  final Set<String> classificationFilter;
  final bool showSettingsButton;
  /// Draw material-winning captures threatened by the side that just moved.
  final bool threatDetectorEnabled;
  final Color? hintColorOverride;

  /// Whether to draw a gold border around the origin and destination squares
  /// of the last played move, so it is obvious which side just moved. Driven
  /// by the controller's current move-tree node, so it updates on navigation
  /// as well as on the move itself.
  final bool showLastMove;
  // Puzzle-specific feedback (green/red/blue tint + icon)
  final String? puzzleFeedbackSquare;
  final String? puzzleFeedbackOriginSquare;
  final Color? puzzleFeedbackColor;
  final IconData? puzzleFeedbackIcon;
  final Color? puzzleFeedbackIconColor;

  const ChessBoard({
    super.key,
    required this.controller,
    this.settings = const ChessboardSettings(),
    this.onSettingsChanged,
    this.onMove,
    this.enableFreeMove = false,
    this.classificationEnabled = false,
    this.classificationFilter = const {},
    this.showSettingsButton = true,
    this.threatDetectorEnabled = false,
    this.hintColorOverride,
    this.showLastMove = true,
    this.puzzleFeedbackSquare,
    this.puzzleFeedbackOriginSquare,
    this.puzzleFeedbackColor,
    this.puzzleFeedbackIcon,
    this.puzzleFeedbackIconColor,
  });

  @override
  State<ChessBoard> createState() => _ChessBoardState();

  /// Warms the piece and classification-asset caches so the first board render
  /// on a freshly installed app doesn't pay SVG parsing + PNG decode on the UI
  /// thread.
  ///
  /// Idempotent; safe to call once after `runApp` from bootstrap. Piece widget
  /// instances are shared by every square, so warming returns the same objects
  /// that the board will reuse for the process lifetime.
  static void warmUpAssets({PieceSet pieceSet = PieceSet.cburnett}) {
    for (final code in _kPieceCodes) {
      final assetPath = ChessboardSettings.pieceAssetPath(pieceSet, code);
      _ChessBoardState._pieceCache.putIfAbsent(assetPath, () {
        return Center(
          child: RepaintBoundary(
            child: SvgPicture.asset(
              assetPath,
              package: 'atlas_ui',
              width: 46,
              height: 46,
              fit: BoxFit.contain,
            ),
          ),
        );
      });
    }

    // Decode the classification badges into Flutter's image cache.
    for (final classification in MoveClassification.values) {
      _warmPng(MoveClassificationUI.getAssetName(classification));
    }
  }

  static void _warmPng(String assetPath) {
    final provider =
        AssetImage(assetPath, package: MoveClassificationUI.package);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    ImageStreamListener? listener;
    void detach() => stream.removeListener(listener!);
    listener = ImageStreamListener(
      (_, _) => detach(),
      onError: (_, _) => detach(),
    );
    stream.addListener(listener);
  }
}

/// Immutable description of the classification marker (spinner or icon) the
/// board should draw on top of the current node's destination square.
class _ClassificationDisplay {
  final String? assetName;
  final String? square;
  final String? originSquare;
  final Color? color;
  final bool pending;

  const _ClassificationDisplay({
    this.assetName,
    this.square,
    this.originSquare,
    this.color,
    this.pending = false,
  });
}

/// Everything one square needs to paint itself, resolved once per board build
/// so that the 64 squares only ever perform O(1) lookups instead of re-walking
/// the legal-move list or re-resolving controller state.
@immutable
class _SquareView {
  const _SquareView({
    required this.fileIndex,
    required this.rankIndex,
    required this.square,
    required this.isDark,
    required this.baseColor,
    required this.piece,
    required this.isLegalTarget,
    required this.isSelected,
    required this.isHint,
    required this.classification,
  });

  /// Visual column, `0..7`, left to right.
  final int fileIndex;

  /// Visual row, `0..7`, top to bottom.
  final int rankIndex;

  /// Algebraic name of the square, e.g. `e4`.
  final String square;

  /// Whether this is a dark tile, driven by the board's own checker pattern.
  final bool isDark;

  /// The tile colour before any interactive highlight is applied. Static for
  /// the lifetime of the position, so it never needs to animate.
  final Color baseColor;

  /// The piece standing on the square, if any.
  final chess.Piece? piece;

  /// Whether the selected piece may move to this square.
  final bool isLegalTarget;

  /// Whether this square holds the selected piece.
  final bool isSelected;

  /// Whether this square is the target of a hint.
  final bool isHint;

  /// Classification marker to draw on this square, if any.
  final _ClassificationDisplay? classification;

  /// Whether this square should render the classification marker.
  bool get hasClassificationHere =>
      classification != null && classification!.square == square;
}

/// A single piece flying from [from] to [to] during a move animation.
///
/// A normal move produces exactly one flight; castling produces a second one
/// for the rook so both pieces glide into place instead of one teleporting.
@immutable
class _PieceFlight {
  const _PieceFlight({
    required this.piece,
    required this.from,
    required this.to,
  });

  final chess.Piece piece;
  final String from;
  final String to;
}

class _ChessBoardState extends State<ChessBoard> with TickerProviderStateMixin {
  late ChessboardSettings _currentSettings;

  /// Motion tokens for the board. Re-resolved only when the platform animation
  /// scale changes, so widget rebuilds always see a stable instance.
  ChessboardMotion _motion = ChessboardMotion.standard;

  // Nullable so hot-reload can safely preserve an older State instance that
  // predates this controller. A full restart is not required after this UI
  // change, and moves still work if animation is temporarily unavailable.
  AnimationController? _moveAnimation;
  late final CurvedAnimation _moveCurve;

  /// Pieces currently flying across the board. Empty while the board is at
  /// rest; a normal move adds one flight, castling adds two (king + rook).
  List<_PieceFlight> _movingFlights = const [];

  /// The move-tree node whose position the board last rendered. Compared with
  /// the controller's current node on every notification to detect genuine
  /// one-ply-forward plays (which animate) vs navigation/resets (which snap).
  MoveNode? _displayedNode;

  /// Same hot-reload guard as [_moveAnimation], for the capture effect.
  AnimationController? _captureAnimation;
  late final CurvedAnimation _captureCurve;
  chess.Piece? _capturedPiece;
  String? _capturedSquare;

  /// Square of the king currently flashing red for check, if any.
  String? _highlightedCheckSquare;
  Timer? _checkFlashTimer;

  String? _threatCacheKey;
  List<ThreatArrow> _cachedThreats = const [];

  /// Per-square subtree cache. A square's widget subtree is rebuilt only when
  /// its render token changes, so overlay updates (selection, legal-move dots,
  /// classification markers) leave the 62+ unchanged squares untouched and the
  /// element tree reuses their existing subtrees.
  final List<_SquareCacheEntry?> _squareCache = List.filled(64, null);

  /// Token capturing the board-wide configuration that every square depends
  /// on, so a settings/motion change invalidates the whole cache.
  late String _boardConfigToken;

  /// Cached piece subtrees keyed by asset path. Piece widget instances are
  /// shared across squares and rebuilds: Flutter's element reconciliation
  /// skips rebuilding any square whose piece instance is identical to the
  /// previous build, so selection, legal-move and hint changes no longer
  /// rebuild the 30+ unchanged piece subtrees. The underlying SVG is also
  /// parsed only once per set.
  static final Map<String, Widget> _pieceCache = {};

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settings;
    final animation = AnimationController(
      vsync: this,
      duration: _motion.moveDuration,
    )..addStatusListener(_onMoveAnimationStatus);
    _moveAnimation = animation;
    _moveCurve = CurvedAnimation(
      parent: animation,
      curve: ChessboardMotion.moveCurve,
    );

    final captureAnimation = AnimationController(
      vsync: this,
      duration: _motion.captureDuration,
    )..addStatusListener(_onCaptureAnimationStatus);
    _captureAnimation = captureAnimation;
    _captureCurve = CurvedAnimation(
      parent: captureAnimation,
      curve: ChessboardMotion.captureCurve,
    );

    widget.controller.addListener(_syncCheckHighlight);
    _displayedNode = widget.controller.currentNode;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the platform's "reduce motion" accessibility setting. The tokens
    // are only swapped when the value actually changes, so ordinary rebuilds
    // always see a stable ChessboardMotion instance.
    final motion = ChessboardMotion.of(context);
    if (motion != _motion) {
      _motion = motion;
      _moveAnimation?.duration = motion.moveDuration;
      _captureAnimation?.duration = motion.captureDuration;
    }
  }

  @override
  void didUpdateWidget(covariant ChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _currentSettings = widget.settings;
    }

    // Follow the controller if the parent swapped it out.
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCheckHighlight);
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_syncCheckHighlight);
      widget.controller.addListener(_onControllerChanged);
      _checkFlashTimer?.cancel();
      _highlightedCheckSquare = null;
      _displayedNode = widget.controller.currentNode;
      _syncCheckHighlight();
    }
  }

  @override
  void dispose() {
    _checkFlashTimer?.cancel();
    widget.controller.removeListener(_syncCheckHighlight);
    widget.controller.removeListener(_onControllerChanged);
    _moveCurve.dispose();
    _moveAnimation?.dispose();
    _captureCurve.dispose();
    _captureAnimation?.dispose();
    super.dispose();
  }

  /// Drives the one-shot "king in check" tint.
  ///
  /// Called on every controller notification (any move or navigation), so the
  /// flash is surfaced regardless of how the position changes. A new or
  /// different check fades a light red tint in over the checked king's square;
  /// after a short hold the tint fades back out, giving a brief, legible cue
  /// without leaving a permanent highlight on the board.
  void _syncCheckHighlight() {
    final checkSquare = widget.controller.kingInCheckSquare;

    if (checkSquare == null) {
      // No longer in check: drop any active flash immediately.
      if (_checkFlashTimer?.isActive == true ||
          _highlightedCheckSquare != null) {
        _checkFlashTimer?.cancel();
        if (mounted) setState(() => _highlightedCheckSquare = null);
      }
      return;
    }

    // Same king still in check: leave the ongoing flash alone.
    if (_highlightedCheckSquare == checkSquare) return;

    _checkFlashTimer?.cancel();
    if (mounted) setState(() => _highlightedCheckSquare = checkSquare);
    _checkFlashTimer = Timer(_kCheckFlashDuration, () {
      if (mounted) setState(() => _highlightedCheckSquare = null);
    });
  }

  void _onMoveAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _movingFlights = const [];
      });
    }
  }

  void _onCaptureAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _capturedPiece = null;
        _capturedSquare = null;
      });
    }
  }

  /// Resolves the piece drawn on [square], preferring an explicit visual
  /// override when the caller has supplied one.
  chess.Piece? _pieceAt(String square) {
    final override = widget.controller.visualOverride;
    if (override != null && override.containsKey(square)) {
      return override[square];
    }
    return widget.controller.game.get(square);
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => ChessboardSettingsDialog(
        initialSettings: _currentSettings,
        onSettingsChanged: (settings) {
          setState(() => _currentSettings = settings);
          widget.onSettingsChanged?.call(settings);
        },
      ),
    );
  }

  /// True while a piece's flight animation is still running (from the moment
  /// a move is applied until [_onMoveAnimationStatus] clears it).
  bool get _isMoveAnimating => _movingFlights.isNotEmpty;

  /// Animates a move the instant it is applied to the controller.
  ///
  /// The smooth flight is a property of the board, not of whoever triggered
  /// the move: user taps/drags, engine replies (play vs Pippo), puzzle reveals
  /// and opponent replies all funnel through [ChessboardController.makeMove],
  /// which notifies this listener. Comparing the previously rendered node with
  /// the new current node tells the board that exactly one ply was played
  /// forward, so the moved piece — from either side — flies instead of
  /// teleporting. Anything else (undo, jumps, resets, classification updates)
  /// snaps, which is the expected behaviour for navigation.
  void _onControllerChanged() {
    if (!mounted) return;
    final controller = widget.controller;
    final next = controller.currentNode;
    final prev = _displayedNode;
    _displayedNode = next;

    final animation = _moveAnimation;
    if (animation == null) return;
    if (next.isRoot || next.move == null) return;
    if (!identical(next.parent, prev)) return; // navigation, jump or reset

    final move = next.move!;
    final flights = <_PieceFlight>[
      _PieceFlight(
        piece: chess.Piece(move.piece, move.color),
        from: move.fromAlgebraic,
        to: move.toAlgebraic,
      ),
    ];

    // Castling moves two pieces: glide the rook to its new square next to the
    // king instead of letting it teleport.
    if ((move.flags & _kFlagKsCastle) != 0) {
      final backRank = move.color == chess.Chess.WHITE ? '1' : '8';
      flights.add(
        _PieceFlight(
          piece: chess.Piece(chess.Chess.ROOK, move.color),
          from: 'h$backRank',
          to: 'f$backRank',
        ),
      );
    } else if ((move.flags & _kFlagQsCastle) != 0) {
      final backRank = move.color == chess.Chess.WHITE ? '1' : '8';
      flights.add(
        _PieceFlight(
          piece: chess.Piece(chess.Chess.ROOK, move.color),
          from: 'a$backRank',
          to: 'd$backRank',
        ),
      );
    }

    // The captured piece is the opponent's piece sitting on the destination
    // square. En-passant captures remove a pawn that is NOT on the destination
    // square, so they skip the capture overlay (the pawn simply vanishes,
    // matching the previous tap-move behaviour).
    final chess.Piece? captured =
        (move.captured != null && (move.flags & _kFlagEpCapture) == 0)
        ? chess.Piece(
            move.captured!,
            move.color == chess.Chess.WHITE
                ? chess.Chess.BLACK
                : chess.Chess.WHITE,
          )
        : null;

    setState(() {
      _movingFlights = flights;
      _capturedPiece = captured;
      _capturedSquare = captured == null ? null : move.toAlgebraic;
    });
    animation.forward(from: 0.0);
    if (captured != null) _captureAnimation?.forward(from: 0.0);
  }

  /// Computes the classification marker for the current node, if any, so the
  /// board can render it from its own controller listener without forcing the
  /// parent screen to rebuild on every classification update.
  _ClassificationDisplay? _computeClassificationDisplay() {
    if (!widget.classificationEnabled) return null;

    // Withhold both the pending pulse and the finished classification icon
    // while the move's flight animation is still running: a classification
    // that arrives almost instantly must not pop in mid-air or make the
    // piece appear to freeze. The status listener's setState rebuilds the
    // board the moment the piece lands, and only then is the marker shown.
    if (_isMoveAnimating) return null;

    final node = widget.controller.currentNode;

    if (node.isPendingClassification && !node.isRoot) {
      return _ClassificationDisplay(
        square: node.move?.toAlgebraic,
        pending: true,
      );
    }

    final classification = node.classification;
    if (classification == null || node.isRoot) return null;

    final label = MoveClassificationUI.getLabel(classification.classification);
    if (!widget.classificationFilter.contains(label)) return null;

    final sacrificed = classification.sacrificedSquare;
    final square = (sacrificed != null && sacrificed.isNotEmpty)
        ? sacrificed
        : node.move?.toAlgebraic;

    return _ClassificationDisplay(
      assetName: MoveClassificationUI.getAssetName(
        classification.classification,
      ),
      square: square,
      originSquare: node.move?.fromAlgebraic,
      color: MoveClassificationUI.getColor(classification.classification),
    );
  }

  List<ThreatArrow> _computeThreats() {
    if (!widget.threatDetectorEnabled) return const [];

    final node = widget.controller.currentNode;
    if (node.isRoot || node.parent == null || node.move == null) return const [];

    final move = node.move!;
    final moveUci =
        '${move.fromAlgebraic}${move.toAlgebraic}${move.promotion?.name ?? ''}';
    final key = '${node.parent!.fen}|$moveUci';
    if (_threatCacheKey == key) return _cachedThreats;

    _threatCacheKey = key;
    _cachedThreats = ThreatDetectorService.detect(
      fenBefore: node.parent!.fen,
      moveUci: moveUci,
    );
    return _cachedThreats;
  }

  @override
  Widget build(BuildContext context) {
    final isBlack = _currentSettings.orientation == BoardOrientation.black;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => _buildBoard(context, isBlack),
    );
  }

  Widget _buildBoard(BuildContext context, bool isBlack) {
    final controller = widget.controller;
    final game = controller.game;

    // Board-wide configuration that every square's render depends on. Whenever
    // any of these change the per-square cache below is invalidated wholesale.
    _boardConfigToken = [
      widget.showLastMove,
      _currentSettings.pieceSet.name,
      _currentSettings.showCoordinates,
      _currentSettings.showLegalMoves,
      _currentSettings.legalMoveColor.toARGB32().toRadixString(16),
      widget.hintColorOverride?.toARGB32().toRadixString(16) ?? '',
      widget.enableFreeMove,
      widget.puzzleFeedbackIcon?.codePoint,
      widget.puzzleFeedbackColor?.toARGB32().toRadixString(16),
      _motion.highlightDuration.inMilliseconds,
      _motion.moveDuration.inMilliseconds,
      _motion.captureDuration.inMilliseconds,
      _motion.selectionPulseDuration.inMilliseconds,
    ].join('|');

    // Precompute everything read per square once per build so the 64 squares
    // only do O(1) lookups (Set.contains) instead of re-walking lists and
    // re-resolving state for every square.
    final legalMoves = controller.legalMoves.toSet();
    final selectedSquare = controller.selectedSquare;
    final hintSquare = controller.hintSquare;
    final visualOverride = controller.visualOverride;
    final classification = _computeClassificationDisplay();
    final threats = _computeThreats();

    // Origin/destination of the last played move, for the gold border marker.
    final nodeMove = controller.currentNode.move;
    final lastMoveFrom = nodeMove?.fromAlgebraic;
    final lastMoveTo = nodeMove?.toAlgebraic;

    final showMovingPiece = _moveAnimation != null && _movingFlights.isNotEmpty;

    final showCapturedPiece =
        _captureAnimation != null &&
        _capturedPiece != null &&
        _capturedSquare != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    children: List.generate(8, (rankIndex) {
                      return Expanded(
                        child: Row(
                          children: List.generate(8, (fileIndex) {
                            return Expanded(
                              child: _buildSquare(
                                fileIndex,
                                rankIndex,
                                isBlack,
                                game: game,
                                legalMoves: legalMoves,
                                selectedSquare: selectedSquare,
                                hintSquare: hintSquare,
                                visualOverride: visualOverride,
                                classification: classification,
                                lastMoveFrom: lastMoveFrom,
                                lastMoveTo: lastMoveTo,
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                  // The captured piece is added first so it paints *under* the
                  // arriving piece: the defender is taken off the square while
                  // the attacker lands on top of it. A subtle capture ring is
                  // laid just above the victim so the capture stays legible.
                  if (showCapturedPiece)
                    RepaintBoundary(child: _buildCapturedPiece(isBlack)),
                  if (_captureAnimation != null && _capturedSquare != null)
                    RepaintBoundary(child: _buildCaptureFlash(isBlack)),
                  if (showMovingPiece)
                    RepaintBoundary(child: _buildMovingPiece(isBlack)),
                  for (final threat in threats)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _ThreatArrowPainter(
                          fromSquare: threat.fromSquare,
                          toSquare: threat.toSquare,
                          isBlack: isBlack,
                        ),
                      ),
                    ),
                  // Best-move arrow (yellow), painted above everything else.
                  // Purely visual: it never intercepts touches.
                  if (controller.bestMoveFrom != null &&
                      controller.bestMoveTo != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _BestMoveArrowPainter(
                          fromSquare: controller.bestMoveFrom!,
                          toSquare: controller.bestMoveTo!,
                          isBlack: isBlack,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showSettingsButton) _buildSettingsButton(),
      ],
    );
  }

  Widget _buildSettingsButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 0, bottom: 0, top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _showSettings,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.more_horiz,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSquare(
    int fileIndex,
    int rankIndex,
    bool isBlack, {
    required chess.Chess game,
    required Set<String> legalMoves,
    required String? selectedSquare,
    required String? hintSquare,
    required Map<String, chess.Piece?>? visualOverride,
    required _ClassificationDisplay? classification,
    required String? lastMoveFrom,
    required String? lastMoveTo,
  }) {
    // White: fileIndex 0..7 is 'a'..'h', rankIndex 0..7 is Rank 8..1
    // Black: fileIndex 0..7 is 'h'..'a', rankIndex 0..7 is Rank 1..8
    final file = isBlack ? 7 - fileIndex : fileIndex;
    final rank = isBlack ? rankIndex : 7 - rankIndex;
    final square = _squareName(file, rank);

    final isAnimatingSquare = _movingFlights.any(
      (f) => f.from == square || f.to == square,
    );
    final chess.Piece? piece;
    if (isAnimatingSquare) {
      piece = null;
    } else if (visualOverride != null && visualOverride.containsKey(square)) {
      piece = visualOverride[square];
    } else {
      piece = game.get(square);
    }

    final isDark = (fileIndex + rankIndex).isOdd;
    final tileColor = isDark
        ? _currentSettings.darkTileColor(fileIndex, rankIndex)
        : _currentSettings.lightTileColor(fileIndex, rankIndex);

    // The origin and destination of the last played move are marked with a
    // yellowish fill (replacing the former border-based marker). Once a
    // classification is received its colour rewrites that yellow on these
    // squares; while the move is still being classified
    // (`classification?.color` is null) the yellow stays, so the user always
    // sees where the piece came from and where it moved to.
    final isLastMoveSquare =
        widget.showLastMove && (square == lastMoveFrom || square == lastMoveTo);

    // Puzzle feedback tint overrides classification tint (green/red/blue)
    Color effectiveBase = tileColor;
    if (widget.puzzleFeedbackColor != null &&
        (widget.puzzleFeedbackSquare == square ||
            widget.puzzleFeedbackOriginSquare == square)) {
      effectiveBase = Color.lerp(tileColor, widget.puzzleFeedbackColor, 0.45)!;
    } else if (isLastMoveSquare) {
      effectiveBase = Color.lerp(
        tileColor,
        classification?.color ?? _kLastMoveColor,
        _kMarkerTintAmount,
      )!;
    } else if (classification != null &&
        classification.color != null &&
        (classification.square == square ||
            classification.originSquare == square)) {
      effectiveBase = Color.lerp(
        tileColor,
        classification.color,
        _kMarkerTintAmount,
      )!;
    }
    final baseColor = effectiveBase;

    final view = _SquareView(
      fileIndex: fileIndex,
      rankIndex: rankIndex,
      square: square,
      isDark: isDark,
      baseColor: baseColor,
      piece: piece,
      isLegalTarget: legalMoves.contains(square),
      isSelected: selectedSquare == square,
      isHint: hintSquare == square,
      classification: classification,
    );

    // Rebuild only when this square's visible state changed. All inputs that
    // affect the square's visuals/behaviour are folded into the token so the
    // cache can never serve a stale subtree.
    final int idx = rankIndex * 8 + fileIndex;
    final bool hasBadge = view.hasClassificationHere;
    final String badge = hasBadge
        ? (view.classification!.pending
            ? '-'
            : view.classification!.assetName ?? '@')
        : '';
    final String token = [
      _boardConfigToken,
      isBlack,
      square,
      isDark,
      baseColor.toARGB32().toRadixString(16),
      _tokenPieceCode(piece),
      view.isLegalTarget,
      view.isSelected,
      view.isHint,
      view.square == _highlightedCheckSquare,
      hasBadge,
      badge,
    ].join('|');

    final _SquareCacheEntry? cached = _squareCache[idx];
    if (cached != null && cached.token == token) {
      return cached.child;
    }

    final Widget child = DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != square &&
          (widget.enableFreeMove || view.isLegalTarget),
      onAcceptWithDetails: (details) {
        final from = details.data;
        final to = square;
        _requestMove(from, to);
      },
      builder: (context, _, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleSquareTap(square),
        child: ColoredBox(
          color: view.baseColor,
          child: _buildSquareContent(view, isBlack),
        ),
      ),
    );

    _squareCache[idx] = _SquareCacheEntry(token, child);
    return child;
  }

  Widget _buildSquareContent(_SquareView view, bool isBlack) {
    final hintColor = widget.hintColorOverride ?? _kHintTint;
    final children = <Widget>[
      // Both tints stay mounted on every square so they can animate *out* when
      // the selection moves elsewhere. While a tint is fully transparent the
      // underlying AnimatedOpacity paints nothing at all, so an idle square
      // pays no paint cost.
      SquareHighlight(
        active: view.isSelected,
        color: _kSelectionTint,
        duration: _motion.highlightDuration,
      ),
      SquareHighlight(
        active: view.isHint,
        color: hintColor,
        duration: _motion.highlightDuration,
      ),
      SquareHighlight(
        active: view.square == _highlightedCheckSquare,
        color: _kCheckTint,
        duration: _motion.highlightDuration,
      ),
    ];

    if (_currentSettings.showCoordinates) {
      children.add(_buildCoordinate(view, isBlack));
    }

    final piece = view.piece;
    if (_currentSettings.showLegalMoves && view.isLegalTarget) {
      children.add(piece == null ? _buildLegalMoveDot() : _buildCaptureRing());
    }

    if (piece != null) {
      children.add(
        SelectedPiecePulse(
          isSelected: view.isSelected,
          motion: _motion,
          child: _buildPiece(piece),
        ),
      );
    }

    if (view.hasClassificationHere) {
      final classification = view.classification!;
      if (classification.pending) {
        // Cycling icon carousel (book → best → brilliant → …) instead of a
        // static random-colour dot.
        children.add(const _ClassificationCycle());
      } else if (classification.assetName != null) {
        children.add(_buildClassificationIcon(classification.assetName!));
      }
    }

    // Puzzle feedback icon (green check / red cross) rendered on feedback square
    if (widget.puzzleFeedbackIcon != null &&
        widget.puzzleFeedbackSquare == view.square) {
      children.add(
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: widget.puzzleFeedbackIconColor ?? Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.puzzleFeedbackIcon,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(fit: StackFit.expand, children: children);
  }

  Widget _buildLegalMoveDot() {
    return Center(
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: _currentSettings.legalMoveColor.withValues(alpha: .7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildCaptureRing() {
    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: _currentSettings.legalMoveColor.withValues(alpha: .7),
            width: 4,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildClassificationIcon(String assetPath) {
    return _ClassificationBadge(assetPath: assetPath);
  }

  Widget _buildCoordinate(_SquareView view, bool isBlack) {
    final fileIndex = view.fileIndex;
    final rankIndex = view.rankIndex;

    String? label;
    // Rank labels on the left visual edge (fileIndex == 0)
    // File labels on the bottom visual edge (rankIndex == 7)

    if (fileIndex == 0) {
      // Rank label
      final rank = isBlack ? rankIndex + 1 : 8 - rankIndex;
      label = '$rank';
    } else if (rankIndex == 7) {
      // File label
      final file = isBlack ? 7 - fileIndex : fileIndex;
      label = String.fromCharCode(97 + file);
    }

    if (label == null) return const SizedBox.shrink();

    final coordColor = view.isDark
        ? view.baseColor.withValues(alpha: 0.78)
        : view.baseColor.withValues(alpha: 0.82);

    final alignment = fileIndex == 0
        ? Alignment.topLeft
        : Alignment.bottomRight;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          top: fileIndex == 0 ? 2 : 0,
          left: fileIndex == 0 ? 3 : 0,
          right: fileIndex != 0 ? 3 : 0,
          bottom: rankIndex == 7 ? 2 : 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: coordColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(chess.Piece piece) {
    final pieceSet = _currentSettings.pieceSet;
    final isWhite = piece.color == chess.Chess.WHITE;
    final pieceCode = _pieceCode(piece, isWhite);
    final assetPath = ChessboardSettings.pieceAssetPath(pieceSet, pieceCode);

    // Reuse the identical widget subtree for every square showing this piece:
    // unchanged squares then skip rebuilding their piece entirely.
    return _pieceCache.putIfAbsent(assetPath, () {
      return Center(
        child: RepaintBoundary(
          child: SvgPicture.asset(
            assetPath,
            package: 'atlas_ui',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
          ),
        ),
      );
    });
  }

  String _pieceCode(chess.Piece piece, bool isWhite) {
    final prefix = isWhite ? 'w' : 'b';
    final typeCode = switch (piece.type) {
      chess.Chess.PAWN => 'P',
      chess.Chess.KNIGHT => 'N',
      chess.Chess.BISHOP => 'B',
      chess.Chess.ROOK => 'R',
      chess.Chess.QUEEN => 'Q',
      chess.Chess.KING => 'K',
      _ => 'P',
    };
    return '$prefix$typeCode';
  }

  /// Compact piece token for the per-square cache ('e' when the square is
  /// empty).
  String _tokenPieceCode(chess.Piece? piece) {
    if (piece == null) return 'e';
    return _pieceCode(piece, piece.color == chess.Chess.WHITE);
  }

  String _squareName(int file, int rank) =>
      '${String.fromCharCode(97 + file)}${rank + 1}';

  void _handleSquareTap(String square) {
    if (widget.controller.selectedSquare == square) {
      widget.controller.selectSquare(null);
    } else if (widget.controller.legalMoves.contains(square)) {
      final from = widget.controller.selectedSquare!;
      final to = square;
      _requestMove(from, to);
    } else if (widget.controller.game.get(square) != null) {
      widget.controller.selectSquare(square);
    } else {
      widget.controller.selectSquare(null);
    }
  }

  void _requestMove(String from, String to) {
    final piece = _pieceAt(from);
    if (piece == null || !widget.controller.legalMoves.contains(to)) {
      // The attempt no longer matches the current selection (the piece is no
      // longer on the origin square, or the dots are stale). Drop the
      // selection so its legal-move dots can never survive the attempt.
      widget.controller.selectSquare(null);
      return;
    }

    final animation = _moveAnimation;
    if (animation == null) {
      // This can only happen for a State preserved through hot reload. Keep
      // interaction correct and let the next full build restore animation.
      widget.controller.makeMove(from, to);
      return;
    }

    // Whether the move is applied through the controller directly or via the
    // external `onMove` handler, the resulting controller notification drives
    // the flight animation in [_onControllerChanged] — user moves and
    // programmatic moves (engine replies, puzzle reveals) therefore animate
    // identically, from either side of the board.
    final moved = widget.onMove == null
        ? widget.controller.makeMove(from, to)
        : _notifyExternalMove(from, to);
    if (!moved) return;
  }

  bool _notifyExternalMove(String from, String to) {
    widget.onMove!(from, to);
    // The external handler owns the move from here, and it is free to REJECT
    // it without ever touching the controller — the puzzle screens do exactly
    // that when the move is not the solution. Nothing would then notify the
    // board, so the selected piece and its legal-move dots stayed stuck on
    // screen even though the attempt was over. Clearing the selection here
    // keeps the indicator honest either way: an applied move has already
    // cleared it, a rejected one loses it now.
    widget.controller.selectSquare(null);
    return true;
  }

  Widget _buildMovingPiece(bool isBlack) {
    // Guarded by `showMovingPiece` in _buildBoard; this is the hot-reload case
    // where the controller has not been created yet.
    if (_moveAnimation == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: [
          for (final flight in _movingFlights)
            MovingPieceOverlay(
              progress: _moveCurve,
              from: _displaySquare(flight.from, isBlack),
              to: _displaySquare(flight.to, isBlack),
              motion: _motion,
              child: _buildPiece(flight.piece),
            ),
        ],
      ),
    );
  }

  Widget _buildCapturedPiece(bool isBlack) {
    // Guarded by `showCapturedPiece` in _buildBoard.
    if (_captureAnimation == null) return const SizedBox.shrink();

    return CapturedPieceOverlay(
      progress: _captureCurve,
      square: _displaySquare(_capturedSquare!, isBlack),
      motion: _motion,
      child: _buildPiece(_capturedPiece!),
    );
  }

  Widget _buildCaptureFlash(bool isBlack) {
    // Guarded by `_capturedSquare != null` in _buildBoard.
    if (_captureAnimation == null) return const SizedBox.shrink();

    return CaptureFlash(
      progress: _captureCurve,
      square: _displaySquare(_capturedSquare!, isBlack),
    );
  }

  /// Maps an algebraic square name such as `e4` to its position on screen,
  /// accounting for the board's orientation.
  BoardSquare _displaySquare(String square, bool isBlack) {
    final file = square.codeUnitAt(0) - 97;
    final rank = square.codeUnitAt(1) - 49;
    return BoardSquare(isBlack ? 7 - file : file, isBlack ? rank : 7 - rank);
  }
}

/// Small classification badge — a 15x15 asset icon — pinned to the top-right
/// corner of a square. Shared by the finished classification icon and the
/// cycling "still classifying" indicator so both look identical in size and
/// placement.
class _ClassificationBadge extends StatelessWidget {
  const _ClassificationBadge({required this.assetPath});

  /// Asset path of the classification icon to render (looked up through
  /// [MoveClassificationUI.package]).
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Image.asset(
          assetPath,
          width: 15,
          height: 15,
          package: MoveClassificationUI.package,
        ),
      ),
    );
  }
}

/// "Classification in progress" indicator shown on the destination square
/// while the move is still being analysed (after the piece has landed).
///
/// Instead of an abstract random-colour dot, it cycles through a small, stable
/// set of classification icons — Best → Excellent → Mistake — one at a time.
/// The three icons are deliberately generic (a green "good" icon, a green
/// "excellent" icon and an orange "mistake" icon) so the rotation reads as a
/// loading animation, never as an actually-arrived classification result.
class _ClassificationCycle extends StatefulWidget {
  const _ClassificationCycle();

  @override
  State<_ClassificationCycle> createState() => _ClassificationCycleState();
}

class _ClassificationCycleState extends State<_ClassificationCycle> {
  /// How long each icon stays on screen before the next one takes its place.
  /// Kept very short so the icons flick by quickly and read as "still loading"
  /// instead of three meaningful classifications sitting on the square.
  static const Duration _kStep = Duration(milliseconds: 150);

  /// The icons cycled while classification is pending. A deliberately small,
  /// recognizable subset — an engine-neutral green "best", a green "excellent"
  /// and an orange "mistake" — rather than every possible badge.
  static final List<String> _assetNames = [
    MoveClassificationUI.getAssetName(MoveClassification.best),
    MoveClassificationUI.getAssetName(MoveClassification.excellent),
    MoveClassificationUI.getAssetName(MoveClassification.mistake),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_kStep, (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (!mounted) return;
    setState(() => _index = (_index + 1) % _assetNames.length);
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetNames[_index % _assetNames.length];
    return _ClassificationBadge(assetPath: assetPath);
  }
}
/// Caches a built square subtree together with the render token it was built
/// for, so `_buildSquare` can hand back the identical [Widget] instance when
/// nothing on that square changed (letting Flutter's element reconciliation
/// skip the entire subtree).
class _SquareCacheEntry {
  final String token;
  final Widget child;

  const _SquareCacheEntry(this.token, this.child);
}
