import '../../models/achievement.dart';
import '../../models/daily_progress.dart';
import '../gamification/achievements_catalog.dart';
import '../gamification/level_system.dart';
import '../storage/settings_keys.dart';
import '../storage/storage_service.dart';
import '../utils/date_utils.dart';
import '../utils/haptics.dart';

/// Сервис геймификации: XP, уровни, прогресс по дням, достижения.
class GamificationService {
  GamificationService._();

  static int get totalXp =>
      StorageService.settings.get(SettingsKeys.totalXp, defaultValue: 0) as int;

  static int get level => LevelSystem.levelForXp(totalXp);

  static double get progressToNext => LevelSystem.progressToNext(totalXp);

  static int get xpToNext => LevelSystem.xpToNext(totalXp);

  /// Прибавить XP. Возвращает (newTotal, levelUp?, newAchievements).
  static Future<XpGain> addXp(
    int amount, {
    int questionsDelta = 0,
    int cardsDelta = 0,
    int quizzesDelta = 0,
    int scansDelta = 0,
    int notesDelta = 0,
  }) async {
    final oldXp = totalXp;
    final oldLevel = LevelSystem.levelForXp(oldXp);
    final newTotal = oldXp + amount;
    await StorageService.settings.put(SettingsKeys.totalXp, newTotal);

    // Дневной прогресс
    final dayKey = ZinkDates.dayKey(DateTime.now());
    final currentRaw = StorageService.progress.get(dayKey);
    final current = currentRaw is Map
        ? DailyProgress.fromJson(currentRaw)
        : DailyProgress.empty(dayKey);
    final updated = current.copyWith(
      xpEarned: current.xpEarned + amount,
      questionsAsked: current.questionsAsked + questionsDelta,
      cardsReviewed: current.cardsReviewed + cardsDelta,
      quizzesCompleted: current.quizzesCompleted + quizzesDelta,
      scansCompleted: current.scansCompleted + scansDelta,
    );
    await StorageService.progress.put(dayKey, updated.toJson());

    final newLevel = LevelSystem.levelForXp(newTotal);
    final levelUp = newLevel > oldLevel;

    // Проверка достижений
    final unlocked = await _checkAchievements(updated, notesDelta);

    return XpGain(newTotal: newTotal, levelUp: levelUp, newLevel: newLevel, unlocked: unlocked);
  }

  static Future<List<Achievement>> _checkAchievements(
    DailyProgress today,
    int notesDelta,
  ) async {
    final already = unlockedIds().toSet();
    final unlocked = <Achievement>[];

    int aggregate(AchievementType t) {
      switch (t) {
        case AchievementType.questions:
          return _aggregateField((p) => p.questionsAsked);
        case AchievementType.cardsReviewed:
          return _aggregateField((p) => p.cardsReviewed);
        case AchievementType.quizzesCompleted:
          return _aggregateField((p) => p.quizzesCompleted);
        case AchievementType.scansCompleted:
          return _aggregateField((p) => p.scansCompleted);
        case AchievementType.streakDays:
          return StorageService.settings
                  .get(SettingsKeys.streakCurrent, defaultValue: 0) as int;
        case AchievementType.xpTotal:
          return totalXp;
        case AchievementType.notesCreated:
          final count = StorageService.notes.length;
          return count;
      }
    }

    for (final a in AchievementsCatalog.all) {
      if (already.contains(a.id)) continue;
      if (aggregate(a.type) >= a.threshold) {
        final unlock = AchievementUnlock(
          achievementId: a.id,
          unlockedAt: DateTime.now(),
        );
        await StorageService.achievements.put(a.id, unlock.toJson());
        unlocked.add(a);
        await ZinkHaptics.success();
      }
    }

    return unlocked;
  }

  static int _aggregateField(int Function(DailyProgress) selector) {
    int sum = 0;
    for (final raw in StorageService.progress.values) {
      if (raw is Map) {
        sum += selector(DailyProgress.fromJson(raw));
      }
    }
    return sum;
  }

  static Iterable<String> unlockedIds() {
    return StorageService.achievements.keys.cast<String>();
  }

  static List<Achievement> unlockedAchievements() {
    final ids = unlockedIds().toSet();
    return AchievementsCatalog.all.where((a) => ids.contains(a.id)).toList();
  }

  static List<DailyProgress> recentProgress({int days = 14}) {
    final now = DateTime.now();
    final result = <DailyProgress>[];
    for (var i = days - 1; i >= 0; i--) {
      final dt = now.subtract(Duration(days: i));
      final key = ZinkDates.dayKey(dt);
      final raw = StorageService.progress.get(key);
      result.add(raw is Map ? DailyProgress.fromJson(raw) : DailyProgress.empty(key));
    }
    return result;
  }

  static DailyProgress today() {
    final key = ZinkDates.dayKey(DateTime.now());
    final raw = StorageService.progress.get(key);
    return raw is Map ? DailyProgress.fromJson(raw) : DailyProgress.empty(key);
  }
}

class XpGain {
  const XpGain({
    required this.newTotal,
    required this.levelUp,
    required this.newLevel,
    required this.unlocked,
  });

  final int newTotal;
  final bool levelUp;
  final int newLevel;
  final List<Achievement> unlocked;
}
