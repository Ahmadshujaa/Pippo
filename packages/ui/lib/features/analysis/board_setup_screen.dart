import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chess/chess.dart' as chess;

import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/AppBottomNav.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';
import 'package:atlas_core/atlas_core.dart';

/// Full-screen chess "Board Setup" editor.
///
/// Lets a user build any position piece by piece: tap or drag pieces from the
/// palette onto the board, tap an occupied square to remove it, or drag a
/// piece off the board to delete it. Choose who moves first, then either
/// Cancel (return to analysis untouched) or Finish.
///
/// Performance is kept smooth (no per-frame lag) by caching the expensive SVG
/// piece subtrees once per asset path — unchanged squares then skip rebuilding
/// their piece entirely — and by only mutating state on discrete drop/tap
/// events rather than during drag feedback frames.
class BoardSetupScreen extends StatefulWidget {
  const BoardSetupScreen({super.key});

  @override
  State<BoardSetupScreen> createState() => _BoardSetupScreenState();
}

class _BoardSetupScreenState extends State<BoardSetupScreen> {
  /// Session-level board/analysis owner, shared with the Analysis screen.
  GameAnalysisService get _service => GameAnalysisService.instance;

  /// Currently placed pieces keyed by square name (e.g. 'e4').
  final Map<String, chess.Piece> _pieces = {};

  chess.Color _sideToMove = chess.Color.WHITE;

  /// The palette piece currently armed for placement (e.g. 'wQ'), or null.
  /// When set, tapping an empty/occupied square places that piece there.
  String? _armedCode;

  ChessboardSettings _settings = const ChessboardSettings(showCoordinates: true);

  /// Validity error reported by the chess package for the current FEN.
  String? _error;

  /// Cached SVG piece subtrees keyed by the asset path (piece set + code).
  /// Sharing the exact same widget instance across squares lets element
  /// reconciliation skip rebuilding unchanged pieces during quick edits.
  static final Map<String, Widget> _svgPieceCache = {};

  /// Fixed palette chip edge length. Kept small enough to fit six chips plus
  /// the row label on the narrowest supported device width.
  static const double _chipSize = 40;

  @override
  void initState() {
    super.initState();
    _seedFromAnalysis();
  }

  /// Starts editing from the position currently on the analysis board so the
  /// user can tweak what they are already looking at.
  void _seedFromAnalysis() {
    final game = _service.controller.game;
    for (var rank = 8; rank >= 1; rank--) {
      for (var file = 0; file < 8; file++) {
        final square = _square(file, rank - 1);
        final piece = game.get(square);
        if (piece != null) _pieces[square] = piece;
      }
    }
    _sideToMove = game.turn;
  }

  // =========================================================================
  // Piece code helpers (e.g. 'wQ', 'bN').
  // =========================================================================

  static String _pieceCodeFrom(chess.Piece p) {
    final color = p.color == chess.Color.WHITE ? 'w' : 'b';
    return '$color${p.type.name.toUpperCase()}';
  }

  chess.Piece? _pieceFromCode(String code) {
    if (code.length != 2) return null;
    final chess.Color? color = switch (code[0]) {
      'w' => chess.Color.WHITE,
      'b' => chess.Color.BLACK,
      _ => null,
    };
    if (color == null) return null;
    final chess.PieceType? type = switch (code[1].toLowerCase()) {
      'p' => chess.PieceType.PAWN,
      'n' => chess.PieceType.KNIGHT,
      'b' => chess.PieceType.BISHOP,
      'r' => chess.PieceType.ROOK,
      'q' => chess.PieceType.QUEEN,
      'k' => chess.PieceType.KING,
      _ => null,
    };
    if (type == null) return null;
    return chess.Piece(type, color);
  }

  static bool _isSquareName(String s) =>
      s.length == 2 && s[0].codeUnitAt(0) >= 97 && s[0].codeUnitAt(0) <= 104 &&
      s[1].codeUnitAt(0) >= 49 && s[1].codeUnitAt(0) <= 56;

  static String _square(int file, int rank) =>
      '${String.fromCharCode(97 + file)}${rank + 1}';

