import 'package:flutter/material.dart';

/// Брендовый логотип ZINK — использует avatarka.png из assets.
class ZinkLogo extends StatelessWidget {
  const ZinkLogo({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/avatarka.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
