import 'package:flutter/material.dart';

class ZinkDivider extends StatelessWidget {
  const ZinkDivider({super.key, this.height = 1, this.indent = 0, this.endIndent = 0});

  final double height;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
