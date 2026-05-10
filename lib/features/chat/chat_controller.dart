import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/gigachat_client.dart';
import '../../core/network/gigachat_exception.dart';
import '../../core/providers.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/storage/storage_service.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/user_profile.dart';

/// Состояние чата.
class ChatState {
  const ChatState({
    required this.session,
    required this.streaming,
    this.error,
  });

  factory ChatState.fresh() => ChatState(
        session: ChatSession(title: 'Новый диалог', messages: const []),
        streaming: false,
      );

  final ChatSession session;
  final bool streaming;
  final String? error;

  ChatState copyWith({
    ChatSession? session,
    bool? streaming,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      session: session ?? this.session,
      streaming: streaming ?? this.streaming,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Контроллер чата.
class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref, {ChatSession? initial})
      : super(initial != null
            ? ChatState(session: initial, streaming: false)
            : ChatState.fresh());

  final Ref _ref;
  StreamSubscription<String>? _sub;

  String _buildSystemPrompt(UserProfile? profile) {
    final name = profile?.name ?? 'Друг';
    final age = profile?.age;
    final subjects = profile?.preferredSubjects.join(', ') ?? '—';
    final tone = profile?.tone.label ?? 'дружеский';
    return '''
Ты — ZINK, персональный ИИ-репетитор на русском языке. Тебя зовут Зинк.
Твой ученик — $name${age != null ? ', $age лет' : ''}.
Любимые предметы ученика: $subjects.
Стиль общения: $tone.

Правила:
- Отвечай только на русском, чисто и понятно.
- Объясняй пошагово, начиная с простого. Используй короткие абзацы.
- В формулах используй обычные символы (* / + - ^ =), без LaTeX.
- Если вопрос пустой/непонятный — задай уточняющий вопрос.
- В конце сложных ответов делай краткое резюме одной строкой.
- Не используй эмодзи. Не используй смайлики. Не используй стикеры.
''';
  }

  Future<void> sendMessage(String text, {String? attachmentText}) async {
    if (state.streaming) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final profile = _ref.read(userProfileProvider);
    final userMsg = ChatMessage(
      role: ChatRole.user,
      content: trimmed,
      attachmentText: attachmentText,
    );
    final placeholder = ChatMessage(role: ChatRole.assistant, content: '');

    final updatedMessages = [...state.session.messages, userMsg, placeholder];
    final updatedSession = state.session.copyWith(
      messages: updatedMessages,
      title: state.session.messages.isEmpty
          ? _titleFromFirst(trimmed)
          : state.session.title,
    );
    state = state.copyWith(
      session: updatedSession,
      streaming: true,
      clearError: true,
    );

    final GigaChatClient client;
    try {
      client = await _ref.read(gigaChatClientProvider.future);
    } catch (e) {
      _finishWithError(e.toString());
      return;
    }

    final messagesForApi = <Map<String, String>>[
      {'role': 'system', 'content': _buildSystemPrompt(profile)},
      for (final m in updatedMessages.where((m) => m.role != ChatRole.assistant || m.content.isNotEmpty))
        {
          'role': _roleString(m.role),
          'content': m.attachmentText != null && m.attachmentText!.isNotEmpty
              ? '${m.content}\n\nКонтекст из тетради:\n${m.attachmentText}'
              : m.content,
        },
    ];

    final buffer = StringBuffer();
    try {
      await for (final chunk in client.streamCompletion(
        messages: messagesForApi,
        model: AppConfig.gigaChatModel,
      )) {
        buffer.write(chunk);
        _updateAssistantContent(buffer.toString());
      }
    } on GigaChatException catch (e) {
      // Стрим упал — попробуем не-стрим запрос как fallback
      try {
        final fallback = await client.completion(messages: messagesForApi);
        buffer.write(fallback);
        _updateAssistantContent(buffer.toString());
      } catch (_) {
        _finishWithError(e.message);
        return;
      }
    } catch (e) {
      _finishWithError(e.toString());
      return;
    }

    state = state.copyWith(streaming: false);
    await _persistSession();
    await _awardXp();
  }

  void _updateAssistantContent(String content) {
    final msgs = [...state.session.messages];
    final lastIndex = msgs.length - 1;
    msgs[lastIndex] = msgs[lastIndex].copyWith(content: content);
    state = state.copyWith(
      session: state.session.copyWith(messages: msgs),
    );
  }

  void _finishWithError(String error) {
    // Удалить пустой плейсхолдер ассистента
    final msgs = [...state.session.messages];
    if (msgs.isNotEmpty &&
        msgs.last.role == ChatRole.assistant &&
        msgs.last.content.isEmpty) {
      msgs.removeLast();
    }
    state = state.copyWith(
      streaming: false,
      session: state.session.copyWith(messages: msgs),
      error: error,
    );
  }

  Future<void> _persistSession() async {
    final s = state.session;
    if (s.messages.isEmpty) return;
    await StorageService.chats.put(s.id, s.toJson());
  }

  Future<void> _awardXp() async {
    await StreakService.markToday();
    final gain = await GamificationService.addXp(
      AppConfig.xpPerQuestion,
      questionsDelta: 1,
    );
    _ref.read(totalXpProvider.notifier).state = gain.newTotal;
  }

  void newSession() {
    _sub?.cancel();
    state = ChatState.fresh();
  }

  void dismissError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> loadSession(String id) async {
    final raw = StorageService.chats.get(id);
    if (raw is Map) {
      state = ChatState(session: ChatSession.fromJson(raw), streaming: false);
    }
  }

  String _roleString(ChatRole role) {
    switch (role) {
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
      case ChatRole.system:
        return 'system';
    }
  }

  String _titleFromFirst(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 40) return cleaned;
    return '${cleaned.substring(0, 38)}…';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) {
  return ChatController(ref);
});

/// Провайдер для существующей сессии (передаётся id через параметр).
final loadedChatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>((ref, sessionId) {
  final raw = StorageService.chats.get(sessionId);
  final session = raw is Map ? ChatSession.fromJson(raw) : null;
  return ChatController(ref, initial: session);
});
