import 'package:flutter/material.dart';

import '../../../core/theme/zink_spacing.dart';
import '../../../widgets/zink_card.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.done, required this.target});

  final int done;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    return ZinkCard(
      padding: const EdgeInsets.all(ZinkSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(
                'Цель',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: ZinkSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$done',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  ' / $target',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZinkSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
