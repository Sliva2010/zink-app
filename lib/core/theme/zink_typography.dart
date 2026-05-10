import 'package:flutter/material.dart';

import 'zink_colors.dart';

/// Типографика ZINK.
///
/// Базовый шрифт — Inter (встроен в assets). Если по какой-то причине
/// шрифт не загрузится, fallback — системный sans-serif.
class ZinkTypography {
  ZinkTypography._();

  static const String fontFamily = 'ZinkDisplay';

  static TextTheme buildTextTheme(Color onSurface, Color onSurfaceMuted) {
    return TextTheme(
      // Display — крупные заголовки в Hero-моментах
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 56,
        height: 1.05,
        letterSpacing: -1.5,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 44,
        height: 1.08,
        letterSpacing: -1.0,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        height: 1.1,
        letterSpacing: -0.6,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Headline — заголовки экранов
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        height: 1.15,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        height: 1.2,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Title — карточки/секции
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        height: 1.3,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Body — основной текст
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: onSurfaceMuted,
      ),
      // Label — кнопки, чипы
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.2,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.2,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        height: 1.2,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w500,
        color: onSurfaceMuted,
      ),
    );
  }

  // Вспомогательные стили для брендинга
  static const TextStyle brandWordmark = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
    color: ZinkColors.pureBlack,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.45,
    letterSpacing: 0.2,
  );
}
