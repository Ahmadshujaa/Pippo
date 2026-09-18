class CourseModel {
  final String openingName;
  final String slug;
  final String description;
  final String playfulDescription;
  final String side;
  final String mainCategory;
  final String subCategory;
  final String ecoCode;
  final int chapterCount;
  final int variationCount;
  final List<CourseChapterModel> chapters;
  final bool isLocked;

  CourseModel({
    required this.openingName,
    required this.slug,
    required this.description,
    required this.playfulDescription,
    required this.side,
    required this.mainCategory,
    required this.subCategory,
    required this.ecoCode,
    required this.chapterCount,
    required this.variationCount,
    required this.chapters,
    this.isLocked = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      openingName: json['opening_name'] ?? json['openingName'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      playfulDescription: json['playful_description'] ?? json['playfulDescription'] ?? '',
      side: json['side'] ?? 'white',
      mainCategory: json['main_category'] ?? json['mainCategory'] ?? '',
      subCategory: json['sub_category'] ?? json['subCategory'] ?? '',
      ecoCode: json['eco_code'] ?? json['ecoCode'] ?? '',
      chapterCount: (json['chapter_count'] as num? ?? json['chapterCount'] as num?)?.toInt() ?? 0,
      variationCount: (json['variation_count'] as num? ?? json['variationCount'] as num?)?.toInt() ?? 0,
      chapters: (json['chapters'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CourseChapterModel.fromJson(e))
              .toList() ??
          [],
      isLocked: json['isLocked'] ?? false,
    );
  }
}

class CourseChapterModel {
  final String name;
  // Editable in place so a saved description is reflected immediately in the
  // running app without re-fetching the course from MongoDB.
  String description;
  final int variationCount;
  final List<CourseVariationModel> variations;

  CourseChapterModel({
    required this.name,
    required this.description,
    required this.variationCount,
    required this.variations,
  });

  factory CourseChapterModel.fromJson(Map<String, dynamic> json) {
    final variations = (json['variations'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => CourseVariationModel.fromJson(e))
            .toList() ??
        [];
        
    int count = (json['variation_count'] as num? ?? json['variationCount'] as num?)?.toInt() ?? 0;
    if (count == 0 && variations.isNotEmpty) {
      count = variations.length;
    }

    return CourseChapterModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      variationCount: count,
      variations: variations,
    );
  }
}

class CourseVariationModel {
  final String name;
  final String pgn;
  // Editable in place so a saved explanation is reflected immediately in the
  // running app without re-fetching the course from MongoDB.
  String theory;
  final String description;
  final List<CourseMoveModel> plies;
  final List<CourseBranchModel> branches;

  CourseVariationModel({
    required this.name,
    required this.pgn,
    required this.theory,
    required this.description,
    required this.plies,
    required this.branches,
  });

  factory CourseVariationModel.fromJson(Map<String, dynamic> json) {
    // Search for move list in various possible keys
    final pliesData = json['plies'] ?? 
                      json['moves'] ?? 
                      json['move_list'] ?? 
                      json['move_history'] ?? 
                      json['moveHistory'] ?? 
                      json['line'] ?? 
                      json['variation'];
    
    // Search for branches in various possible keys
    final branchesData = json['branches'] ?? 
                         json['alternative_lines'] ?? 
                         json['sub_variations'] ??
                         json['branch_lines'];

    return CourseVariationModel(
      name: json['name'] ?? '',
      pgn: json['pgn'] ?? '',
      theory: json['theory'] ?? '',
      description: json['description'] ?? '',
      plies: (pliesData as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CourseMoveModel.fromJson(e))
              .toList() ??
          [],
      branches: (branchesData as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CourseBranchModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CourseMoveModel {
  String fen;
  final String move;
  // Editable in place so a saved explanation is reflected immediately in the
  // running app without re-fetching the course from MongoDB.
  String explanation;
  // Editable in place so a saved hint is reflected immediately in the
  // running app without re-fetching the course from MongoDB.
  String hint;
  final int ply;

  CourseMoveModel({
    this.fen = '',
    required this.move,
    required this.explanation,
    this.hint = '',
    this.ply = 0,
  });

  factory CourseMoveModel.fromJson(Map<String, dynamic> json) {
    return CourseMoveModel(
      fen: json['fen'] ?? '',
      move: json['move'] ?? '',
      explanation: json['explanation'] ?? '',
      hint: json['hint'] ?? '',
      ply: (json['ply'] as num?)?.toInt() ?? 0,
    );
  }
}

class CourseBranchModel {
  final String name;
  final String pgn;
  final int startMoveIndex;
  // Editable in place so a saved explanation is reflected immediately in the
  // running app without re-fetching the course from MongoDB.
  String explanation;
  final List<CourseMoveModel> plies;

  CourseBranchModel({
    required this.name,
    required this.pgn,
    required this.startMoveIndex,
    required this.explanation,
    required this.plies,
  });

  factory CourseBranchModel.fromJson(Map<String, dynamic> json) {
    final pliesData = json['plies'] ?? 
                      json['moves'] ?? 
                      json['move_list'] ?? 
                      json['move_history'] ?? 
                      json['moveHistory'] ?? 
                      json['line'] ?? 
                      json['variation'];

    return CourseBranchModel(
      name: json['name'] ?? '',
      pgn: json['pgn'] ?? '',
      startMoveIndex: (json['startMoveIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] ?? '',
      plies: (pliesData as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => CourseMoveModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
