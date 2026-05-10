import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../models/quiz.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_chip.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';
import 'quiz_play_screen.dart';

class QuizSetupScreen extends ConsumerStatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  ConsumerState<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends ConsumerState<QuizSetupScreen> {
  final _topicCtrl = TextEditingController();
  int _count = 5;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref.read(gigaChatClientProvider.future);
      final response = await client.completion(
        messages: [
          {
            'role': 'system',
            'content':
                'Ты — генератор учебных квизов. Отвечай строго в формате JSON.'
          },
          {
            'role': 'user',
            'content':
                'Сгенерируй $_count вопросов по теме «$topic» на русском. Для каждого: 4 варианта ответа, один правильный. Формат строго JSON: {"questions":[{"q":"...","options":["...","...","...","..."],"correct":0,"explain":"..."}]}. Без вступления, только JSON.'
          },
        ],
        temperature: 0.4,
        maxTokens: 1400,
      );
      final parsed = _extractJson(response);
      if (parsed == null) {
        throw const FormatException('Не удалось распарсить JSON');
      }
      final list = (parsed['questions'] as List?) ?? [];
      final questions = list.map((raw) {
        final m = raw as Map<String, dynamic>;
        return QuizQuestion(
          question: (m['q'] as String?)?.trim() ?? '',
          options:
              ((m['options'] as List?) ?? []).map((e) => e.toString()).toList(),
          correctIndex: (m['correct'] as num?)?.toInt() ?? 0,
          explanation: (m['explain'] as String?)?.trim(),
        );
      }).where((q) => q.options.length >= 2).toList();
      if (questions.isEmpty) {
        throw const FormatException('Пустой список вопросов');
      }
      final quiz = Quiz(topic: topic, questions: questions);
      await StorageService.quizzes.put(quiz.id, quiz.toJson());
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizPlayScreen(quizId: quiz.id)),
      );
    } catch (e) {
      setState(() => _error = 'Не удалось сгенерировать квиз. Попробуйте другую тему.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _extractJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start < 0 || end < 0) return null;
    final raw = response.substring(start, end + 1);
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'Квиз'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZinkSpacing.md),
            Text(
              'Выбери тему — ИИ соберёт квиз',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: ZinkSpacing.md),
            ZinkTextField(
              controller: _topicCtrl,
              hint: 'Например: фотосинтез',
              prefixIcon: Icons.search_rounded,
            ),
            const SizedBox(height: ZinkSpacing.xl),
            Text('Количество вопросов', style: theme.textTheme.labelLarge),
            const SizedBox(height: ZinkSpacing.sm),
            Wrap(
              spacing: ZinkSpacing.sm,
              children: [3, 5, 7, 10]
                  .map((c) => ZinkChip(
                        label: '$c',
                        selected: _count == c,
                        onTap: () => setState(() => _count = c),
                      ))
                  .toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: ZinkSpacing.md),
              Text(_error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface)),
            ],
            const Spacer(),
            ZinkButton(
              label: _loading ? 'Генерирую...' : 'Сгенерировать',
              icon: Icons.bolt_rounded,
              size: ZinkButtonSize.lg,
              expand: true,
              loading: _loading,
              onPressed: _loading ? null : _generate,
            ),
            const SizedBox(height: ZinkSpacing.xl),
          ],
        ),
      ),
    );
  }
}
