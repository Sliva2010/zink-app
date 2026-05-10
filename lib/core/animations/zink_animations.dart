import 'package:flutter/material.dart';

/// Готовые анимированные виджеты ZINK для микровзаимодействий.
class ZinkEntrance extends StatelessWidget {
  const ZinkEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final dx = (1 - value) * offset.dx;
        final dy = (1 - value) * offset.dy * MediaQuery.sizeOf(context).height;
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          ),
        );
      },
    );
  }
}

/// Pulse-эффект (для голосового микрофона, например)
class ZinkPulse extends StatefulWidget {
  const ZinkPulse({
    super.key,
    required this.child,
    this.active = true,
    this.minScale = 0.96,
    this.maxScale = 1.04,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final bool active;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<ZinkPulse> createState() => _ZinkPulseState();
}

class _ZinkPulseState extends State<ZinkPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ZinkPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = widget.minScale +
            (widget.maxScale - widget.minScale) * _ctrl.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// Шиммер — для скелетонов
class ZinkShimmer extends StatefulWidget {
  const ZinkShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ZinkShimmer> createState() => _ZinkShimmerState();
}

class _ZinkShimmerState extends State<ZinkShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = widget.highlightColor ??
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.18);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
              begin: Alignment(-1.0 - 2 * _ctrl.value, 0),
              end: Alignment(1.0 - 2 * _ctrl.value, 0),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
