import 'package:flutter/material.dart';

/// Pippo's logo.
///
/// Always rendered as a square with rounded corners, keeping the image's
/// full yellow background (no cropping, no transparency, no tint).
class PippoAvatar extends StatelessWidget {
  const PippoAvatar({super.key, this.size = 48, this.cornerRadius});

  /// Side length of the square.
  final double size;

  /// Corner radius. Defaults to 28% of [size] when omitted.
  final double? cornerRadius;

  double get _radius => cornerRadius ?? size * 0.28;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/pippo/Pippo.jpeg',
          package: 'atlas_ui',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: const Color(0xFFF5C518),
            alignment: Alignment.center,
            child: Icon(
              Icons.smart_toy_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
