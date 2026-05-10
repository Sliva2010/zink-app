import 'package:flutter/material.dart';

/// Чёрно-белая палитра ZINK.
///
/// Строгая монохромная гамма: только чёрный, белый и оттенки серого.
/// Цвет используется как смысловой акцент (фокус, состояние), не для декора.
class ZinkColors {
  ZinkColors._();

  // Основа
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Промежуточные оттенки для иерархии
  static const Color ink = Color(0xFF0A0A0A);
  static const Color graphite = Color(0xFF1A1A1A);
  static const Color slate = Color(0xFF333333);
  static const Color steel = Color(0xFF666666);
  static const Color stone = Color(0xFF9A9A9A);
  static const Color mist = Color(0xFFCFCFCF);
  static const Color paper = Color(0xFFF2F2F2);
  static const Color porcelain = Color(0xFFF7F7F7);
  static const Color snow = Color(0xFFFAFAFA);

  // Полупрозрачные оверлеи (для overlay/scrim)
  static const Color overlayLight = Color(0x14000000);
  static const Color overlayMedium = Color(0x29000000);
  static const Color overlayStrong = Color(0x52000000);
}
