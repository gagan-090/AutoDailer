// lib/utils/animation_utils.dart - MODERN ANIMATION UTILITIES
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../config/theme_config.dart';

class AnimationUtils {
  // STAGGERED LIST ANIMATIONS
  static Widget staggeredListItem({
    required int index,
    required Widget child,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }

  // STAGGERED GRID ANIMATIONS
  static Widget staggeredGridItem({
    required int index,
    required Widget child,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 375),
      columnCount: 2,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }

  // SLIDE IN FROM SIDE
  static Widget slideInFromLeft({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        horizontalOffset: -50.0,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  static Widget slideInFromRight({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  // SCALE ANIMATION
  static Widget scaleIn({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 375),
      child: ScaleAnimation(
        child: FadeInAnimation(child: child),
      ),
    );
  }

  // BOUNCE ANIMATION
  static Widget bounceIn({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 600),
      child: ScaleAnimation(
        curve: Curves.elasticOut,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  // SLIDE UP ANIMATION
  static Widget slideUp({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  // ANIMATED BUTTON WRAPPER
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => {},
            onTapUp: (_) => onTap(),
            onTapCancel: () => {},
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // SHIMMER LOADING EFFECT
  static Widget shimmerLoading({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConfig.radiusM),
      ),
    );
  }

  // HERO ANIMATION WRAPPER
  static Widget heroWrapper({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  // ANIMATED COUNTER
  static Widget animatedCounter({
    required int value,
    TextStyle? textStyle,
    Duration duration = const Duration(milliseconds: 1000),
    String? suffix,
  }) {
    return TweenAnimationBuilder<int>(
      duration: duration,
      tween: IntTween(begin: 0, end: value),
      builder: (context, animatedValue, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              animatedValue.toString(),
              style: textStyle,
            ),
            if (suffix != null)
              Text(
                suffix,
                style: textStyle?.copyWith(fontSize: (textStyle.fontSize ?? 16) * 0.7),
              ),
          ],
        );
      },
    );
  }

  // PULSE ANIMATION
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 1.0, end: 1.1),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }

  // FLOATING ANIMATION
  static Widget floatingAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 5 * (0.5 - (value * 2 - 1).abs())),
          child: child,
        );
      },
      child: child,
    );
  }

  // ANIMATED PROGRESS BAR
  static Widget animatedProgressBar({
    required double progress,
    Color? color,
    Color? backgroundColor,
    double height = 4.0,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, animatedProgress, child) {
        return LinearProgressIndicator(
          value: animatedProgress,
          backgroundColor: backgroundColor ?? Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? ThemeConfig.accentColor,
          ),
          minHeight: height,
        );
      },
    );
  }

  // RIPPLE EFFECT
  static Widget rippleEffect({
    required Widget child,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(ThemeConfig.radiusM),
        splashColor: ThemeConfig.accentColor.withValues(alpha: 0.1),
        highlightColor: ThemeConfig.accentColor.withValues(alpha: 0.05),
        child: child,
      ),
    );
  }
}

// CUSTOM ANIMATED WIDGETS
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ThemeConfig.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ThemeConfig.animationCurve,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ThemeConfig.animationCurve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: widget.onTap,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

// FLOATING ACTION BUTTON ANIMATION
class AnimatedFAB extends StatefulWidget {
  final List<FABItem> items;
  final Widget mainButton;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AnimatedFAB({
    super.key,
    required this.items,
    required this.mainButton,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -60.0 * (index + 1) * _expandAnimation.value,
                  ),
                  child: Opacity(
                    opacity: _expandAnimation.value.clamp(0.0, 1.0),
                    child: FloatingActionButton(
                      heroTag: item.label,
                      mini: true,
                      onPressed: item.onPressed,
                      backgroundColor: item.backgroundColor,
                      child: item.icon,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
        FloatingActionButton(
          onPressed: widget.onToggle,
          child: AnimatedRotation(
            turns: widget.isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: widget.mainButton,
          ),
        ),
      ],
    );
  }
}

class FABItem {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  FABItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });
}