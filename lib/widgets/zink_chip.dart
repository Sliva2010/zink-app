import 'package:flutter/material.dart';

import '../core/theme/zink_spacing.dart';
import '../core/utils/haptics.dart';

class ZinkChip extends StatelessWidget {
  const ZinkChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              ZinkHaptics.selection();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: ZinkSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
