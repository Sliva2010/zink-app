import 'package:flutter/material.dart';

import '../core/theme/zink_spacing.dart';
import '../core/utils/haptics.dart';

enum ZinkButtonVariant { solid, outline, ghost }
enum ZinkButtonSize { sm, md, lg }

/// Универсальная кнопка ZINK.
///
/// Дизайн: строгая прямоугольная форма с лёгким скруглением, без теней.
/// Использует haptics на каждом нажатии.
class ZinkButton extends StatefulWidget {
  const ZinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ZinkButtonVariant.solid,
    this.size = ZinkButtonSize.md,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ZinkButtonVariant variant;
  final ZinkButtonSize size;
  final bool expand;
  final bool loading;

  @override
  State<ZinkButton> createState() => _ZinkButtonState();
}

class _ZinkButtonState extends State<ZinkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = widget.onPressed == null || widget.loading;

    final double height;
    final double paddingH;
    final double fontSize;
    switch (widget.size) {
      case ZinkButtonSize.sm:
        height = 40;
        paddingH = 14;
        fontSize = 14;
        break;
      case ZinkButtonSize.md:
        height = 52;
        paddingH = 20;
        fontSize = 15;
        break;
      case ZinkButtonSize.lg:
        height = 60;
        paddingH = 24;
        fontSize = 16;
        break;
    }

    Color bg;
    Color fg;
    Border? border;
    switch (widget.variant) {
      case ZinkButtonVariant.solid:
        bg = scheme.primary;
        fg = scheme.onPrimary;
        border = null;
        break;
      case ZinkButtonVariant.outline:
        bg = scheme.surface;
        fg = scheme.onSurface;
        border = Border.all(color: scheme.onSurface, width: 1.4);
        break;
      case ZinkButtonVariant.ghost:
        bg = Colors.transparent;
        fg = scheme.onSurface;
        border = null;
        break;
    }

    if (disabled) {
      bg = bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.6);
    }

    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () async {
              await ZinkHaptics.light();
              widget.onPressed?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 18),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
