import 'package:flutter/material.dart';
import 'package:atlas_ui/core/theme/AppColors.dart';
import 'package:atlas_ui/shared/widgets/PippoAvatar.dart';

/// Pippo's logo on the left with a comic-style speech bubble on the right.
///
/// The bubble is the classic comic "someone is speaking" shape: rounded on the
/// top and far side, with a short flat tail on the bottom-left corner pointing
/// back at the avatar.
class PippoChatBubble extends StatelessWidget {
  const PippoChatBubble({
    super.key,
    this.message,
    this.avatarSize = 52,
    this.showAvatar = true,
    this.fixedHeight,
  });

  /// Text to display inside the speech bubble. When null the bubble hides.
  final String? message;

  /// Side length of the Pippo logo. A little big by default.
  final double avatarSize;

  /// Set to false when the bubble should stand alone (no avatar).
  final bool showAvatar;

  /// Fixed height for the message AREA (the bubble adds its own padding on
  /// top). When set, the bubble never grows beyond that height: longer
  /// messages scroll inside and a small down-arrow hints at the hidden text.
  /// Used for the game-review explanations so a long review can never squeeze
  /// the board. When null, the bubble sizes itself to the message.
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message;

    final messageText = Text(
      // Only rendered when `text != null` (see the AnimatedSwitcher child
      // below); the ?? '' merely satisfies null safety for the eager build.
      text ?? '',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimaryOf(context),
      ),
    );

    final bubble = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: child,
        ),
      ),
      child: text == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey('bubble-$text'),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: fixedHeight == null
                  ? messageText
                  : _BubbleScrollArea(height: fixedHeight!, message: messageText),
            ),
    );

    if (!showAvatar) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Flexible(child: bubble)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PippoAvatar(size: avatarSize),
        Expanded(child: bubble),
      ],
    );
  }
}

/// Fixed-height scrollable message area used inside the speech bubble.
///
/// Shows a small, subtle down arrow in the bottom-right corner while there is
/// hidden content below the fold, so the user knows the bubble scrolls. The
/// arrow disappears once the bottom is reached (or when nothing overflows).
class _BubbleScrollArea extends StatefulWidget {
  final double height;
  final Text message;

  const _BubbleScrollArea({required this.height, required this.message});

  @override
  State<_BubbleScrollArea> createState() => _BubbleScrollAreaState();
}

class _BubbleScrollAreaState extends State<_BubbleScrollArea> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCanScrollDown);
    // The text is laid out after the first frame — only then do we know the
    // real scroll extent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCanScrollDown();
    });
  }

  @override
  void didUpdateWidget(_BubbleScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new message can change the scroll extent in either direction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateCanScrollDown();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCanScrollDown() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final bool can =
        position.maxScrollExtent > 0 &&
        _scrollController.offset < position.maxScrollExtent - 2;
    if (can != _canScrollDown) {
      setState(() => _canScrollDown = can);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: widget.message,
          ),
          if (_canScrollDown)
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Theme.of(context).hintColor.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
