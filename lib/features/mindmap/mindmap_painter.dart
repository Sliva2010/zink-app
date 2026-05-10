import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/mind_map.dart';

/// Простой радиальный рендер mind map: корень в центре, дети по кругу.
class MindMapPainter extends CustomPainter {
  MindMapPainter({
    required this.map,
    required this.foreground,
    required this.background,
    required this.outline,
  });

  final MindMap map;
  final Color foreground;
  final Color background;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rootNode = map.root;

    final linePaint = Paint()
      ..color = outline
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final positions = _layout(rootNode, center);

    // Линии
    for (final entry in positions.entries) {
      final node = entry.key;
      final pos = entry.value;
      for (final child in node.children) {
        final childPos = positions[child];
        if (childPos == null) continue;
        canvas.drawLine(pos, childPos, linePaint);
      }
    }

    // Узлы
    for (final entry in positions.entries) {
      final node = entry.key;
      final pos = entry.value;
      final isRoot = identical(node, rootNode);
      _drawNode(canvas, node.label, pos, isRoot: isRoot);
    }
  }

  Map<MindMapNode, Offset> _layout(MindMapNode root, Offset center) {
    final result = <MindMapNode, Offset>{root: center};
    const innerRadius = 220.0;
    const outerRadius = 380.0;

    final children = root.children;
    if (children.isEmpty) return result;

    for (var i = 0; i < children.length; i++) {
      final angle = (2 * pi * i) / children.length - pi / 2;
      final pos = center + Offset(cos(angle), sin(angle)) * innerRadius;
      result[children[i]] = pos;

      // Внуки
      for (var j = 0; j < children[i].children.length; j++) {
        final spread = children[i].children.length == 1
            ? 0.0
            : (j - (children[i].children.length - 1) / 2) * 0.55;
        final childAngle = angle + spread;
        final gPos = center + Offset(cos(childAngle), sin(childAngle)) * outerRadius;
        result[children[i].children[j]] = gPos;
      }
    }
    return result;
  }

  void _drawNode(Canvas canvas, String label, Offset center,
      {required bool isRoot}) {
    final fontSize = isRoot ? 16.0 : 13.0;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isRoot ? background : foreground,
          fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
          fontSize: fontSize,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
      textAlign: TextAlign.center,
    )..layout(maxWidth: isRoot ? 200 : 160);

    final padding = isRoot ? 14.0 : 10.0;
    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + padding * 2,
      height: tp.height + padding * 1.2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final bgPaint = Paint()..color = isRoot ? foreground : background;
    canvas.drawRRect(rrect, bgPaint);
    if (!isRoot) {
      final borderPaint = Paint()
        ..color = outline
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, borderPaint);
    }

    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.foreground != foreground ||
        oldDelegate.background != background ||
        oldDelegate.outline != outline;
  }
}
