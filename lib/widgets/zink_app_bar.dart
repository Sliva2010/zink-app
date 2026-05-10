import 'package:flutter/material.dart';

import '../core/theme/zink_spacing.dart';
import '../core/utils/haptics.dart';

/// AppBar в стиле ZINK: чистый, без теней, с тонкой нижней рамкой.
class ZinkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZinkAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBack = true,
    this.bottom,
    this.elevation = false,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;
  final PreferredSizeWidget? bottom;
  final bool elevation;

  @override
  Size get preferredSize => Size.fromHeight(
        56 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: elevation
                ? theme.colorScheme.outline
                : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: ZinkSpacing.sm),
                  if (leading != null)
                    leading!
                  else if (showBack && canPop)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        ZinkHaptics.light();
                        Navigator.maybePop(context);
                      },
                    )
                  else
                    const SizedBox(width: ZinkSpacing.sm),
                  if (title != null)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: (showBack && canPop) ? 0 : ZinkSpacing.sm,
                        ),
                        child: Text(
                          title!,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (actions != null) ...actions!,
                  const SizedBox(width: ZinkSpacing.sm),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
