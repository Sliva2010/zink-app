import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/gigachat_client.dart';
import '../../core/network/gigachat_exception.dart';
import '../../core/providers.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/haptics.dart';
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
- Для математических и химических формул ВСЕГДА используй LaTeX:
  - Инлайн: \$x^2 + 3x - 4\$, \$H_2O\$, \$\\frac{a}{b}\$, \$\\sqrt{2}\$.
  - Отдельным блоком: \$\$E = mc^2\$\$, \$\$\\int_0^1 x\\,dx\$\$.
  - Степени, индексы, дроби, корни, химические индексы — только через LaTeX.
  - НЕ пиши формулы в виде "x^2" вне LaTeX; используй \$x^2\$.
- Если вопрос пустой/непонятный — задай уточняющий вопрос.
- В конце сложных ответов делай краткое резюме одной строкой.
- Не используй эмодзи. Не используй смайлики. Не используй стикеры.
''';
  }

  Future<void> sendMessage(String text) async {
    if (state.streaming) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Проверка сети
    final online = await ConnectivityService.isOnline();
    if (!online) {
      state = state.copyWith(error: 'Нет подключения к интернету');
      await ZinkHaptics.error();
      return;
    }

    await ZinkHaptics.medium();

    final profile = _ref.read(userProfileProvider);
    final userMsg = ChatMessage(role: ChatRole.user, content: trimmed);
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
      for (final m in updatedMessages
          .where((m) => m.role != ChatRole.assistant || m.content.isNotEmpty))
        {
          'role': _roleString(m.role),
          'content': m.content,
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
      // Стрим упал — fallback на sync
      try {
        final fallback = await client.completion(messages: messagesForApi);
        buffer.write(fallback);
        _updateAssistantContent(buffer.toString());
      } catch (_) {
        _finishWithError(e.message);
        await ZinkHaptics.error();
        return;
      }
    } catch (e) {
      _finishWithError(e.toString());
      await ZinkHaptics.error();
      return;
    }

    state = state.copyWith(streaming: false);
    await _persistSession();
    await _awardXp();
    await ZinkHaptics.light();
  }

  /// Регенерировать последний ответ ассистента.
  Future<void> regenerate() async {
    if (state.streaming) return;
    final msgs = state.session.messages;
    if (msgs.isEmpty) return;
    // Убираем последний ответ ассистента
    final withoutLast = msgs.last.role == ChatRole.assistant
        ? msgs.sublist(0, msgs.length - 1)
        : msgs;
    if (withoutLast.isEmpty || withoutLast.last.role != ChatRole.user) return;
    final lastUserText = withoutLast.last.content;
    // Откатываем до состояния перед последним вопросом
    state = state.copyWith(
      session: state.session.copyWith(
        messages: withoutLast.sublist(0, withoutLast.length - 1),
      ),
      clearError: true,
    );
    await sendMessage(lastUserText);
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
