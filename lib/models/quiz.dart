import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<dynamic, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String?,
    );
  }
}

class Quiz {
  Quiz({
    String? id,
    required this.topic,
    required this.questions,
    DateTime? createdAt,
    this.score,
    this.completedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String topic;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final int? score;
  final DateTime? completedAt;

  Quiz copyWith({int? score, DateTime? completedAt}) => Quiz(
        id: id,
        topic: topic,
        questions: questions,
        createdAt: createdAt,
        score: score ?? this.score,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'score': score,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Quiz.fromJson(Map<dynamic, dynamic> json) {
    return Quiz(
      id: json['id'] as String?,
      topic: json['topic'] as String? ?? '',
      questions: (json['questions'] as List? ?? [])
          .map((e) => QuizQuestion.fromJson(e as Map))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      score: (json['score'] as num?)?.toInt(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
