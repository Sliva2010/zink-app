import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ChatRole { user, assistant, system }

class ChatMessage {
  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.attachmentText,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  /// Доп. текстовая нагрузка: например, распознанный OCR-текст.
  final String? attachmentText;

  ChatMessage copyWith({String? content}) => ChatMessage(
        id: id,
        role: role,
        content: content ?? this.content,
        createdAt: createdAt,
        attachmentText: attachmentText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'attachmentText': attachmentText,
      };

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      role: ChatRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => ChatRole.user,
      ),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      attachmentText: json['attachmentText'] as String?,
    );
  }
}
