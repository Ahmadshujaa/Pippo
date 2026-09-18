class PuzzleModel {
  final String id;
  final String fen;
  final String bestMove;
  final bool completed;

  PuzzleModel({
    required this.id,
    required this.fen,
    required this.bestMove,
    required this.completed,
  });

  factory PuzzleModel.fromJson(Map<String, dynamic> json) {
    // MongoDB IDs can be strings or maps with $oid
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'] as String;
      return id?.toString() ?? '';
    }

    return PuzzleModel(
      id: parseId(json['id'] ?? json['_id']),
      fen: json['fen'] as String? ?? '',
      bestMove: json['best_move'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class PuzzleDocModel {
  final String id;
  final String playerColor;
  final List<PuzzleModel> puzzles;

  PuzzleDocModel({
    required this.id,
    required this.playerColor,
    required this.puzzles,
  });

  factory PuzzleDocModel.fromJson(Map<String, dynamic> json) {
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'] as String;
      return id?.toString() ?? '';
    }

    return PuzzleDocModel(
      id: parseId(json['_id']),
      playerColor: json['player_color'] as String? ?? 'white',
      puzzles: (json['puzzles'] as List? ?? [])
          .map((p) => PuzzleModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
