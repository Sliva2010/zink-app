import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zink_colors.dart';
import 'zink_spacing.dart';
import 'zink_typography.dart';

/// Сборка темы ZINK.
///
/// `light` — белый фон с чёрным текстом (основной).
/// `dark` — инверсия для «Inverse Mode» в настройках.
class ZinkTheme {
  ZinkTheme._();

  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        background: ZinkColors.pureWhite,
        surface: ZinkColors.pureWhite,
        surfaceMuted: ZinkColors.porcelain,
        surfaceBorder: ZinkColors.mist,
        onSurface: ZinkColors.pureBlack,
        onSurfaceMuted: ZinkColors.steel,
        primary: ZinkColors.pureBlack,
        onPrimary: ZinkColors.pureWhite,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        background: ZinkColors.pureBlack,
        surface: ZinkColors.ink,
        surfaceMuted: ZinkColors.graphite,
        surfaceBorder: ZinkColors.slate,
        onSurface: ZinkColors.pureWhite,
        onSurfaceMuted: ZinkColors.stone,
        primary: ZinkColors.pureWhite,
        onPrimary: ZinkColors.pureBlack,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceMuted,
    required Color surfaceBorder,
    required Color onSurface,
    required Color onSurfaceMuted,
    required Color primary,
    required Color onPrimary,
  }) {
    final textTheme = ZinkTypography.buildTextTheme(onSurface, onSurfaceMuted);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: onSurface,
      onSecondary: onPrimary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceMuted,
      outline: surfaceBorder,
      outlineVariant: surfaceBorder.withValues(alpha: 0.5),
      error: onSurface,
      onError: onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: ZinkTypography.fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      splashColor: onSurface.withValues(alpha: 0.06),
      highlightColor: onSurface.withValues(alpha: 0.04),
      dividerTheme: DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: onSurface, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: 56,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ZinkSpacing.radiusXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
          side: BorderSide(color: surfaceBorder),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusLg),
          side: BorderSide(color: surfaceBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: onSurface,
        linearTrackColor: surfaceBorder,
        circularTrackColor: surfaceBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: onSurfaceMuted),
        labelStyle: textTheme.labelMedium?.copyWith(color: onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ZinkSpacing.lg,
          vertical: ZinkSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
          borderSide: BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
          borderSide: BorderSide(color: onSurface, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusMd),
          borderSide: BorderSide(color: onSurface, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: onSurface.withValues(alpha: 0.08),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: onSurface, size: 22),
        ),
        height: 64,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: onSurface,
          borderRadius: BorderRadius.circular(ZinkSpacing.radiusSm),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: onPrimary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
