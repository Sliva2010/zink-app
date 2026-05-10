import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';
import '../../models/chat_message.dart';
import '../../models/note.dart';
import '../../core/storage/storage_service.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_scaffold.dart';
import 'chat_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _saveAsNote(BuildContext context, ChatMessage message) async {
    final note = Note(
      title: 'Конспект из чата',
      content: message.content,
    );
    await StorageService.notes.put(note.id, note.toJson());
    if (!context.mounted) return;
    ZinkHaptics.medium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено в конспекты')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final ctrl = ref.read(chatControllerProvider.notifier);

    // Автоскролл вниз при изменениях
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ZinkScaffold(
      safeArea: false,
      appBar: ZinkAppBar(
        title: state.session.messages.isEmpty
            ? 'Новый диалог'
            : state.session.title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go(RoutePaths.home),
        ),
        actions: [
          IconButton(
            tooltip: 'История',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.go(RoutePaths.chatHistory),
          ),
          IconButton(
            tooltip: 'Новый диалог',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              ZinkHaptics.medium();
              ctrl.newSession();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.error != null)
              _ErrorBar(
                error: state.error!,
                onDismiss: ctrl.dismissError,
              ),
            Expanded(
              child: state.session.messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        ZinkSpacing.lg,
                        ZinkSpacing.md,
                        ZinkSpacing.lg,
                        ZinkSpacing.lg,
                      ),
                      itemCount: state.session.messages.length,
                      itemBuilder: (context, index) {
                        final m = state.session.messages[index];
                        final isStreaming =
                            state.streaming && index == state.session.messages.length - 1;
                        return MessageBubble(
                          message: m,
                          isStreaming: isStreaming,
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: m.content));
                            ZinkHaptics.light();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Скопировано')),
                            );
                          },
                          onSpeak: () => unawaited(TtsService.speak(m.content)),
                          onSaveAsNote: m.role == ChatRole.assistant
                              ? () => _saveAsNote(context, m)
                              : null,
                        );
                      },
                    ),
            ),
            ChatComposer(
              streaming: state.streaming,
              onSend: (text, ocrText) => ctrl.sendMessage(text, attachmentText: ocrText),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examples = [
      'Объясни теорему Пифагора простыми словами',
      'Расскажи о Великой Отечественной войне',
      'Помоги решить уравнение 2x² - 4x + 1 = 0',
      'Что такое генетика? Кратко',
      'Сравни клетки растений и животных',
    ];
    return Padding(
      padding: const EdgeInsets.all(ZinkSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: ZinkSpacing.lg),
          Text(
            'Спроси что угодно',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: ZinkSpacing.sm),
          Text(
            'Я объясню тему пошагово, разберу задачу или подскажу, с чего начать.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: ZinkSpacing.xl),
          Text(
            'Примеры:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: ZinkSpacing.sm),
          for (final e in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $e', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.error, required this.onDismiss});

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: ZinkSpacing.lg,
        vertical: ZinkSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 18, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, color: theme.colorScheme.onPrimary, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
