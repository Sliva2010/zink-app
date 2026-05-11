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
    // \[ \] -> $$...$$
    final normalized = src
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
}

class _Block {
  _Block(this.text, {required this.isDisplay});
  final String text;
  final bool isDisplay;
}
