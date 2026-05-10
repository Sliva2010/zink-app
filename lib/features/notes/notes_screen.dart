import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/animations/zink_animations.dart';
import '../../core/router/route_paths.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../models/note.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';

  void _createNote() async {
    final note = Note(title: 'Новый конспект', content: '');
    await StorageService.notes.put(note.id, note.toJson());
    if (!mounted) return;
    context.push('/notes/${note.id}');
  }

  void _deleteNote(String id) async {
    await StorageService.notes.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: 'Знания',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Карточки',
            onPressed: () => context.push(RoutePaths.cards),
          ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Квизы',
            onPressed: () => context.push(RoutePaths.quiz),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Mind Maps',
            onPressed: () => context.push(RoutePaths.mindmap),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: ZinkSpacing.sm),
            ZinkTextField(
              controller: TextEditingController(text: _query)
                ..selection =
                    TextSelection.collapsed(offset: _query.length),
              hint: 'Поиск по конспектам',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: ZinkSpacing.md),
            Expanded(
              child: ValueListenableBuilder<Box<dynamic>>(
                valueListenable: StorageService.notes.listenable(),
                builder: (context, box, _) {
                  final notes = box.values
                      .whereType<Map>()
                      .map(Note.fromJson)
                      .where((n) =>
                          _query.isEmpty ||
                          n.title.toLowerCase().contains(_query.toLowerCase()) ||
                          n.content.toLowerCase().contains(_query.toLowerCase()))
                      .toList()
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  if (notes.isEmpty) {
                    return _EmptyNotes(onCreate: _createNote);
                  }
                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: ZinkSpacing.xxxl),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: ZinkSpacing.md),
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      return ZinkEntrance(
                        delay: Duration(milliseconds: 30 * i),
                        child: ZinkCard(
                          onTap: () => context.push('/notes/${n.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    onPressed: () => _deleteNote(n.id),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.content.isEmpty ? 'Пусто' : n.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: ZinkSpacing.sm),
                              Text(
                                ZinkDates.humanRelative(n.updatedAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
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
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZinkSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 56,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: ZinkSpacing.lg),
            Text('Конспектов пока нет', style: theme.textTheme.titleLarge),
            const SizedBox(height: ZinkSpacing.sm),
            Text(
              'Сохраняй ответы ИИ или пиши свои.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ZinkSpacing.xl),
            ZinkButton(
              label: 'Создать первый',
              icon: Icons.add_rounded,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
