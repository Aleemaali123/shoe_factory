import 'package:flutter/material.dart';

/// Fades and rises its child. Staggers with [index].
/// Plays when a [TickerMode] above it is enabled, so offstage tabs wait.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.dy = 18,
  });

  final Widget child;
  final int index;
  final double dy;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final delay = widget.index.clamp(0, 8) * 45;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 460 + delay),
    );
    final start = delay / (460 + delay);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.dy),
            child: child,
          ),
        );
      },
    );
  }
}

/// Shrinks slightly while a finger is down. Does not steal the child's taps.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PopIn extends StatelessWidget {
  const PopIn(
      {super.key,
      required this.child,
      this.duration = const Duration(milliseconds: 280)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1),
      duration: duration,
      curve: Curves.elasticOut,
      child: child,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
    );
  }
}
