import 'package:uuid/uuid.dart';

import 'chat_message.dart';

const _uuid = Uuid();

/// Сессия диалога с ИИ-репетитором.
class ChatSession {
  ChatSession({
    String? id,
    required this.title,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.subject,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String? subject;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? title,
    List<ChatMessage>? messages,
    String? subject,
    DateTime? updatedAt,
  }) =>
      ChatSession(
        id: id,
        title: title ?? this.title,
        subject: subject ?? this.subject,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChatSession.fromJson(Map<dynamic, dynamic> json) {
    return ChatSession(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Без названия',
      subject: json['subject'] as String?,
      messages: (json['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(e as Map))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
