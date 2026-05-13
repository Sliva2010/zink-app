import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/zink_animations.dart';
import '../../core/gamification/level_system.dart';
import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/storage/storage_service.dart';
import '../../models/flash_card.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';
import 'widgets/level_badge.dart';
import 'widgets/quick_action.dart';
import 'widgets/streak_card.dart';
import 'widgets/daily_goal_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final xp = ref.watch(totalXpProvider);
    final level = LevelSystem.levelForXp(xp);
    final today = GamificationService.today();
    final streak = StreakService.current;
    // Карточки к повторению
    final dueCards = StorageService.cards.values
        .whereType<Map>()
        .map(FlashCard.fromJson)
        .where((c) => c.isDue)
        .length;

    return ZinkScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZinkSpacing.xl,
          ZinkSpacing.md,
          ZinkSpacing.xl,
          ZinkSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка: приветствие + уровень
            ZinkEntrance(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.name ?? 'Друг',
                          style: theme.textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  LevelBadge(level: level),
                ],
              ),
            ),
            const SizedBox(height: ZinkSpacing.xl),

            // Карточка XP
            ZinkEntrance(
              delay: const Duration(milliseconds: 60),
              child: _XpCard(xp: xp, level: level),
            ),
            const SizedBox(height: ZinkSpacing.md),

            // Streak + Daily goal
            Row(
              children: [
                Expanded(
                  child: ZinkEntrance(
                    delay: const Duration(milliseconds: 100),
                    child: StreakCard(streak: streak),
                  ),
                ),
                const SizedBox(width: ZinkSpacing.md),
                Expanded(
                  child: ZinkEntrance(
                    delay: const Duration(milliseconds: 140),
                    child: DailyGoalCard(
                      done: today.questionsAsked,
                      target: profile?.dailyGoal ?? 5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: ZinkSpacing.xl),
            if (dueCards > 0) ...[
              ZinkEntrance(
                delay: const Duration(milliseconds: 160),
                child: ZinkCard(
                  onTap: () => context.go(RoutePaths.cardsReview),
                  padding: const EdgeInsets.all(ZinkSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
                        ),
                        child: Icon(
                          Icons.style_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: ZinkSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Карточки ждут повторения',
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              '$dueCards ${_cardWord(dueCards)} к повторению',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ZinkSpacing.md),
            ],
            Text('Быстрые действия', style: theme.textTheme.titleLarge),
            const SizedBox(height: ZinkSpacing.md),

            ZinkEntrance(
              delay: const Duration(milliseconds: 180),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: ZinkSpacing.md,
                mainAxisSpacing: ZinkSpacing.md,
                childAspectRatio: 1.3,
                children: [
                  QuickAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Спросить',
                    subtitle: 'Чат с ИИ',
                    onTap: () => context.go(RoutePaths.chat),
                  ),
                  QuickAction(
                    icon: Icons.menu_book_outlined,
                    title: 'Конспекты',
                    subtitle: 'Мои заметки',
                    onTap: () => context.go(RoutePaths.notes),
                  ),
                  QuickAction(
                    icon: Icons.style_outlined,
                    title: 'Карточки',
                    subtitle: 'Повторение',
                    onTap: () => context.go(RoutePaths.cards),
                  ),
                  QuickAction(
                    icon: Icons.quiz_outlined,
                    title: 'Квиз',
                    subtitle: 'Проверка знаний',
                    onTap: () => context.go(RoutePaths.quiz),
                  ),
                  QuickAction(
                    icon: Icons.account_tree_outlined,
                    title: 'Mind Map',
                    subtitle: 'Структура темы',
                    onTap: () => context.go(RoutePaths.mindmap),
                  ),
                  QuickAction(
                    icon: Icons.history_rounded,
                    title: 'История',
                    subtitle: 'Прошлые диалоги',
                    onTap: () => context.go(RoutePaths.chatHistory),
                  ),
                ],
              ),
            ),

            const SizedBox(height: ZinkSpacing.xl),

            // Совет дня
            ZinkEntrance(
              delay: const Duration(milliseconds: 220),
              child: ZinkCard(
                onTap: () => context.go(RoutePaths.chat),
                padding: const EdgeInsets.all(ZinkSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: ZinkSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Совет дня',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tipOfDay(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cardWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'карточка';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'карточки';
    return 'карточек';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи,';
    if (hour < 12) return 'Доброе утро,';
    if (hour < 18) return 'Добрый день,';
    return 'Добрый вечер,';
  }

  String _tipOfDay() {
    final tips = [
      'Объясняй сложные темы своими словами — это закрепляет знания',
      'Повторяй за 5 минут до сна — память работает на ура',
      'Не понял тему? Спроси ZINK тремя разными способами — найдёшь свой',
      'Сложности с темой? Создай Mind Map и увидь структуру целиком',
      'Карточки SRS экономят 80% времени на повторении',
    ];
    final i = (DateTime.now().day +
            DateTime.now().month +
            DateTime.now().year) %
        tips.length;
    return tips[i];
  }
}

class _XpCard extends StatelessWidget {
  const _XpCard({required this.xp, required this.level});

  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = LevelSystem.progressToNext(xp);
    final toNext = LevelSystem.xpToNext(xp);
    final today = GamificationService.today();

    return Container(
      padding: const EdgeInsets.all(ZinkSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Уровень $level',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '+${today.xpEarned} XP сегодня',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZinkSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                xp.toString(),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ZinkSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    color: scheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'до следующего уровня — $toNext XP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
