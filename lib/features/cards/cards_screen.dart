import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/router/route_paths.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../models/flash_card.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  Future<void> _addCard() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddCardSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'Карточки'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.lg),
        child: ValueListenableBuilder<Box<dynamic>>(
          valueListenable: StorageService.cards.listenable(),
          builder: (context, box, _) {
            final cards = box.values
                .whereType<Map>()
                .map(FlashCard.fromJson)
                .toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            final due = cards.where((c) => c.isDue).length;

            if (cards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(ZinkSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.style_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: ZinkSpacing.lg),
                      Text('Создай первую карточку',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: ZinkSpacing.sm),
                      Text(
                        'Карточки SM-2 экономят 80% времени на повторении.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: ZinkSpacing.xl),
                      ZinkButton(
                        label: 'Добавить карточку',
                        icon: Icons.add_rounded,
                        onPressed: _addCard,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: ZinkSpacing.md),
                ZinkCard(
                  padding: const EdgeInsets.all(ZinkSpacing.lg),
                  background: theme.colorScheme.primary,
                  borderColor: theme.colorScheme.primary,
                  onTap: due == 0
                      ? null
                      : () => context.push(RoutePaths.cardsReview),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'К повторению',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$due ${_word(due)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ZinkSpacing.md),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: ZinkSpacing.xxxl),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: ZinkSpacing.sm),
                    itemBuilder: (context, i) {
                      final c = cards[i];
                      return ZinkCard(
                        padding: const EdgeInsets.all(ZinkSpacing.md + 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.front,
                                style: theme.textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              c.back,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _word(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'карточка';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'карточки';
    return 'карточек';
  }
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _front = TextEditingController();
  final _back = TextEditingController();

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  void _save() async {
    if (_front.text.trim().isEmpty || _back.text.trim().isEmpty) return;
    final card = FlashCard(front: _front.text.trim(), back: _back.text.trim());
    await StorageService.cards.put(card.id, card.toJson());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ZinkSpacing.xl,
        ZinkSpacing.lg,
        ZinkSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + ZinkSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: ZinkSpacing.md),
          Text('Новая карточка', style: theme.textTheme.headlineSmall),
          const SizedBox(height: ZinkSpacing.lg),
          ZinkTextField(
            controller: _front,
            label: 'Лицевая сторона',
            hint: 'Вопрос или термин',
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: ZinkSpacing.md),
          ZinkTextField(
            controller: _back,
            label: 'Обратная сторона',
            hint: 'Ответ или определение',
            minLines: 1,
            maxLines: 5,
          ),
          const SizedBox(height: ZinkSpacing.xl),
          ZinkButton(
            label: 'Сохранить',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
