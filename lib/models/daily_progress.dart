/// Прогресс пользователя за один день.
class DailyProgress {
  const DailyProgress({
    required this.dateKey, // YYYY-MM-DD
    required this.questionsAsked,
    required this.cardsReviewed,
    required this.quizzesCompleted,
    required this.scansCompleted,
    required this.minutesSpent,
    required this.xpEarned,
  });

  factory DailyProgress.empty(String dateKey) =>
      DailyProgress(
        dateKey: dateKey,
        questionsAsked: 0,
        cardsReviewed: 0,
        quizzesCompleted: 0,
        scansCompleted: 0,
        minutesSpent: 0,
        xpEarned: 0,
      );

  final String dateKey;
  final int questionsAsked;
  final int cardsReviewed;
  final int quizzesCompleted;
  final int scansCompleted;
  final int minutesSpent;
  final int xpEarned;

  DailyProgress copyWith({
    int? questionsAsked,
    int? cardsReviewed,
    int? quizzesCompleted,
    int? scansCompleted,
    int? minutesSpent,
    int? xpEarned,
  }) =>
      DailyProgress(
        dateKey: dateKey,
        questionsAsked: questionsAsked ?? this.questionsAsked,
        cardsReviewed: cardsReviewed ?? this.cardsReviewed,
        quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
        scansCompleted: scansCompleted ?? this.scansCompleted,
        minutesSpent: minutesSpent ?? this.minutesSpent,
        xpEarned: xpEarned ?? this.xpEarned,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'questionsAsked': questionsAsked,
        'cardsReviewed': cardsReviewed,
        'quizzesCompleted': quizzesCompleted,
        'scansCompleted': scansCompleted,
        'minutesSpent': minutesSpent,
        'xpEarned': xpEarned,
      };

  factory DailyProgress.fromJson(Map<dynamic, dynamic> json) {
    return DailyProgress(
      dateKey: json['dateKey'] as String? ?? '',
      questionsAsked: (json['questionsAsked'] as num?)?.toInt() ?? 0,
      cardsReviewed: (json['cardsReviewed'] as num?)?.toInt() ?? 0,
      quizzesCompleted: (json['quizzesCompleted'] as num?)?.toInt() ?? 0,
      scansCompleted: (json['scansCompleted'] as num?)?.toInt() ?? 0,
      minutesSpent: (json['minutesSpent'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
    );
  }
}
