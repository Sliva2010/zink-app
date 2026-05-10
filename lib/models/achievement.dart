/// Достижение в системе геймификации ZINK.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.type,
    this.iconCode = 0xe5ca, // material check
  });

  final String id;
  final String title;
  final String description;
  final int threshold;
  final AchievementType type;
  final int iconCode;
}

enum AchievementType {
  questions,
  cardsReviewed,
  quizzesCompleted,
  scansCompleted,
  streakDays,
  xpTotal,
  notesCreated,
}

class AchievementUnlock {
  const AchievementUnlock({
    required this.achievementId,
    required this.unlockedAt,
  });

  final String achievementId;
  final DateTime unlockedAt;

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'unlockedAt': unlockedAt.toIso8601String(),
      };

  factory AchievementUnlock.fromJson(Map<dynamic, dynamic> json) {
    return AchievementUnlock(
      achievementId: json['achievementId'] as String? ?? '',
      unlockedAt: DateTime.tryParse(json['unlockedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
