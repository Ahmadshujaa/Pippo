import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/l10n/generated/app_localizations.dart';

/// A dialog for editing a MongoDB-backed text (explanations, hints, theory...).
///
/// The dialog owns its [TextEditingController], so the controller is disposed
/// only when the dialog route is fully torn down (after its exit animation).
/// Disposing it in the caller right after `showDialog` resolves — while the
/// animating-out TextField is still listening — crashes with
/// "A TextEditingController was used after being disposed".
class ExplanationEditDialog extends StatefulWidget {
  /// Shown above the text field (e.g. "Move: e4" or "Hint: Nf3").
  final String title;

  /// The initial text loaded into the field.
  final String initialText;

  /// Label of the text field's hint. Defaults to 'Write the explanation...'.
  final String? hintText;

  const ExplanationEditDialog({
    super.key,
    required this.title,
    required this.initialText,
    this.hintText,
  });

  /// Pops the dialog with the (untrimmed) entered text, or null on cancel.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialText,
    String? hintText,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ExplanationEditDialog(
        title: title,
        initialText: initialText,
        hintText: hintText,
      ),
    );
  }

  @override
  State<ExplanationEditDialog> createState() => _ExplanationEditDialogState();
}

class _ExplanationEditDialogState extends State<ExplanationEditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.editExplanationTitle,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            maxLength: 2000,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimaryOf(context),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? l10n.writeExplanationHint,
              hintStyle: TextStyle(
                color: AppColors.textTertiaryOf(context),
              ),
              filled: true,
              fillColor: AppColors.backgroundOf(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
