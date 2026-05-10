import 'package:flutter/services.dart';

import '../storage/storage_service.dart';
import '../storage/settings_keys.dart';

/// Обёртка над [HapticFeedback], уважающая настройку «haptics».
class ZinkHaptics {
  ZinkHaptics._();

  static bool get _enabled =>
      StorageService.settings.get(SettingsKeys.hapticsEnabled, defaultValue: true) as bool;

  static Future<void> light() async {
    if (_enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (_enabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    if (_enabled) await HapticFeedback.heavyImpact();
  }

  static Future<void> selection() async {
    if (_enabled) await HapticFeedback.selectionClick();
  }
}
