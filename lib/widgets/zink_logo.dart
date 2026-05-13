import 'package:flutter/material.dart';

import '../core/theme/zink_typography.dart';

/// Брендовый логотип-вордмарк ZINK.
class ZinkLogo extends StatelessWidget {
  const ZinkLogo({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'ZINK',
      style: ZinkTypography.brandWordmark.copyWith(
        fontSize: size,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }
}