  // =========================================================================
  // Position management.
  // =========================================================================

  void _setPiece(String square, chess.Piece piece) {
    setState(() => _pieces[square] = piece);
  }

  void _placeFromCode(String square, String code) {
    final piece = _pieceFromCode(code);
    if (piece != null) _setPiece(square, piece);
  }

  void _handleSquareTap(String square) {
    if (_armedCode != null) {
      _placeFromCode(square, _armedCode!);
    } else if (_pieces.containsKey(square)) {
      setState(() => _pieces.remove(square));
    }
  }

  /// Common drop handler for the board squares. Accepts either a palette piece
  /// code (place it) or a square name (move an existing board piece here).
  /// [square] names and [Piece] codes never collide (codes are always w/b + a
  /// piece letter, squares are always a-h + a rank digit), so parsing the
  /// payload is unambiguous even for b-file square names like "b4".
  void _handleDrop(String square, String data) {
    if (_pieceFromCode(data) != null) {
      _placeFromCode(square, data);
    } else if (_isSquareName(data) && data != square) {
      final piece = _pieces.remove(data);
      if (piece == null) return;
      setState(() => _pieces[square] = piece);
    }
  }

  void _clearBoard() {
    setState(() {
      _pieces.clear();
      _error = null;
    });
  }

  void _standardStart() {
    setState(() {
      _pieces.clear();
      _pieces.addAll(_startPositionPieces());
      _sideToMove = chess.Color.WHITE;
      _error = null;
    });
  }

  static Map<String, chess.Piece> _startPositionPieces() {
    final map = <String, chess.Piece>{};
    const backRank = ['r', 'n', 'b', 'q', 'k', 'b', 'n', 'r'];
    for (var file = 0; file < 8; file++) {
      final type = _typeForLetter(backRank[file])!;
      map['${String.fromCharCode(97 + file)}1'] =
          chess.Piece(type, chess.Color.WHITE);
      map['${String.fromCharCode(97 + file)}8'] =
          chess.Piece(type, chess.Color.BLACK);
      map['${String.fromCharCode(97 + file)}2'] =
          chess.Piece(chess.PieceType.PAWN, chess.Color.WHITE);
      map['${String.fromCharCode(97 + file)}7'] =
          chess.Piece(chess.PieceType.PAWN, chess.Color.BLACK);
    }
    return map;
  }

  static chess.PieceType? _typeForLetter(String letter) => switch (letter) {
    'r' => chess.PieceType.ROOK,
    'n' => chess.PieceType.KNIGHT,
    'b' => chess.PieceType.BISHOP,
    'q' => chess.PieceType.QUEEN,
    'k' => chess.PieceType.KING,
    'p' => chess.PieceType.PAWN,
    _ => null,
  };

  static String _fenLetter(chess.Piece piece) => piece.color == chess.Color.WHITE
      ? piece.type.name.toUpperCase()
      : piece.type.name;

