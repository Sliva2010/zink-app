import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Конспект — сохранённая «заметка» из чата или созданная вручную.
class Note {
  Note({
    String? id,
    required this.title,
    required this.content,
    this.subject,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String content;
  final String? subject;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({
    String? title,
    String? content,
    String? subject,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        subject: subject ?? this.subject,
        tags: tags ?? this.tags,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<dynamic, dynamic> json) {
    return Note(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Без названия',
      content: json['content'] as String? ?? '',
      subject: json['subject'] as String?,
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
