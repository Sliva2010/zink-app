/// Система уровней ZINK.
///
/// Прогрессия не линейная: каждый следующий уровень требует больше XP.
class LevelSystem {
  LevelSystem._();

  /// Сколько XP суммарно нужно, чтобы достичь уровня [level].
  /// Уровень 1 = 0 XP. Уровень 2 = 50 XP. Дальше — квадратичный рост.
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    final n = level - 1;
    // 50 * n + 10 * n^2
    return (50 * n + 10 * n * n);
  }

  /// Текущий уровень при заданном суммарном XP.
  static int levelForXp(int xp) {
    if (xp <= 0) return 1;
    int level = 1;
    while (totalXpForLevel(level + 1) <= xp && level < 100) {
      level++;
    }
    return level;
  }

  /// Прогресс [0..1] до следующего уровня.
  static double progressToNext(int xp) {
    final lvl = levelForXp(xp);
    final cur = totalXpForLevel(lvl);
    final next = totalXpForLevel(lvl + 1);
    if (next == cur) return 1.0;
    return ((xp - cur) / (next - cur)).clamp(0.0, 1.0);
  }

  /// XP, не достающих до следующего уровня.
  static int xpToNext(int xp) {
    final lvl = levelForXp(xp);
    return totalXpForLevel(lvl + 1) - xp;
  }
}
