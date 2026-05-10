import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/router/app_router.dart';
import '../core/theme/zink_theme.dart';

class ZinkApp extends ConsumerWidget {
  const ZinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final inverse = ref.watch(inverseModeProvider);

    return MaterialApp.router(
      title: 'ZINK',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ZinkTheme.light(),
      darkTheme: ZinkTheme.dark(),
      themeMode: inverse ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Зафиксируем масштаб шрифта чтобы дизайн не «плыл» на сильных накрутках
        final scale = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
