import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gamification/achievements_catalog.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../models/achievement.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unlockedIds = GamificationService.unlockedIds().toSet();
    final progress = GamificationService.recentProgress(days: 14);
    final all = AchievementsCatalog.all;

    final maxXp = progress.fold<int>(
        0, (m, p) => p.xpEarned > m ? p.xpEarned : m);
    final yMax = (maxXp + 10).clamp(20, 999).toDouble();

    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'Прогресс', showBack: false),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZinkSpacing.lg,
          ZinkSpacing.md,
          ZinkSpacing.lg,
          ZinkSpacing.xxxl,
        ),
        children: [
          // Текущий статус
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Стрик',
                  value: '${StreakService.current}',
                  subtitle: 'дней подряд',
                ),
              ),
              const SizedBox(width: ZinkSpacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Лучший',
                  value: '${StreakService.best}',
                  subtitle: 'дней рекорд',
                ),
              ),
            ],
          ),
          const SizedBox(height: ZinkSpacing.md),

          // График XP за 14 дней
          ZinkCard(
            padding: const EdgeInsets.all(ZinkSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP за 14 дней', style: theme.textTheme.titleMedium),
                const SizedBox(height: ZinkSpacing.md),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      maxY: yMax,
                      backgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yMax / 3,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.colorScheme.outline,
                          strokeWidth: 0.5,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      barGroups: [
                        for (var i = 0; i < progress.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: progress[i].xpEarned.toDouble(),
                              color: theme.colorScheme.onSurface,
                              width: 8,
                              borderRadius:
                                  const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: ZinkSpacing.xl),
          Text('Достижения', style: theme.textTheme.titleLarge),
          const SizedBox(height: ZinkSpacing.md),

          for (final a in all)
            Padding(
              padding: const EdgeInsets.only(bottom: ZinkSpacing.sm),
              child: _AchievementRow(
                achievement: a,
                unlocked: unlockedIds.contains(a.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkCard(
      padding: const EdgeInsets.all(ZinkSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.displaySmall),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.unlocked,
  });

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ZinkSpacing.md,
        vertical: ZinkSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: unlocked ? scheme.primary : scheme.surface,
        border: Border.all(
            color: unlocked ? scheme.primary : scheme.outline, width: 1),
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: unlocked ? scheme.onPrimary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
            ),
            child: Icon(
              unlocked ? Icons.emoji_events_rounded : Icons.lock_outline,
              color: unlocked ? scheme.primary : scheme.onSurface,
              size: 18,
            ),
          ),
          const SizedBox(width: ZinkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: unlocked ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: unlocked
                        ? scheme.onPrimary.withValues(alpha: 0.7)
                        : scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle, color: scheme.onPrimary, size: 18)
          else
            Icon(Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
