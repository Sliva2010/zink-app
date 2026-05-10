import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/services/gamification_service.dart';
import '../../core/srs/sm2.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';
import '../../models/flash_card.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_scaffold.dart';

class CardsReviewScreen extends ConsumerStatefulWidget {
  const CardsReviewScreen({super.key});

  @override
  ConsumerState<CardsReviewScreen> createState() => _CardsReviewScreenState();
}

class _CardsReviewScreenState extends ConsumerState<CardsReviewScreen> {
  List<FlashCard> _queue = [];
  bool _revealed = false;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  void _loadQueue() {
    final all = StorageService.cards.values
        .whereType<Map>()
        .map(FlashCard.fromJson)
        .where((c) => c.isDue)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    setState(() {
      _queue = all;
      _revealed = false;
    });
  }

  Future<void> _grade(int quality) async {
    if (_queue.isEmpty) return;
    final card = _queue.first;
    final updated = Sm2.apply(card, quality);
    await StorageService.cards.put(updated.id, updated.toJson());

    final gain = await GamificationService.addXp(
      AppConfig.xpPerCardReview,
      cardsDelta: 1,
    );
    ref.read(totalXpProvider.notifier).state = gain.newTotal;

    ZinkHaptics.light();
    setState(() {
      _queue.removeAt(0);
      _doneCount++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_queue.isEmpty) {
      return ZinkScaffold(
        appBar: const ZinkAppBar(title: 'Повторение'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(ZinkSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4)),
                const SizedBox(height: ZinkSpacing.lg),
                Text(
                  _doneCount > 0 ? 'Все карточки повторены' : 'Сейчас ничего нет',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: ZinkSpacing.sm),
                if (_doneCount > 0)
                  Text(
                    'Повторено: $_doneCount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: ZinkSpacing.xl),
                ZinkButton(
                  label: 'Назад',
                  icon: Icons.arrow_back_rounded,
                  variant: ZinkButtonVariant.outline,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = _queue.first;
    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: 'Осталось: ${_queue.length}',
      ),
      body: Padding(
        padding: const EdgeInsets.all(ZinkSpacing.xl),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1.0)
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey('${current.id}-$_revealed'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(ZinkSpacing.xl),
                    decoration: BoxDecoration(
                      color: _revealed
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                          color: theme.colorScheme.outline, width: 1.4),
                      borderRadius:
                          BorderRadius.circular(ZinkSpacing.radiusLg),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          _revealed ? current.back : current.front,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ZinkSpacing.md),
            Text(
              _revealed ? 'Как вспомнилось?' : 'Нажми на карточку, чтобы увидеть ответ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: ZinkSpacing.md),
            if (_revealed)
              Row(
                children: [
                  Expanded(
                    child: _GradeBtn(
                      label: 'Сложно',
                      quality: 2,
                      onTap: _grade,
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.sm),
                  Expanded(
                    child: _GradeBtn(
                      label: 'Норм',
                      quality: 4,
                      onTap: _grade,
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.sm),
                  Expanded(
                    child: _GradeBtn(
                      label: 'Легко',
                      quality: 5,
                      onTap: _grade,
                    ),
                  ),
                ],
              )
            else
              ZinkButton(
                label: 'Показать ответ',
                expand: true,
                onPressed: () => setState(() => _revealed = true),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradeBtn extends StatelessWidget {
  const _GradeBtn({
    required this.label,
    required this.quality,
    required this.onTap,
  });

  final String label;
  final int quality;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return ZinkButton(
      label: label,
      variant: ZinkButtonVariant.outline,
      size: ZinkButtonSize.md,
      onPressed: () => onTap(quality),
      expand: true,
    );
  }
}
