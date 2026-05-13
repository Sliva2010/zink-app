import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    // Копируем в постоянное хранилище приложения
    final appDir = await getApplicationDocumentsDirectory();
    final dest = File('${appDir.path}/user_avatar.jpg');
    await File(picked.path).copy(dest.path);
    await ref.read(userAvatarPathProvider.notifier).set(dest.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final inverse = ref.watch(inverseModeProvider);
    final avatarPath = ref.watch(userAvatarPathProvider);

    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'Профиль', showBack: false),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ZinkSpacing.lg,
          ZinkSpacing.md,
          ZinkSpacing.lg,
          ZinkSpacing.xxxl,
        ),
        children: [
          // Карточка профиля
          if (profile == null)
            ZinkCard(
              padding: const EdgeInsets.all(ZinkSpacing.lg),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: ZinkSpacing.md),
                  Text(
                    'Профиль не заполнен',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: ZinkSpacing.sm),
                  Text(
                    'Пройди онбординг чтобы ZINK адаптировался под тебя',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ZinkSpacing.lg),
                  ZinkButton(
                    label: 'Заполнить профиль',
                    icon: Icons.edit_rounded,
                    onPressed: () => context.go(RoutePaths.onboarding),
                  ),
                ],
              ),
            )
          else
            ZinkCard(
              padding: const EdgeInsets.all(ZinkSpacing.lg),
              child: Row(
                children: [
                  // Аватарка с возможностью смены
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
                            image: avatarPath != null
                                ? DecorationImage(
                                    image: FileImage(File(avatarPath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: avatarPath == null
                              ? Text(
                                  profile.name.characters.first.toUpperCase(),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(ZinkSpacing.radiusFull),
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ZinkSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: theme.textTheme.titleLarge),
                        Text(
                          '${profile.age} лет · ${profile.tone.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (profile.preferredSubjects.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              profile.preferredSubjects.take(3).join(', ') +
                                  (profile.preferredSubjects.length > 3 ? '...' : ''),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: ZinkSpacing.xl),
          Text(
            'Внешний вид',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.invert_colors_rounded,
            title: 'Инверсный режим',
            subtitle: inverse ? 'Чёрный фон, белый текст' : 'Белый фон, чёрный текст',
            trailing: Switch(
              value: inverse,
              onChanged: (_) => ref.read(inverseModeProvider.notifier).toggle(),
              activeColor: theme.colorScheme.primary,
              activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),

          const SizedBox(height: ZinkSpacing.xl),
          Text(
            'Данные',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: 'Очистить кеш ИИ',
            subtitle: 'Освободит немного памяти',
            onTap: () async {
              await StorageService.aiCache.clear();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Кеш очищен')),
              );
            },
          ),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.delete_sweep_outlined,
            title: 'Очистить историю чатов',
            subtitle: 'Удалить все диалоги',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Удалить все чаты?'),
                  content: const Text(
                      'Все диалоги будут удалены без возможности восстановления.'),
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
                await StorageService.chats.clear();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('История чатов очищена')),
                );
              }
            },
          ),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.refresh_rounded,
            title: 'Сбросить профиль',
            subtitle: 'Пройти онбординг заново',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Сбросить профиль?'),
                  content: const Text('Все данные профиля будут удалены.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(userProfileProvider.notifier).clear();
                await ref.read(userAvatarPathProvider.notifier).clear();
                if (!context.mounted) return;
                context.go(RoutePaths.onboarding);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: ZinkSpacing.md,
        vertical: ZinkSpacing.md - 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: ZinkSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
        ],
      ),
    );
  }
}
