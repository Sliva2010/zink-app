import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/zink_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/math_text.dart';
import '../../../widgets/thinking_status.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isStreaming,
    this.waiting = false,
    this.onCopy,
    this.onSpeak,
    this.onSaveAsNote,
  });

  final ChatMessage message;
  final bool isStreaming;
  final bool waiting;
  final VoidCallback? onCopy;
  final VoidCallback? onSpeak;
  final VoidCallback? onSaveAsNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final scheme = theme.colorScheme;

    final bubbleColor = isUser ? scheme.primary : scheme.surface;
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;
    final align = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    // Аватарка пользователя
    final avatarPath = ref.watch(userAvatarPathProvider);
    final userName = ref.watch(userProfileProvider)?.name ?? '';
    final userInitial = userName.isNotEmpty ? userName.characters.first.toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: ZinkSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: align,
        children: [
          // Аватар ZINK (слева для ответов ИИ)
          if (!isUser) ...[
            _ZinkAvatar(color: scheme.onSurface, fg: scheme.onPrimary),
            const SizedBox(width: ZinkSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZinkSpacing.md + 2,
                    vertical: ZinkSpacing.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    border: isUser
                        ? null
                        : Border.all(color: scheme.outline, width: 1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(ZinkSpacing.radiusLg),
                      topRight: const Radius.circular(ZinkSpacing.radiusLg),
                      bottomLeft: Radius.circular(
                        isUser ? ZinkSpacing.radiusLg : ZinkSpacing.radiusXs,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? ZinkSpacing.radiusXs : ZinkSpacing.radiusLg,
                      ),
                    ),
                  ),
                  child: waiting
                      ? ThinkingStatus(color: textColor)
                      : MathText(
                          text: message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ZinkDates.humanTime(message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!isUser && message.content.isNotEmpty && !isStreaming) ...[
                        const SizedBox(width: 8),
                        _ActionBtn(
                          icon: Icons.copy_rounded,
                          onTap: onCopy,
                          tooltip: 'Копировать',
                        ),
                        _ActionBtn(
                          icon: Icons.volume_up_outlined,
                          onTap: onSpeak,
                          tooltip: 'Озвучить',
                        ),
                        if (onSaveAsNote != null)
                          _ActionBtn(
                            icon: Icons.bookmark_add_outlined,
                            onTap: onSaveAsNote,
                            tooltip: 'Сохранить как конспект',
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Аватарка пользователя (справа для сообщений юзера)
          if (isUser) ...[
            const SizedBox(width: ZinkSpacing.sm),
            _UserAvatar(
              avatarPath: avatarPath,
              initial: userInitial,
              color: scheme.primary,
              fg: scheme.onPrimary,
            ),
          ],
        ],
      ),
    );
  }
}

/// Аватар ZINK — буква Z в квадрате
class _ZinkAvatar extends StatelessWidget {
  const _ZinkAvatar({required this.color, required this.fg});

  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
      ),
      alignment: Alignment.center,
      child: Text(
        'Z',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Аватарка пользователя — фото или инициал
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.avatarPath,
    required this.initial,
    required this.color,
    required this.fg,
  });

  final String? avatarPath;
  final String initial;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
        image: avatarPath != null
            ? DecorationImage(
                image: FileImage(File(avatarPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: avatarPath == null
          ? Text(
              initial,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            )
          : null,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      ),
    );
  }
}
