/// Профиль пользователя ZINK.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.preferredSubjects,
    required this.dailyGoal,
    this.tone = LearningTone.friendly,
    this.createdAt,
  });

  final String name;
  final int age;
  final List<String> preferredSubjects;
  final int dailyGoal;
  final LearningTone tone;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? name,
    int? age,
    List<String>? preferredSubjects,
    int? dailyGoal,
    LearningTone? tone,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      tone: tone ?? this.tone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'preferredSubjects': preferredSubjects,
        'dailyGoal': dailyGoal,
        'tone': tone.name,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<dynamic, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      age: (json['age'] as num).toInt(),
      preferredSubjects:
          (json['preferredSubjects'] as List).map((e) => e.toString()).toList(),
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 5,
      tone: LearningTone.values.firstWhere(
        (t) => t.name == (json['tone'] as String? ?? 'friendly'),
        orElse: () => LearningTone.friendly,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

enum LearningTone {
  friendly('Дружеский'),
  formal('Формальный'),
  strict('Строгий'),
  playful('Игровой');

  const LearningTone(this.label);
  final String label;
}
