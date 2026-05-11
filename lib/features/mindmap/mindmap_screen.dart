import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/zink_spacing.dart';
import '../../models/mind_map.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_button.dart';
import '../../widgets/zink_scaffold.dart';
import '../../widgets/zink_text_field.dart';
import 'mindmap_painter.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  const MindMapScreen({super.key});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen> {
  final _topicCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  MindMap? _map;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _topicCtrl.dispose();
    _transformCtrl.dispose();
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
                'Ты — генератор интеллект-карт. Отвечай строго в формате JSON.'
          },
          {
            'role': 'user',
            'content':
                'Построй интеллект-карту по теме «$topic» на русском. Глубина 3 уровня. Формат строго JSON: {"label":"$topic","children":[{"label":"...","children":[{"label":"...","children":[]},...]},...]}. Без вступления, только JSON.'
          },
        ],
        temperature: 0.5,
        maxTokens: 1400,
      );
      final json = _extractJson(response);
      if (json == null) throw const FormatException('JSON не получен');
      final root = MindMapNode.fromJson(json);
      setState(() => _map = MindMap(title: topic, root: root));
    } catch (e) {
      setState(() => _error = 'Не удалось построить карту. Попробуйте другую тему.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _extractJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start < 0 || end < 0) return null;
    try {
      return jsonDecode(response.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: ZinkAppBar(
        title: 'Mind Map',
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go(RoutePaths.home),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZinkSpacing.xl,
              ZinkSpacing.md,
              ZinkSpacing.xl,
              ZinkSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ZinkTextField(
                    controller: _topicCtrl,
                    hint: 'Тема для карты',
                    prefixIcon: Icons.account_tree_outlined,
                  ),
                ),
                const SizedBox(width: ZinkSpacing.sm),
                ZinkButton(
                  label: 'Построить',
                  onPressed: _loading ? null : _generate,
                  loading: _loading,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ZinkSpacing.xl),
              child: Text(_error!, style: theme.textTheme.bodySmall),
            ),
          Expanded(
            child: _map == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(ZinkSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            size: 56,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: ZinkSpacing.md),
                          Text(
                            'Введите тему и нажмите «Построить»',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 0.4,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(400),
                    child: CustomPaint(
                      size: const Size(2200, 1600),
                      painter: MindMapPainter(
                        map: _map!,
                        foreground: theme.colorScheme.onSurface,
                        background: theme.colorScheme.surface,
                        outline: theme.colorScheme.outline,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