  /// Builds a complete FEN (with "-"/"-"/"0"/"1" for castling, en passant,
  /// and move counters, which is correct for an arbitrary setup).
  String _buildFen() {
    final sb = StringBuffer();
    for (var rank = 8; rank >= 1; rank--) {
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final piece = _pieces[_square(file, rank - 1)];
        if (piece == null) {
          empty++;
          continue;
        }
        if (empty > 0) {
          sb.write(empty);
          empty = 0;
        }
        sb.write(_fenLetter(piece));
      }
      if (empty > 0) sb.write(empty);
      if (rank > 1) sb.write('/');
    }
    return '$sb ${_sideToMove == chess.Color.WHITE ? 'w' : 'b'} - - 0 1';
  }

  // =========================================================================
  // Apply (Finish) / Cancel
  // =========================================================================

  void _handleFinish() {
    final fen = _buildFen();

    // Use the official chess package's legality checker — we deliberately do
    // not re-implement FEN/position legality here.
    final validation = chess.Chess.validate_fen(fen);
    if (validation['valid'] != true) {
      setState(() => _error = validation['error']?.toString() ?? 'Illegal position');
      return;
    }

    final service = GameAnalysisService.instance;
    // Halt any in-flight engine search so it doesn't keep chewing CPU while we
    // swap in the new position.
    StockfishEngineService.instance.stop();
    // Cancel a running full-game analysis run (and clear its per-node
    // classification state).
    service.cancelRunningAnalysis();
    // Drop the loaded game (PGN/headers/imported moves) — it is being replaced
    // by the setup position.
    service.clearLoadedGameData();
    // Classification/engine must not start until the user plays a move in the
    // setup. Set BEFORE loading so the Analysis screen's controller listener
    // (which notifies synchronously inside loadFen) sees the flag and treats
    // the new root as inert.
    service.suppressEngineUntilMove = true;
    // Loading the FEN rebuilds the move-tree root and deletes every move.
    service.controller.loadFen(fen);
    // Drop any cached per-position analysis/classification.
    MoveClassificationService.instance.clearCache();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: AppLocalizations.of(context).cancelButton,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).boardSetupTitle,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_rounded),
            tooltip: AppLocalizations.of(context).flipBoardTooltip,
            onPressed: () => setState(() {
              _settings = _settings.copyWith(
                orientation: _settings.orientation == BoardOrientation.white
                    ? BoardOrientation.black
                    : BoardOrientation.white,
              );
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBoard(),
              const SizedBox(height: 16),
              _buildActionRow(theme),
              const SizedBox(height: 20),
              _buildSideToMove(theme),
              const SizedBox(height: 20),
              _buildPalette(theme),
              const SizedBox(height: 18),
              _buildFenReadout(theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomActions(theme),
          const AppBottomNav(active: AppTab.analysis),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: RepaintBoundary(
          child: Column(
            children: List.generate(8, (rankIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(8, (fileIndex) {
                    return Expanded(child: _buildSquare(fileIndex, rankIndex));
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSquare(int fileIndex, int rankIndex) {
    final isBlack = _settings.orientation == BoardOrientation.black;
    final file = isBlack ? 7 - fileIndex : fileIndex;
    final rank = isBlack ? rankIndex : 7 - rankIndex;
    final square = _square(file, rank);

    final piece = _pieces[square];
    final dark = (fileIndex + rankIndex).isOdd;
    Color tile = dark
        ? _settings.darkTileColor(fileIndex, rankIndex)
        : _settings.lightTileColor(fileIndex, rankIndex);

    final showTargetDot = _armedCode != null && piece == null;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _handleDrop(square, details.data),
      builder: (context, candidates, _) {
        if (candidates.isNotEmpty) {
          tile = Color.lerp(tile, AppColors.primary, 0.35)!;
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleSquareTap(square),
          child: ColoredBox(
            color: tile,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoordinate(fileIndex, rankIndex, dark, tile),
                if (showTargetDot)
                  Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (piece != null)
                  _buildBoardPiece(square, _pieceCodeFrom(piece)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinate(int fileIndex, int rankIndex, bool dark, Color tile) {
    final isBlack = _settings.orientation == BoardOrientation.black;
    String? label;
    if (fileIndex == 0) {
      final rank = isBlack ? rankIndex + 1 : 8 - rankIndex;
      label = '$rank';
    } else if (rankIndex == 7) {
      final file = isBlack ? 7 - fileIndex : fileIndex;
      label = String.fromCharCode(97 + file);
    }
    if (label == null) return const SizedBox.shrink();

    final color = tile.computeLuminance() > 0.5
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.6);

    return Align(
      alignment: fileIndex == 0 ? Alignment.topLeft : Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildBoardPiece(String square, String code) {
    return Draggable<String>(
      data: square,
      maxSimultaneousDrags: 1,
      feedback: _pieceFeedback(code),
      childWhenDragging: const SizedBox.shrink(),
      onDragEnd: (details) {
        // Dropping a piece off the board (outside any square DragTarget)
        // removes it. Dropping it on another square was accepted and handled
        // by that square's [onAcceptWithDetails].
        if (!details.wasAccepted && mounted) {
          setState(() => _pieces.remove(square));
        }
      },
      child: _cachedPiece(code),
    );
  }

  Widget _pieceFeedback(String code) {
    return IgnorePointer(
      child: SizedBox(
        width: 62,
        height: 62,
        child: _cachedPiece(code),
      ),
    );
  }

  Widget _buildActionRow(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _actionPill(Icons.delete_outline_rounded, l10n.clearBoardButton, theme,
              () => _clearBoard()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionPill(Icons.replay_rounded, l10n.startPositionButton, theme,
              () => _standardStart()),
        ),
      ],
    );
  }

  Widget _actionPill(
    IconData icon,
    String label,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtleOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideToMove(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whoMovesHeader,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.1,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<chess.Color>(
          segments: [
            ButtonSegment(
              value: chess.Color.WHITE,
              icon: const Icon(Icons.circle, color: Colors.white, size: 16),
              label: Text(l10n.sideWhite),
            ),
            ButtonSegment(
              value: chess.Color.BLACK,
              icon: const Icon(Icons.circle, color: Colors.black, size: 16),
              label: Text(l10n.sideBlack),
            ),
          ],
          selected: {_sideToMove},
          showSelectedIcon: true,
          onSelectionChanged: (value) {
            setState(() {
              _sideToMove = value.first;
              _error = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPalette(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.piecesHeader,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.1,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        _buildPaletteRow(chess.Color.WHITE, l10n.sideWhite),
        const SizedBox(height: 10),
        _buildPaletteRow(chess.Color.BLACK, l10n.sideBlack),
        const SizedBox(height: 14),
        Text(
          l10n.setupInstructions,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteRow(chess.Color color, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
        Expanded(
          child: Row(
            // Each chip lives in an equally-sized cell so the palette always
            // fits every screen width — the chips never drive the row's width.
            children: [..._pieceCodesFor(color).map(_buildPaletteChipCell)],
          ),
        ),
      ],
    );
  }

  List<String> _pieceCodesFor(chess.Color color) {
    const letters = ['k', 'q', 'r', 'b', 'n', 'p'];
    final prefix = color == chess.Color.WHITE ? 'w' : 'b';
    return letters.map((l) => '$prefix${l.toUpperCase()}').toList();
  }

  /// Equal-width cell wrapper so six chips always divide the row cleanly.
  Widget _buildPaletteChipCell(String code) {
    return Expanded(
      child: Center(child: _buildPaletteChip(code)),
    );
  }

  Widget _buildPaletteChip(String code) {
    final isArmed = _armedCode == code;
    return Draggable<String>(
      data: code,
      maxSimultaneousDrags: 1,
      feedback: _pieceFeedback(code),
      childWhenDragging: Opacity(opacity: 0.35, child: _chipContent(code, isArmed)),
      child: GestureDetector(
        onTap: () => setState(() {
          _armedCode = isArmed ? null : code;
          _error = null;
        }),
        child: _chipContent(code, isArmed),
      ),
    );
  }

  Widget _chipContent(String code, bool isArmed) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: _chipSize,
      height: _chipSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isArmed
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.surfaceSubtleOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isArmed ? AppColors.primary : theme.dividerColor,
          width: isArmed ? 2 : 1,
        ),
        boxShadow: isArmed
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      // The piece scales to the chip: no fixed inner size that could overflow.
      child: _cachedPiece(code),
    );
  }

  Widget _buildFenReadout(ThemeData theme) {
    final fen = _buildFen();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtleOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error != null ? AppColors.error : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).fenHeader,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fen,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 15, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // Bottom actions (Finish / Cancel) + cached piece rendering.
  // =========================================================================

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancelButton,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleFinish,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                AppLocalizations.of(context).setupFinish,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cachedPiece(String code) {
    assert(code.length == 2);
    final path = ChessboardSettings.pieceAssetPath(_settings.pieceSet, code);
    final key = '${_settings.pieceSet}/$path';
    return _svgPieceCache.putIfAbsent(key, () {
      return Center(
        child: RepaintBoundary(
          child: SvgPicture.asset(
            path,
            package: 'atlas_ui',
            fit: BoxFit.contain,
          ),
        ),
      );
    });
  }
}