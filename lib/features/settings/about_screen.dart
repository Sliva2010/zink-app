import 'package:flutter/material.dart';

import '../../core/theme/zink_spacing.dart';
import '../../widgets/zink_app_bar.dart';
import '../../widgets/zink_logo.dart';
import '../../widgets/zink_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZinkScaffold(
      appBar: const ZinkAppBar(title: 'О ZINK'),
      body: Padding(
        padding: const EdgeInsets.all(ZinkSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZinkLogo(size: 40),
            const SizedBox(height: ZinkSpacing.md),
            Text(
              'персональный ИИ-репетитор',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: ZinkSpacing.xxl),
            Text(
              'ZINK — твой персональный репетитор на базе GigaChat.\n\n'
              'Объяснит сложное, разберёт задачу, поможет повторить материал. '
              'Работает на российских серверах через защищённое соединение '
              '(сертификаты Минцифры РФ).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: ZinkSpacing.xl),
            Text(
              'Технологии',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: ZinkSpacing.sm),
            Text(
              '• GigaChat:Lite — ИИ-ядро\n'
              '• Flutter 3.x — UI и анимации\n'
              '• Hive — локальный оффлайн-кеш\n'
              '• Speech-to-Text — голосовой ввод\n'
              '• flutter_math_fork — рендеринг LaTeX\n'
              '• Минцифры РФ CA — SSL pinning',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
