import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/animations/zink_animations.dart';
import '../../core/router/route_paths.dart';
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

  void _shareSession(ChatSession s) {
    final buf = StringBuffer();
    buf.writeln('Диалог: ${s.title}');
    buf.writeln('─' * 30);
    for (final m in s.messages) {
      final who = m.role.name == 'user' ? 'Я' : 'ZINK';
      buf.writeln('$who: ${m.content}');
      buf.writeln();
    }
    Share.share(buf.toString(), subject: s.title);
  }

  void _deleteSession(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить диалог?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.chats.delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: 'История',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
      ),
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
                      // Безопасно берём первое непустое сообщение
                      final preview = s.messages
                          .where((m) => m.content.isNotEmpty)
                          .map((m) => m.content)
                          .firstOrNull ?? '';
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
                                preview,
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
                                  Row(
                                    children: [
                                      Text(
                                        '${s.messages.length} сообщ.',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _shareSession(s),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.share_outlined,
                                            size: 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _deleteSession(s.id),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ],
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
