import 'package:flutter/material.dart';

import '../core/theme/zink_spacing.dart';

class ZinkCard extends StatelessWidget {
  const ZinkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(ZinkSpacing.lg),
    this.borderColor,
    this.background,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
    );
    return Material(
      color: background ?? theme.colorScheme.surface,
      shape: shape.copyWith(
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
        splashColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: 0.02),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
