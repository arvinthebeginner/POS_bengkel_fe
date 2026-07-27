import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color tokens for the "Kinetic Tactility" design system generated in
/// stitch_markdown_design_system/kinetic_tactility/DESIGN.md.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFF4FAFD);
  static const surfaceDim = Color(0xFFD4DBDD);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEEF5F7);
  static const surfaceContainer = Color(0xFFE8EFF1);
  static const surfaceContainerHigh = Color(0xFFE2E9EC);

  static const onSurface = Color(0xFF161D1F);
  static const onSurfaceVariant = Color(0xFF5D3F3B);
  static const outline = Color(0xFF926F6A);

  static const primary = Color(0xFF940003);
  static const primaryContainer = Color(0xFFC10207);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFF595F65);
  static const secondaryContainer = Color(0xFFDEE3EA);

  static const error = Color(0xFFBA1A1A);

  static const successFill = Color(0xFFB7E4C7);
  static const successText = Color(0xFF2F9E5B);
  static const warningFill = Color(0xFFFBE7A1);
  static const warningText = Color(0xFFB8860B);
  static const errorFill = Color(0xFFF5C6C6);
  static const errorText = Color(0xFFC0392B);

  /// Light-side shadow on raised/pressed neumorphic surfaces.
  static const neuLight = Color(0xFFFFFFFF);

  /// Dark-side shadow on raised/pressed neumorphic surfaces.
  static const neuShadow = Color(0xFFB8BFC9);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryContainer,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    );

    final headlineFont = GoogleFonts.quicksandTextTheme();
    final bodyFont = GoogleFonts.interTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: headlineFont.displayLarge,
      displayMedium: headlineFont.displayMedium,
      displaySmall: headlineFont.displaySmall,
      headlineLarge: headlineFont.headlineLarge,
      headlineMedium: headlineFont.headlineMedium,
      headlineSmall: headlineFont.headlineSmall,
      titleLarge: headlineFont.titleLarge,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
