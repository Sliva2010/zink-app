import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Карточка для интервального повторения (SuperMemo SM-2).
class FlashCard {
  FlashCard({
    String? id,
    required this.front,
    required this.back,
    this.subject,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
  })  : id = id ?? _uuid.v4(),
        dueDate = dueDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        lastReviewedAt = lastReviewedAt;

  final String id;
  final String front;
  final String back;
  final String? subject;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;

  FlashCard copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
    DateTime? lastReviewedAt,
    String? front,
    String? back,
    String? subject,
  }) =>
      FlashCard(
        id: id,
        front: front ?? this.front,
        back: back ?? this.back,
        subject: subject ?? this.subject,
        easeFactor: easeFactor ?? this.easeFactor,
        intervalDays: intervalDays ?? this.intervalDays,
        repetitions: repetitions ?? this.repetitions,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      );

  bool get isDue => DateTime.now().isAfter(dueDate) ||
      DateTime.now().isAtSameMomentAs(dueDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'subject': subject,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  factory FlashCard.fromJson(Map<dynamic, dynamic> json) {
    return FlashCard(
      id: json['id'] as String?,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      subject: json['subject'] as String?,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.tryParse(json['lastReviewedAt'] as String)
          : null,
    );
  }
}
