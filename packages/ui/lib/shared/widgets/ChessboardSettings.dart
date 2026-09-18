import 'package:flutter/material.dart';

import 'package:atlas_ui/l10n/generated/app_localizations.dart';

enum PieceSet {
  cburnett,
  merida,
  staunty,
  alpha,
  maestro,
}

enum BoardTheme { emerald, midnight, purple, sand, blue, brown }

enum LegalMoveIndicatorColor { white, green, blue, amber, red }

enum BoardOrientation { white, black }

class ChessboardSettings {
  final PieceSet pieceSet;
  final BoardTheme boardTheme;
  final bool showLegalMoves;
  final bool enableDragAndDrop;
  final bool playSounds;
  final bool showCoordinates;
  final LegalMoveIndicatorColor legalMoveIndicatorColor;
  final BoardOrientation orientation;

  const ChessboardSettings({
    this.pieceSet = PieceSet.cburnett,
    this.boardTheme = BoardTheme.emerald,
    this.showLegalMoves = true,
    this.enableDragAndDrop = true,
    this.playSounds = true,
    this.showCoordinates = true,
    this.legalMoveIndicatorColor = LegalMoveIndicatorColor.white,
    this.orientation = BoardOrientation.white,
  });

  ChessboardSettings copyWith({
    PieceSet? pieceSet,
    BoardTheme? boardTheme,
    bool? showLegalMoves,
    bool? enableDragAndDrop,
    bool? playSounds,
    bool? showCoordinates,
    LegalMoveIndicatorColor? legalMoveIndicatorColor,
    BoardOrientation? orientation,
  }) {
    return ChessboardSettings(
      pieceSet: pieceSet ?? this.pieceSet,
      boardTheme: boardTheme ?? this.boardTheme,
      showLegalMoves: showLegalMoves ?? this.showLegalMoves,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      playSounds: playSounds ?? this.playSounds,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      legalMoveIndicatorColor:
          legalMoveIndicatorColor ?? this.legalMoveIndicatorColor,
      orientation: orientation ?? this.orientation,
    );
  }

  static const tileColors = <BoardTheme, ({Color light, Color dark})>{
    BoardTheme.emerald: (light: Color(0xFFEBECD0), dark: Color(0xFF769656)),
    BoardTheme.midnight: (light: Color(0xFFD9E8F5), dark: Color(0xFF4D7399)),
    BoardTheme.purple: (light: Color(0xFFEEDDEE), dark: Color(0xFF9B6B9B)),
    BoardTheme.sand: (light: Color(0xFFF0D9B5), dark: Color(0xFFB58863)),
    BoardTheme.blue: (light: Color(0xFFD1D5E8), dark: Color(0xFF586F91)),
    BoardTheme.brown: (light: Color(0xFFEBD1A6), dark: Color(0xFF966F33)),
  };

  /// Localized name of a board theme.
  ///
  /// A method rather than the `Map` this used to be: the theme names are
  /// colour words, they are translated, and so they need the current
  /// localizations to resolve.
  static String themeLabel(BoardTheme theme, AppLocalizations l10n) {
    switch (theme) {
      case BoardTheme.emerald:
        return l10n.boardThemeEmerald;
      case BoardTheme.midnight:
        return l10n.boardThemeMidnight;
      case BoardTheme.purple:
        return l10n.boardThemePurple;
      case BoardTheme.sand:
        return l10n.boardThemeSand;
      case BoardTheme.blue:
        return l10n.boardThemeBlue;
      case BoardTheme.brown:
        return l10n.boardThemeBrown;
    }
  }

  /// Piece-set names stay untranslated on purpose: they name the piece
  /// artwork itself (Cburnett, Merida, Staunty...) and are proper nouns.
  static const pieceSetLabels = <PieceSet, String>{
    PieceSet.cburnett: 'Cburnett',
    PieceSet.merida: 'Merida',
    PieceSet.staunty: 'Staunty',
    PieceSet.alpha: 'Alpha',
    PieceSet.maestro: 'Maestro',
  };

  Color darkTileColor(int x, int y) {
    return tileColors[boardTheme]!.dark;
  }

  Color lightTileColor(int x, int y) {
    return tileColors[boardTheme]!.light;
  }

  Color get legalMoveColor {
    switch (legalMoveIndicatorColor) {
      case LegalMoveIndicatorColor.white:
        return const Color(0xFFFFFFFF);
      case LegalMoveIndicatorColor.green:
        return const Color(0xFF2E9B57);
      case LegalMoveIndicatorColor.blue:
        return const Color(0xFF2878C7);
      case LegalMoveIndicatorColor.amber:
        return const Color(0xFFD18A12);
      case LegalMoveIndicatorColor.red:
        return const Color(0xFFC74444);
    }
  }

  static String pieceAssetPath(PieceSet pieceSet, String pieceCode) {
    final folder = _pieceSetFolder(pieceSet);
    return 'assets/pieces/$folder/$pieceCode.svg';
  }

  static String knightPreviewPath(PieceSet pieceSet) =>
      pieceAssetPath(pieceSet, 'wN');

  static String _pieceSetFolder(PieceSet set) {
    switch (set) {
      case PieceSet.cburnett:
        return 'cburnett';
      case PieceSet.merida:
        return 'merida';
      case PieceSet.staunty:
        return 'staunty';
      case PieceSet.alpha:
        return 'alpha';
      case PieceSet.maestro:
        return 'maestro';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ChessboardSettings &&
      other.pieceSet == pieceSet &&
      other.boardTheme == boardTheme &&
      other.showLegalMoves == showLegalMoves &&
      other.enableDragAndDrop == enableDragAndDrop &&
      other.playSounds == playSounds &&
      other.showCoordinates == showCoordinates &&
      other.legalMoveIndicatorColor == legalMoveIndicatorColor &&
      other.orientation == orientation;

  @override
  int get hashCode => Object.hash(
    pieceSet,
    boardTheme,
    showLegalMoves,
    enableDragAndDrop,
    playSounds,
    showCoordinates,
    legalMoveIndicatorColor,
    orientation,
  );
}
