import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/ChessboardSettings.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

class ChessboardSettingsDialog extends StatefulWidget {
  final ChessboardSettings initialSettings;
  final ValueChanged<ChessboardSettings> onSettingsChanged;

  const ChessboardSettingsDialog({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<ChessboardSettingsDialog> createState() =>
      _ChessboardSettingsDialogState();
}

class _ChessboardSettingsDialogState extends State<ChessboardSettingsDialog> {
  late ChessboardSettings _settings;

  static const _pieceSets = PieceSet.values;
  static const _boardThemes = BoardTheme.values;
  static const _indicators = LegalMoveIndicatorColor.values;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.boardSettingsTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(l10n.pieceSetLabel, _buildPieceSetGrid),
            const SizedBox(height: 20),
            _buildSection(l10n.boardThemeLabel, _buildBoardThemeGrid),
            const SizedBox(height: 20),
            _buildSection(l10n.moveIndicatorLabel, _buildIndicatorRow),
            const SizedBox(height: 16),
            _buildSwitch(l10n.showCoordinatesLabel, _settings.showCoordinates,
                (v) => _update(_settings.copyWith(showCoordinates: v))),
            _buildSwitch(l10n.dragAndDropLabel, _settings.enableDragAndDrop,
                (v) => _update(_settings.copyWith(enableDragAndDrop: v))),
            _buildSwitch(l10n.soundLabel, _settings.playSounds,
                (v) => _update(_settings.copyWith(playSounds: v))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.closeButton,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget Function() builder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
                fontSize: 13)),
        const SizedBox(height: 10),
        builder(),
      ],
    );
  }

  Widget _buildPieceSetGrid() {
    return SizedBox(
      height: 94,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _pieceSets.map((set) {
            final selected = _settings.pieceSet == set;
            final label = ChessboardSettings.pieceSetLabels[set]!;
            final preview = ChessboardSettings.knightPreviewPath(set);
            final isLast = set == _pieceSets.last;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: _buildPieceChip(set, label, preview, selected, _updatePieceSet),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieceChip(
      PieceSet set, String label, String previewPath, bool selected, ValueChanged<PieceSet> onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onSelect(set),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : (isDark ? AppColors.surfaceSubtleDark : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              previewPath,
              package: 'atlas_ui',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardThemeGrid() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 72,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _boardThemes.map((theme) {
            final selected = _settings.boardTheme == theme;
            final colors = ChessboardSettings.tileColors[theme]!;
            final isLast = theme == _boardThemes.last;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: _ThemeChip(
                light: colors.light,
                dark: colors.dark,
                label: ChessboardSettings.themeLabel(theme, l10n),
                selected: selected,
                onTap: () => _update(_settings.copyWith(boardTheme: theme)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIndicatorRow() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: _indicators.map((c) {
        final selected = _settings.legalMoveIndicatorColor == c;
        final color = ChessboardSettings(legalMoveIndicatorColor: c).legalMoveColor;
        return Expanded(
          child: _IndicatorDotChip(
            color: color,
            label: _indicatorLabel(l10n, c),
            selected: selected,
            onTap: () =>
                _update(_settings.copyWith(legalMoveIndicatorColor: c)),
          ),
        );
      }).toList(),
    );
  }

  /// Move-indicator color name in the on-screen language. White reuses the
  /// side name; blue reuses the board-theme blue.
  String _indicatorLabel(AppLocalizations l10n, LegalMoveIndicatorColor c) {
    switch (c) {
      case LegalMoveIndicatorColor.white:
        return l10n.sideWhite;
      case LegalMoveIndicatorColor.green:
        return l10n.indicatorGreen;
      case LegalMoveIndicatorColor.blue:
        return l10n.boardThemeBlue;
      case LegalMoveIndicatorColor.amber:
        return l10n.indicatorAmber;
      case LegalMoveIndicatorColor.red:
        return l10n.indicatorRed;
    }
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _updatePieceSet(PieceSet set) => _update(_settings.copyWith(pieceSet: set));

  void _update(ChessboardSettings s) {
    setState(() => _settings = s);
    widget.onSettingsChanged(s);
  }
}

class _ThemeChip extends StatelessWidget {
  final Color light;
  final Color dark;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.light,
    required this.dark,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                width: 2.5,
              ),
              boxShadow: selected
                  ? [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    )]
                  : null,
              gradient: LinearGradient(
                colors: [light, light, dark, dark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.48, 0.52, 1.0],
              ),
            ),
            child: selected
                ? Icon(Icons.check, color: isDark ? Colors.white70 : Colors.white, size: 16)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorDotChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndicatorDotChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : (isDark ? AppColors.surfaceSubtleDark : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? AppColors.surfaceSubtleDark : Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}