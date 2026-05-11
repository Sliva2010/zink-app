import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_card.dart';
import '../../widgets/zink_logo.dart';
import '../../widgets/zink_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);
    final inverse = ref.watch(inverseModeProvider);

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
          ZinkCard(
            padding: const EdgeInsets.all(ZinkSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (profile?.name ?? '?').characters.first.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: ZinkSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? 'Друг',
                          style: theme.textTheme.titleLarge),
                      if (profile != null)
                        Text(
                          '${profile.age} лет · ${profile.tone.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZinkSpacing.xl),
          Text('Внешний вид', style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          )),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.invert_colors_rounded,
            title: 'Инверсный режим',
            subtitle: inverse ? 'Чёрный фон, белый текст' : 'Белый фон, чёрный текст',
            trailing: Switch(
              value: inverse,
              onChanged: (_) =>
                  ref.read(inverseModeProvider.notifier).toggle(),
              activeColor: theme.colorScheme.primary,
              activeTrackColor:
                  theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: ZinkSpacing.xl),
          Text('Данные', style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          )),
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
            icon: Icons.refresh_rounded,
            title: 'Сбросить онбординг',
            subtitle: 'Пройти заново',
            onTap: () async {
              await ref.read(userProfileProvider.notifier).clear();
              if (!context.mounted) return;
              context.go(RoutePaths.onboarding);
            },
          ),
          const SizedBox(height: ZinkSpacing.xl),
          Text('О приложении', style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          )),
          const SizedBox(height: ZinkSpacing.sm),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'О ZINK',
            subtitle: _version.isEmpty ? '1.0.0' : _version,
            onTap: () => context.push(RoutePaths.about),
          ),
          const SizedBox(height: ZinkSpacing.xl),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ZinkSpacing.md),
              child: Opacity(
                opacity: 0.3,
                child: ZinkLogo(size: 18),
              ),
            ),
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
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
