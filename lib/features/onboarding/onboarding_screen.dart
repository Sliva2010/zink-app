import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/zink_spacing.dart';
import '../../core/utils/haptics.dart';
import '../../models/user_profile.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_chip.dart';
import '../../widgets/zink_logo.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';

const _subjects = [
  'Математика',
  'Алгебра',
  'Геометрия',
  'Физика',
  'Химия',
  'Биология',
  'Русский',
  'Литература',
  'История',
  'Обществознание',
  'География',
  'Информатика',
  'Английский',
  'Немецкий',
  'Французский',
  'Экономика',
];

const _dailyGoals = [3, 5, 8, 12];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '14');

  int _page = 0;
  final Set<String> _selectedSubjects = {};
  int _dailyGoal = 5;
  LearningTone _tone = LearningTone.friendly;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0 && _nameCtrl.text.trim().isEmpty) return;
    if (_page == 1 && (int.tryParse(_ageCtrl.text.trim()) ?? 0) < 5) return;
    if (_page < 4) {
      ZinkHaptics.selection();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      setState(() => _page++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_page == 0) return;
    ZinkHaptics.selection();
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    setState(() => _page--);
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 14,
      preferredSubjects: _selectedSubjects.toList(),
      dailyGoal: _dailyGoal,
      tone: _tone,
      createdAt: DateTime.now(),
    );
    await ref.read(userProfileProvider.notifier).save(profile);
    await StreakService.markToday();
    if (!mounted) return;
    context.go(RoutePaths.home);
  }

  bool get _canProceed {
    switch (_page) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 1:
        final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
        return age >= 5 && age <= 99;
      case 2:
        return _selectedSubjects.isNotEmpty;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: ZinkSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  TextButton(
                    onPressed: _page == 4 ? null : _finish,
                    child: Text(
                      _page == 4 ? '' : 'Пропустить',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ZinkSpacing.md),
                child: _ProgressDots(total: 5, current: _page),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _NamePage(controller: _nameCtrl, onChanged: (_) => setState(() {})),
                    _AgePage(controller: _ageCtrl, onChanged: (_) => setState(() {})),
                    _SubjectsPage(
                      selected: _selectedSubjects,
                      onToggle: (s) => setState(() {
                        if (!_selectedSubjects.add(s)) _selectedSubjects.remove(s);
                      }),
                    ),
                    _DailyGoalPage(
                      selected: _dailyGoal,
                      onSelect: (v) => setState(() => _dailyGoal = v),
                    ),
                    _TonePage(
                      selected: _tone,
                      onSelect: (t) => setState(() => _tone = t),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: ZinkSpacing.md),
                child: ZinkButton(
                  label: _page == 4 ? 'Начать' : 'Дальше',
                  icon: _page == 4 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  expand: true,
                  size: ZinkButtonSize.lg,
                  onPressed: _canProceed ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: active ? 28 : 16,
          decoration: BoxDecoration(
            color: active ? scheme.onSurface : scheme.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZinkLogo(size: 32),
        const SizedBox(height: ZinkSpacing.xxl),
        Text('Как тебя зовут?', style: theme.textTheme.headlineLarge),
        const SizedBox(height: ZinkSpacing.md),
        Text(
          'Чтобы я обращался к тебе по имени и адаптировал ответы под твой стиль.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: ZinkSpacing.xxl),
        ZinkTextField(
          controller: controller,
          hint: 'Имя',
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          maxLength: 32,
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }
}

class _AgePage extends StatelessWidget {
  const _AgePage({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Сколько тебе лет?', style: theme.textTheme.headlineLarge),
        const SizedBox(height: ZinkSpacing.md),
        Text(
          'Это поможет подбирать сложность объяснений.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: ZinkSpacing.xxl),
        ZinkTextField(
          controller: controller,
          hint: 'Возраст',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          maxLength: 3,
        ),
      ],
    );
  }
}

class _SubjectsPage extends StatelessWidget {
  const _SubjectsPage({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Любимые предметы', style: theme.textTheme.headlineLarge),
        const SizedBox(height: ZinkSpacing.md),
        Text(
          'Выбери хотя бы один. Я подберу темы и приоритеты.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: ZinkSpacing.xl),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: ZinkSpacing.sm,
              runSpacing: ZinkSpacing.sm,
              children: [
                for (final s in _subjects)
                  ZinkChip(
                    label: s,
                    selected: selected.contains(s),
                    onTap: () => onToggle(s),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyGoalPage extends StatelessWidget {
  const _DailyGoalPage({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Цель на день', style: theme.textTheme.headlineLarge),
        const SizedBox(height: ZinkSpacing.md),
        Text(
          'Сколько вопросов в день оптимально для тебя?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: ZinkSpacing.xl),
        for (final g in _dailyGoals)
          Padding(
            padding: const EdgeInsets.only(bottom: ZinkSpacing.md),
            child: _GoalOption(
              value: g,
              selected: selected == g,
              onTap: () => onSelect(g),
            ),
          ),
      ],
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: ZinkSpacing.lg,
          vertical: ZinkSpacing.md + 4,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Text(
              '$value',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
            const SizedBox(width: ZinkSpacing.md),
            Expanded(
              child: Text(
                value == 3
                    ? 'Лёгкий темп'
                    : value == 5
                        ? 'Стабильный темп'
                        : value == 8
                            ? 'Уверенный темп'
                            : 'Интенсивно',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? scheme.onPrimary : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _TonePage extends StatelessWidget {
  const _TonePage({required this.selected, required this.onSelect});

  final LearningTone selected;
  final ValueChanged<LearningTone> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Стиль общения', style: theme.textTheme.headlineLarge),
        const SizedBox(height: ZinkSpacing.md),
        Text(
          'Каким должен быть тон ответов?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: ZinkSpacing.xl),
        Expanded(
          child: ListView(
            children: [
              for (final t in LearningTone.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: ZinkSpacing.md),
                  child: _ToneOption(
                    tone: t,
                    selected: selected == t,
                    onTap: () => onSelect(t),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToneOption extends StatelessWidget {
  const _ToneOption({required this.tone, required this.selected, required this.onTap});

  final LearningTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(ZinkSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tone.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? scheme.onPrimary : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
