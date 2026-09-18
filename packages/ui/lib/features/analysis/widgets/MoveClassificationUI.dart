import 'package:flutter/material.dart';
import 'package:atlas_core/atlas_core.dart';

class MoveClassificationUI {
  // These icons are declared by the atlas_ui package, so Flutter must use
  // the package asset namespace when resolving them from the host app.
  static const String package = 'atlas_ui';

  static String getAssetName(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.brilliant:
        return 'assets/classifications/Brilliant.png';
      case MoveClassification.great:
        return 'assets/classifications/Great.png';
      case MoveClassification.best:
        return 'assets/classifications/Best.png';
      case MoveClassification.excellent:
        return 'assets/classifications/Excellent.png';
      case MoveClassification.good:
        return 'assets/classifications/Okay.png';
      case MoveClassification.inaccuracy:
        return 'assets/classifications/Inaccuracy.png';
      case MoveClassification.mistake:
        return 'assets/classifications/Mistake.png';
      case MoveClassification.blunder:
        return 'assets/classifications/Blunder.png';
      case MoveClassification.book:
        return 'assets/classifications/Book.png';
      case MoveClassification.forced:
        return 'assets/classifications/Forced.png';
      case MoveClassification.miss:
        return 'assets/classifications/Miss.png';
    }
  }

  static Color getColor(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.brilliant:
        return const Color(0xFF1BB1AC); // Cyan-ish
      case MoveClassification.great:
        return const Color(0xFF5C8BB0); // Blue-ish
      case MoveClassification.best:
        return const Color(0xFF96BC4B); // Green
      case MoveClassification.excellent:
        return const Color(0xFF96BC4B); // Green
      case MoveClassification.good:
        return const Color(0xFF96BC4B).withValues(alpha: 0.8);
      case MoveClassification.inaccuracy:
        return const Color(0xFFF0C152); // Yellow/Orange
      case MoveClassification.mistake:
        return const Color(0xFFE58F2A); // Orange
      case MoveClassification.blunder:
        return const Color(0xFFB33430); // Red
      case MoveClassification.miss:
        return const Color(0xFFB33430); // Red-orange
      case MoveClassification.book:
        return const Color(0xFFD5A47D); // Brown
      case MoveClassification.forced:
        return const Color(0xFF96BC4B); // Green
    }
  }

  static String getLabel(MoveClassification classification) {
    final name = classification.name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
