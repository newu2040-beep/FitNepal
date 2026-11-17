import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

class FitNepalTheme {
  FitNepalTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: FitNepalColors.canvasBlush,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FitNepalColors.berryRed,
        brightness: Brightness.light,
        primary: FitNepalColors.berryRed,
        onPrimary: Colors.white,
        surface: FitNepalColors.surfaceWhite,
        onSurface: FitNepalColors.deepPlum,
        secondary: FitNepalColors.berryLight,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: FitNepalColors.deepPlum,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: FitNepalColors.deepPlum,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FitNepalColors.deepPlum,
        displayColor: FitNepalColors.deepPlum,
      ),
      cardTheme: CardTheme(
        color: FitNepalColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FitNepalSpacing.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FitNepalColors.deepPlum,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FitNepalColors.darkCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FitNepalColors.berryRed,
        brightness: Brightness.dark,
        primary: FitNepalColors.berryLight,
        onPrimary: Colors.white,
        surface: FitNepalColors.darkSurface,
        onSurface: FitNepalColors.darkTextPrimary,
        secondary: FitNepalColors.berryRed,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: FitNepalColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: FitNepalColors.darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FitNepalColors.darkTextPrimary,
        displayColor: FitNepalColors.darkTextPrimary,
      ),
      cardTheme: CardTheme(
        color: FitNepalColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FitNepalSpacing.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FitNepalColors.berryRed,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
