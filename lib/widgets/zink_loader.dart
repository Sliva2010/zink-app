import 'package:flutter/material.dart';

/// Минималистичный лоадер ZINK — тонкая окружность.
class ZinkLoader extends StatelessWidget {
  const ZinkLoader({super.key, this.size = 28, this.strokeWidth = 2.0, this.color});

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Три «точки», бегающие как при печати ответа ИИ.
class ZinkTypingDots extends StatefulWidget {
  const ZinkTypingDots({super.key, this.color, this.size = 6});

  final Color? color;
  final double size;

  @override
  State<ZinkTypingDots> createState() => _ZinkTypingDotsState();
}

class _ZinkTypingDotsState extends State<ZinkTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value + i * 0.18) % 1.0;
            final opacity = 0.3 + 0.7 * (1 - (phase * 2 - 1).abs());
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
