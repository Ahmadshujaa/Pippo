import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';

class AtlasTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final Function(String)? onChanged;
  /// Height of the input in lines. The default (1) keeps the original
  /// single-line box; pass a larger value for a multi-line message box.
  final int? maxLines;
  final int? minLines;
  /// Hard input cap. When set, pass an empty [counterText] to hide the
  /// built-in counter and render your own below the field instead.
  final int? maxLength;
  final String? counterText;

  const AtlasTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.counterText,
  });

  @override
  State<AtlasTextField> createState() => _AtlasTextFieldState();
}

class _AtlasTextFieldState extends State<AtlasTextField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _isFocused ? AppColors.primary : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused 
                ? theme.cardColor 
                : (isDark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : (_isFocused ? AppColors.primary : theme.dividerColor),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: InputBorder.none,
              counterText: widget.counterText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}


