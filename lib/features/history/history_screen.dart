import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/animations/zink_animations.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../models/chat_session.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'История'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: ZinkSpacing.sm),
            ZinkTextField(
              controller: TextEditingController(text: _query)
                ..selection = TextSelection.collapsed(offset: _query.length),
              hint: 'Поиск по диалогам',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: ZinkSpacing.md),
            Expanded(
              child: ValueListenableBuilder<Box<dynamic>>(
                valueListenable: StorageService.chats.listenable(),
                builder: (context, box, _) {
                  final sessions = box.values
                      .whereType<Map>()
                      .map(ChatSession.fromJson)
                      .where((s) {
                    if (_query.isEmpty) return true;
                    final q = _query.toLowerCase();
                    return s.title.toLowerCase().contains(q) ||
                        s.messages.any((m) => m.content.toLowerCase().contains(q));
                  }).toList()
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ZinkSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 56,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: ZinkSpacing.md),
                            Text('Истории пока нет',
                                style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: ZinkSpacing.xxxl),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: ZinkSpacing.md),
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      final firstUserMsg = s.messages.firstWhere(
                        (m) => m.content.isNotEmpty,
                        orElse: () =>
                            s.messages.isEmpty ? s.messages.first : s.messages.first,
                      );
                      return ZinkEntrance(
                        delay: Duration(milliseconds: 30 * i),
                        child: ZinkCard(
                          onTap: () => context.push('/chat/${s.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(
                                firstUserMsg.content,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: ZinkSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ZinkDates.humanRelative(s.updatedAt),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Text(
                                    '${s.messages.length} сообщ.',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
