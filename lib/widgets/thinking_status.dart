import 'dart:async';

import 'package:flutter/material.dart';

import 'zink_loader.dart';

/// Циклически меняющийся текст-статус, пока модель «думает».
///
/// Каждые ~2.4с меняется надпись:
/// 1. «Думает…»
/// 2. «Печатает…»
/// 3. «Ведёт поиск в интернете…»
///
/// Сопровождается тремя пульсирующими точками ZinkTypingDots.
class ThinkingStatus extends StatefulWidget {
  const ThinkingStatus({super.key, this.color});

  final Color? color;

  @override
  State<ThinkingStatus> createState() => _ThinkingStatusState();
}

class _ThinkingStatusState extends State<ThinkingStatus> {
  static const _phrases = <String>[
    'Думает…',
    'Печатает…',
    'Ведёт поиск в интернете…',
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _phrases.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZinkTypingDots(color: color),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            final fade = FadeTransition(opacity: anim, child: child);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(anim),
              child: fade,
            );
          },
          child: Text(
            _phrases[_index],
            key: ValueKey<int>(_index),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.85),
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
