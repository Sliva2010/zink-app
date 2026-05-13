import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../core/theme/zink_spacing.dart';

/// Виджет, рендерящий смешанный текст: обычные строки + формулы LaTeX.
///
/// Поддерживаемые разделители:
/// - `$...$`  и `$$...$$`
/// - `\(...\)` и `\[...\]`
///
/// Inline-формулы рендерятся в одном потоке с текстом. Display-формулы
/// (`$$...$$` / `\[...\]`) выносятся отдельным центрированным блоком,
/// чтобы выглядели как «выключка» в типографике.
class MathText extends StatelessWidget {
  const MathText({
    super.key,
    required this.text,
    this.style,
    this.selectable = true,
    this.align = TextAlign.start,
  });

  final String text;
  final TextStyle? style;
  final bool selectable;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = style ??
        theme.textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);

    final blocks = _splitDisplay(text);
    if (blocks.length == 1 && !blocks.first.isDisplay) {
      return _inlineRich(context, blocks.first.text, effective);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in blocks)
          if (b.isDisplay)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ZinkSpacing.xs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Math.tex(
                  b.text.trim(),
                  mathStyle: MathStyle.display,
                  textStyle: effective.copyWith(
                    fontSize: (effective.fontSize ?? 14) + 2,
                  ),
                  onErrorFallback: (err) => Text(
                    '\$\$${b.text}\$\$',
                    style: effective,
                  ),
                ),
              ),
            )
          else if (b.text.trim().isNotEmpty)
            _inlineRich(context, b.text, effective),
      ],
    );
  }

  Widget _inlineRich(BuildContext context, String segment, TextStyle effective) {
    final spans = _parseInline(segment, effective);
    final span = TextSpan(style: effective, children: spans);
    return selectable
        ? SelectableText.rich(span, textAlign: align)
        : RichText(text: span, textAlign: align);
  }

  /// Разбиение на display и обычные сегменты.
  List<_Block> _splitDisplay(String src) {
    // Сначала убираем markdown-разметку вне LaTeX-блоков
    final cleaned = _stripMarkdown(src);

    // \[ \] -> $$...$$
    final normalized = cleaned
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$')
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$');

    final blocks = <_Block>[];
    final pattern = RegExp(r'\$\$([\s\S]+?)\$\$', multiLine: true);
    int last = 0;
    for (final m in pattern.allMatches(normalized)) {
      if (m.start > last) {
        blocks.add(_Block(normalized.substring(last, m.start), isDisplay: false));
      }
      blocks.add(_Block(m.group(1) ?? '', isDisplay: true));
      last = m.end;
    }
    if (last < normalized.length) {
      blocks.add(_Block(normalized.substring(last), isDisplay: false));
    }
    if (blocks.isEmpty) {
      blocks.add(_Block(normalized, isDisplay: false));
    }
    return blocks;
  }

  /// Парсер инлайн-формул: $...$.
  List<InlineSpan> _parseInline(String src, TextStyle effective) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\$([^\$\n][^\$\n]*?)\$');
    int last = 0;
    for (final m in pattern.allMatches(src)) {
      if (m.start > last) {
        spans.add(TextSpan(text: src.substring(last, m.start)));
      }
      final body = (m.group(1) ?? '').trim();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          baseline: TextBaseline.alphabetic,
          child: Math.tex(
            body,
            mathStyle: MathStyle.text,
            textStyle: effective,
            onErrorFallback: (err) => Text('\$$body\$', style: effective),
          ),
        ),
      );
      last = m.end;
    }
    if (last < src.length) {
      spans.add(TextSpan(text: src.substring(last)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: src));
    }
    return spans;
  }
  /// Убирает markdown-разметку из текста, сохраняя LaTeX-блоки нетронутыми.
  ///
  /// Удаляет: **bold**, *italic*, __bold__, _italic_, ### заголовки,
  /// `code`, ~~strikethrough~~, > цитаты.
  String _stripMarkdown(String src) {
    // Защищаем LaTeX-блоки: временно заменяем их плейсхолдерами
    final latexBlocks = <String>[];
    String s = src;

    // Защита display LaTeX $$...$$
    s = s.replaceAllMapped(RegExp(r'\$\$([\s\S]+?)\$\$', multiLine: true), (m) {
      latexBlocks.add(m.group(0)!);
      return '\x00LATEX${latexBlocks.length - 1}\x00';
    });
    // Защита inline LaTeX $...$
    s = s.replaceAllMapped(RegExp(r'\$([^\$\n]+?)\$'), (m) {
      latexBlocks.add(m.group(0)!);
      return '\x00LATEX${latexBlocks.length - 1}\x00';
    });

    // Убираем заголовки ### ## #
    s = s.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Убираем **bold** и __bold__
    s = s.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    s = s.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    // Убираем *italic* и _italic_
    s = s.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    s = s.replaceAll(RegExp(r'_(.+?)_'), r'$1');
    // Убираем ~~strikethrough~~
    s = s.replaceAll(RegExp(r'~~(.+?)~~'), r'$1');
    // Убираем `code`
    s = s.replaceAll(RegExp(r'`(.+?)`'), r'$1');
    // Убираем > цитаты
    s = s.replaceAll(RegExp(r'^>\s?', multiLine: true), '');
    // Убираем горизонтальные линии --- или ***
    s = s.replaceAll(RegExp(r'^[-*]{3,}\s*$', multiLine: true), '');

    // Восстанавливаем LaTeX-блоки
    for (var i = 0; i < latexBlocks.length; i++) {
      s = s.replaceAll('\x00LATEX$i\x00', latexBlocks[i]);
    }

    return s;
  }
}

class _Block {
  _Block(this.text, {required this.isDisplay});
  final String text;
  final bool isDisplay;
}
