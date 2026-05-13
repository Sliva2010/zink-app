import 'package:flutter/services.dart';

/// Лёгкая вибрация при значимых действиях.
class ZinkHaptics {
  ZinkHaptics._();

  /// Лёгкий тап — для кнопок, чипов, карточек.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Средний — для отправки сообщения, сохранения.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Успех — для разблокировки достижения, завершения квиза.
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
  }

  /// Ошибка — для неверного ответа, сетевой ошибки.
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Выбор — для переключения чипов, табов.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
