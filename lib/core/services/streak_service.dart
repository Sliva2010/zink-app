import '../storage/settings_keys.dart';
import '../storage/storage_service.dart';
import '../utils/date_utils.dart';

/// Сервис подсчёта стриков.
class StreakService {
  StreakService._();

  static int get current =>
      StorageService.settings.get(SettingsKeys.streakCurrent, defaultValue: 0) as int;

  static int get best =>
      StorageService.settings.get(SettingsKeys.streakBest, defaultValue: 0) as int;

  static DateTime? get lastDay {
    final s = StorageService.settings.get(SettingsKeys.streakLastDay) as String?;
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  /// Зафиксировать активность сегодня. Возвращает текущее значение стрика.
  static Future<int> markToday() async {
    final today = DateTime.now();
    final todayKey = ZinkDates.dayKey(today);
    final lastKey = lastDay != null ? ZinkDates.dayKey(lastDay!) : null;
    if (lastKey == todayKey) return current;

    int newCurrent;
    if (lastDay == null) {
      newCurrent = 1;
    } else {
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));
      final yesterdayKey = ZinkDates.dayKey(yesterday);
      if (lastKey == yesterdayKey) {
        newCurrent = current + 1;
      } else {
        newCurrent = 1; // стрик сбросился
      }
    }

    final box = StorageService.settings;
    await box.put(SettingsKeys.streakCurrent, newCurrent);
    await box.put(SettingsKeys.streakLastDay, today.toIso8601String());
    if (newCurrent > best) {
      await box.put(SettingsKeys.streakBest, newCurrent);
    }
    return newCurrent;
  }
}
