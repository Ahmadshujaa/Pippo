import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:atlas_core/core/analysis/MoveClassificationService.dart';

/// Represents a single move (or initial state) in a tree of chess moves.
class MoveNode {
  final chess.Move? move; // null for the root (starting position)
  final String fen;
  final String san;
  ClassificationResult? classification;
  bool isPendingClassification = false;

  MoveNode? parent;
  final List<MoveNode> children = [];

  // To keep track of which child was last visited for "smart redo"
  int selectedChildIndex = 0;

  MoveNode({
    this.move,
    required this.fen,
    this.san = '',
    this.parent,
    this.classification,
  });

  bool get isRoot => parent == null;
  bool get hasClassification => classification != null;
}

class ChessboardController extends ChangeNotifier {
  late chess.Chess _game;
  String? _selectedSquare;
  List<String> _legalMoves = [];
  Map<String, chess.Piece?>? _visualOverride;
  String? _hintSquare;
  Map<String, String>? _hintMove;
  String? _bestMoveFrom;
  String? _bestMoveTo;

  bool _coalesceScheduled = false;

  int _treeVersion = 0;

  /// Bumped whenever the move tree's STRUCTURE changes (a node is added, or
  /// the game is loaded/reset). Consumers use this to invalidate caches that
  /// depend on the tree shape (e.g. the moves list) without rebuilding on
  /// every notification — navigation, classification and pending-flag updates
  /// do NOT change the tree shape.
  int get treeVersion => _treeVersion;

  // Tree management
  late MoveNode _root;
  late MoveNode _currentNode;

  ChessboardController({
    String fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  }) {
    _game = chess.Chess.fromFEN(fen);
    _root = MoveNode(fen: fen);
    _currentNode = _root;
  }

