import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/services/gamification_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';
import '../../models/quiz.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_scaffold.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  Quiz? _quiz;
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    final raw = StorageService.quizzes.get(widget.quizId);
    if (raw is Map) _quiz = Quiz.fromJson(raw);
  }

  Future<void> _submit() async {
    if (_selected == null || _quiz == null) return;
    final correct = _quiz!.questions[_index].correctIndex;
    final isCorrect = _selected == correct;
    if (isCorrect) {
      _correctCount++;
      final gain = await GamificationService.addXp(
        AppConfig.xpPerQuizCorrect,
      );
      ref.read(totalXpProvider.notifier).state = gain.newTotal;
      ZinkHaptics.medium();
    } else {
      ZinkHaptics.light();
    }
    setState(() => _revealed = true);
  }

  Future<void> _next() async {
    if (_quiz == null) return;
    if (_index < _quiz!.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
    } else {
      // Финал
      final updated = _quiz!.copyWith(
        score: _correctCount,
        completedAt: DateTime.now(),
      );
      await StorageService.quizzes.put(updated.id, updated.toJson());
      await GamificationService.addXp(0, quizzesDelta: 1);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _QuizResultScreen(quiz: updated),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = _quiz;
    if (quiz == null) {
      return ZinkScaffold(
        appBar: const ZinkAppBar(title: 'Квиз'),
        body: const Center(child: Text('Квиз не найден')),
      );
    }
    final q = quiz.questions[_index];
    final correct = q.correctIndex;

    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: '${_index + 1} / ${quiz.questions.length}',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: ZinkSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (_index + 1) / quiz.questions.length,
                minHeight: 4,
                backgroundColor: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: ZinkSpacing.xl),
            Text(q.question, style: theme.textTheme.headlineSmall),
            const SizedBox(height: ZinkSpacing.xl),
            ...List.generate(q.options.length, (i) {
              final isSelected = _selected == i;
              final isCorrect = i == correct;
              Color borderColor = theme.colorScheme.outline;
              Color bg = theme.colorScheme.surface;
              Color fg = theme.colorScheme.onSurface;
              if (_revealed) {
                if (isCorrect) {
                  borderColor = theme.colorScheme.onSurface;
                  bg = theme.colorScheme.primary;
                  fg = theme.colorScheme.onPrimary;
                } else if (isSelected) {
                  borderColor = theme.colorScheme.onSurface;
                }
              } else if (isSelected) {
                borderColor = theme.colorScheme.onSurface;
                bg = theme.colorScheme.surfaceContainerHighest;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: ZinkSpacing.sm),
                child: GestureDetector(
                  onTap: _revealed
                      ? null
                      : () {
                          ZinkHaptics.selection();
                          setState(() => _selected = i);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ZinkSpacing.lg,
                      vertical: ZinkSpacing.md + 2,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border.all(color: borderColor, width: 1.4),
                      borderRadius:
                          BorderRadius.circular(ZinkSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Text(
                          String.fromCharCode(65 + i),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: fg.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: ZinkSpacing.md),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: fg,
                            ),
                          ),
                        ),
                        if (_revealed && isCorrect)
                          Icon(Icons.check_circle, color: fg, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_revealed && q.explanation != null && q.explanation!.isNotEmpty) ...[
              const SizedBox(height: ZinkSpacing.md),
              Container(
                padding: const EdgeInsets.all(ZinkSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
                ),
                child: Text(q.explanation!, style: theme.textTheme.bodySmall),
              ),
            ],
            const Spacer(),
            ZinkButton(
              label: _revealed
                  ? (_index == quiz.questions.length - 1 ? 'Завершить' : 'Дальше')
                  : 'Проверить',
              size: ZinkButtonSize.lg,
              expand: true,
              onPressed: _selected == null
                  ? null
                  : (_revealed ? _next : _submit),
            ),
            const SizedBox(height: ZinkSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _QuizResultScreen extends StatelessWidget {
  const _QuizResultScreen({required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = quiz.score ?? 0;
    final total = quiz.questions.length;
    final percent = total == 0 ? 0 : (100 * score / total).round();
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'Результат'),
      body: Padding(
        padding: const EdgeInsets.all(ZinkSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$percent%', style: theme.textTheme.displayLarge),
            const SizedBox(height: ZinkSpacing.sm),
            Text('$score из $total верно',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: ZinkSpacing.xl),
            Text(
              quiz.topic,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            ZinkButton(
              label: 'На главную',
              icon: Icons.home_rounded,
              expand: true,
              size: ZinkButtonSize.lg,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}
