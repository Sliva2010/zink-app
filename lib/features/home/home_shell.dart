import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final index = _indexFromLocation(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outline, width: 1)),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _TabItem(
                  icon: Icons.home_outlined,
                  iconActive: Icons.home_rounded,
                  label: 'Главная',
                  active: index == 0,
                  onTap: () {
                    ZinkHaptics.selection();
                    context.go(RoutePaths.home);
                  },
                ),
                _TabItem(
                  icon: Icons.menu_book_outlined,
                  iconActive: Icons.menu_book_rounded,
                  label: 'Знания',
                  active: index == 1,
                  onTap: () {
                    ZinkHaptics.selection();
                    context.go(RoutePaths.notes);
                  },
                ),
                _TabItem(
                  icon: Icons.bar_chart_outlined,
                  iconActive: Icons.bar_chart_rounded,
                  label: 'Прогресс',
                  active: index == 2,
                  onTap: () {
                    ZinkHaptics.selection();
                    context.go(RoutePaths.achievements);
                  },
                ),
                _TabItem(
                  icon: Icons.person_outline_rounded,
                  iconActive: Icons.person_rounded,
                  label: 'Профиль',
                  active: index == 3,
                  onTap: () {
                    ZinkHaptics.selection();
                    context.go(RoutePaths.settings);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(RoutePaths.settings)) return 3;
    if (location.startsWith(RoutePaths.achievements)) return 2;
    if (location.startsWith(RoutePaths.notes) ||
        location.startsWith(RoutePaths.cards) ||
        location.startsWith(RoutePaths.quiz) ||
        location.startsWith(RoutePaths.mindmap)) {
      return 1;
    }
    return 0;
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: scheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ZinkSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  active ? iconActive : icon,
                  key: ValueKey(active),
                  size: 24,
                  color: active
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.3,
                  color: active
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