  /// Schedules a single [notifyListeners] for the end of the current frame.
  ///
  /// Overlay-only mutations (selection, hints, classification results, pending
  /// flags, arrows) call this instead of [notifyListeners] so that a burst of
  /// updates — e.g. a reflow that classifies many moves in a row — collapses
  /// into ONE board rebuild per frame instead of N rebuilds. Position changes
  /// (moves, loads, navigation) keep calling [notifyListeners] directly so the
  /// board animates immediately.
  void notifyCoalesced() {
    if (_coalesceScheduled) return;
    _coalesceScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _coalesceScheduled = false;
      notifyListeners();
    });
  }

  chess.Chess get game => _game;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalMoves => _legalMoves;
  Map<String, chess.Piece?>? get visualOverride => _visualOverride;
  String? get hintSquare => _hintSquare;
  Map<String, String>? get hintMove => _hintMove;

  /// From-square (e.g. `e2`) of the best-move arrow, or `null` when hidden.
  String? get bestMoveFrom => _bestMoveFrom;

  /// To-square (e.g. `e4`) of the best-move arrow, or `null` when hidden.
  String? get bestMoveTo => _bestMoveTo;

  /// Algebraic square (e.g. `e8`) of the king that is currently in check, or
  /// `null` when nobody is in check.
  ///
  /// The king in check is always the king of the side to move: after a move the
  /// turn switches to the opponent, so a king in check is `game.turn`'s king.
  String? get kingInCheckSquare {
    if (!_game.in_check) return null;
    return _findPieceSquare(chess.Chess.KING, _game.turn);
  }

  /// Scans the board for the first piece of [type] belonging to [color] and
  /// returns its algebraic square, or `null` if it is not present.
  String? _findPieceSquare(chess.PieceType type, chess.Color color) {
    for (var file = 0; file < 8; file++) {
      for (var rank = 0; rank < 8; rank++) {
        final square = '${String.fromCharCode(97 + file)}${rank + 1}';
        final piece = _game.get(square);
        if (piece != null && piece.type == type && piece.color == color) {
          return square;
        }
      }
    }
    return null;
  }

  MoveNode get root => _root;
  MoveNode get currentNode => _currentNode;

  bool get isSecondOrderVariation {
    // If we are in a variation, check if our parent was also in a variation
    MoveNode? temp = _currentNode;
    int diversions = 0;
    while (temp != null && temp.parent != null) {
      if (temp.parent!.children.indexOf(temp) > 0) {
        diversions++;
      }
      temp = temp.parent;
    }
    return diversions > 1;
  }

  /// Returns the current move sequence (path from root to currentNode)
  List<MoveNode> get currentPath {
    final List<MoveNode> path = [];
    MoveNode? temp = _currentNode;
    while (temp != null) {
      path.add(temp);
      temp = temp.parent;
    }
    return path.reversed.toList();
  }

  /// Returns the "index" in the current branch (0 for root)
  int get currentIndex {
    int index = 0;
    MoveNode? temp = _currentNode;
    while (temp != null && temp.parent != null) {
      index++;
      temp = temp.parent;
    }
    return index;
  }

  bool get canUndo => _currentNode.parent != null;
  bool get canRedo => _currentNode.children.isNotEmpty;

  bool get isInVariation {
    MoveNode? temp = _currentNode;
    while (temp != null && temp.parent != null) {
      if (temp.parent!.children.indexOf(temp) > 0) return true;
      temp = temp.parent;
    }
    return false;
  }

  void undo() {
    if (!canUndo) return;
    _currentNode = _currentNode.parent!;
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();

    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    // Navigate to the last selected child (or first by default)
    final index = _currentNode.selectedChildIndex.clamp(
      0,
      _currentNode.children.length - 1,
    );
    _currentNode = _currentNode.children[index];
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();

    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  void goToStart() {
    _currentNode = _root;
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  void goToEnd() {
    // Navigate to the last node of the current line without notifying per
    // step: jumping to the end of a long game would otherwise trigger one
    // full board rebuild per move in a single frame (the "skipped N frames"
    // spikes users see when tapping "go to end").
    while (canRedo) {
      final index = _currentNode.selectedChildIndex.clamp(
        0,
        _currentNode.children.length - 1,
      );
      _currentNode = _currentNode.children[index];
    }
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  void jumpToIndex(int index) {
    // Navigating back to an index in the CURRENT path
    final path = currentPath;
    if (index < 0 || index >= path.length) return;

    _currentNode = path[index];
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  /// Navigate directly to a move in the analysis tree.  This is intentionally
  /// tree-aware (rather than index-based) so a UI can select nested variations.
  void jumpToNode(MoveNode node) {
    _currentNode = node;
    _game.load(_currentNode.fen);
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  void jumpToDiversion() {
    // Jump back to the last node that was on the "main line" (first branch)
    MoveNode? temp = _currentNode;
    MoveNode? lastMainLineNode;

    while (temp != null) {
      bool onMainLine = true;
      MoveNode? check = temp;
      while (check != null && check.parent != null) {
        if (check.parent!.children.indexOf(check) > 0) {
          onMainLine = false;
          break;
        }
        check = check.parent;
      }
      if (onMainLine) {
        lastMainLineNode = temp;
        break;
      }
      temp = temp.parent;
    }

    if (lastMainLineNode != null) {
      _currentNode = lastMainLineNode;
      _game.load(_currentNode.fen);
      _clearBestMoveArrow();
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();
    }
  }

  void setHintSquare(String? square) {
    _hintSquare = square;
    notifyCoalesced();
  }

  void setHintMove(String? from, String? to) {
    if (from == null || to == null) {
      _hintMove = null;
    } else {
      _hintMove = {'from': from, 'to': to};
    }
    notifyCoalesced();
  }

  void clearHints() {
    _hintSquare = null;
    _hintMove = null;
    notifyCoalesced();
  }

  /// Shows (or hides) the best-move arrow on the board.
  ///
  /// Pass `null` for both squares to clear it. The arrow always belongs to the
  /// currently displayed position, so every navigation / move method below
  /// clears it automatically — the arrow can never linger on a position it
  /// was not computed for.
  void setBestMoveArrow(String? from, String? to) {
    if (from == null || to == null) {
      if (_bestMoveFrom == null && _bestMoveTo == null) return;
      _bestMoveFrom = null;
      _bestMoveTo = null;
      notifyCoalesced();
      return;
    }
    if (_bestMoveFrom == from && _bestMoveTo == to) return;
    _bestMoveFrom = from;
    _bestMoveTo = to;
    notifyCoalesced();
  }

  /// Silent clear used by navigation/move methods (they notify themselves).
  void _clearBestMoveArrow() {
    _bestMoveFrom = null;
    _bestMoveTo = null;
  }

  void setVisualOverride(Map<String, chess.Piece?>? override) {
    _visualOverride = override;
    notifyCoalesced();
  }

  void selectSquare(String? square) {
    if (square == null) {
      _selectedSquare = null;
      _legalMoves = [];
    } else {
      final piece = _game.get(square);
      if (piece == null || piece.color != _game.turn) {
        _selectedSquare = null;
        _legalMoves = [];
        notifyCoalesced();
        return;
      }
      _selectedSquare = square;
      _legalMoves = _game
          .generate_moves({'square': square})
          .map((move) => move.toAlgebraic)
          .cast<String>()
          .toList();
    }
    notifyCoalesced();
  }

  bool makeMove(String from, String to, {String promotion = 'q'}) {
    // 1. Determine SAN and Move object before making the move
    final legalMoves = _game.generate_moves();
    chess.Move? moveObj;
    for (final m in legalMoves) {
      if (m.fromAlgebraic == from &&
          m.toAlgebraic == to &&
          (m.promotion == null || m.promotion!.name == promotion)) {
        moveObj = m;
        break;
      }
    }

    if (moveObj == null) return false;
    final san = _game.move_to_san(moveObj);

    // 2. Actually make the move in the internal chess game
    final moved = _game.move({'from': from, 'to': to, 'promotion': promotion});
    if (moved) {
      final newFen = _game.fen;

      // 3. Check if this move already exists in the current node's children
      MoveNode? nextNode;
      for (int i = 0; i < _currentNode.children.length; i++) {
        if (_currentNode.children[i].fen == newFen) {
          nextNode = _currentNode.children[i];
          _currentNode.selectedChildIndex = i;
          break;
        }
      }

      // 4. If it's a new move/variation, create a new node
      if (nextNode == null) {
        nextNode = MoveNode(
          move: moveObj,
          fen: newFen,
          san: san,
          parent: _currentNode,
        );
        _currentNode.children.add(nextNode);
        _currentNode.selectedChildIndex = _currentNode.children.length - 1;
        _treeVersion++;
      }

      _currentNode = nextNode;
      _clearBestMoveArrow();
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Apply a move given in Standard Algebraic Notation (e.g. "Nf3", "e4").
  /// Returns true if the move was legal and applied.
  bool makeMoveFromSan(String san) {
    final legalMoves = _game.generate_moves();
    chess.Move? moveObj;
    for (final m in legalMoves) {
      if (_game.move_to_san(m) == san) {
        moveObj = m;
        break;
      }
    }
    if (moveObj == null) return false;
    return makeMove(moveObj.fromAlgebraic, moveObj.toAlgebraic);
  }

  void reset() {
    final startFen = chess.Chess.DEFAULT_POSITION;
    _game.reset();
    _root = MoveNode(fen: startFen);
    _currentNode = _root;
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    _treeVersion++;
    notifyListeners();
  }

  void loadFen(String fen) {
    _game.load(fen);
    _root = MoveNode(fen: fen);
    _currentNode = _root;
    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    _treeVersion++;
    notifyListeners();
  }

  void loadGame(List<String> fens) {
    if (fens.isEmpty) return;

    // Reset to start
    _game.load(fens.first);
    _root = MoveNode(fen: fens.first);
    _currentNode = _root;

    // Sequential build of the main line
    final temp = chess.Chess.fromFEN(fens.first);
    for (int i = 1; i < fens.length; i++) {
      final targetFen = fens[i];
      final moves = temp.generate_moves();
      chess.Move? found;
      for (final m in moves) {
        // Keep `temp` on the position before the candidate while looking for
        // a match. This lets us generate SAN and apply the move exactly once.
        temp.make_move(m);
        if (temp.fen == targetFen) {
          found = m;
          temp.undo_move();
          break;
        }
        temp.undo_move();
      }

      if (found != null) {
        final san = temp.move_to_san(found);
        temp.make_move(found);
        final nextNode = MoveNode(
          move: found,
          fen: targetFen,
          san: san,
          parent: _currentNode,
        );
        _currentNode.children.add(nextNode);
        _currentNode = nextNode;
      } else {
        // Fallback if FEN sequence is broken
        break;
      }
    }

    _clearBestMoveArrow();
    _selectedSquare = null;
    _legalMoves = [];
    _treeVersion++;
    notifyListeners();
  }

  void updateClassification(ClassificationResult result) {
    updateClassificationForNode(_currentNode, result);
  }

  /// Classification runs asynchronously.  Always update the node that
  /// started the request, not whichever move the user has navigated to since.
  void updateClassificationForNode(MoveNode node, ClassificationResult result) {
    node.classification = result;
    node.isPendingClassification = false;
    notifyCoalesced();
  }

  void setPendingClassification(bool isPending) {
    setPendingClassificationForNode(_currentNode, isPending);
  }

  void setPendingClassificationForNode(MoveNode node, bool isPending) {
    if (node.isPendingClassification == isPending) return;
    node.isPendingClassification = isPending;
    notifyCoalesced();
  }

  bool _isInSubtree(MoveNode ancestor, MoveNode descendant) {
    MoveNode? cur = descendant;
    while (cur != null) {
      if (identical(cur, ancestor)) return true;
      cur = cur.parent;
    }
    return false;
  }

  /// Deletes [node] and its entire subtree from the tree.
  /// If the current node lies inside the deleted subtree, it is moved to
  /// [node.parent]. Returns true if deletion succeeded.
  bool deleteSubtree(MoveNode node) {
    if (node.isRoot) return false;
    final parent = node.parent!;
    final idx = parent.children.indexOf(node);
    if (idx == -1) return false;
    if (_isInSubtree(node, _currentNode)) {
      _currentNode = parent;
      _game.load(_currentNode.fen);
      _clearBestMoveArrow();
      _selectedSquare = null;
      _legalMoves = [];
    }
    parent.children.removeAt(idx);
    if (parent.selectedChildIndex >= parent.children.length) {
      parent.selectedChildIndex = parent.children.isEmpty
          ? 0
          : parent.children.length - 1;
    }
    _treeVersion++;
    notifyListeners();
    return true;
  }
}
