import 'package:flutter/material.dart';

class FitNepalColors {
  FitNepalColors._();

  // Primary Palette (Section 3 Visual design system)
  static const Color canvasBlush = Color(0xFFFFF7FA);
  static const Color canvasSecondary = Color(0xFFFDF0F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color berryRed = Color(0xFFD91F4D);
  static const Color berryDark = Color(0xFFB3123B);
  static const Color berryLight = Color(0xFFE93A68);
  static const Color deepPlum = Color(0xFF32152A);
  static const Color mutedPlum = Color(0xFF73566A);
  static const Color softPlum = Color(0xFFA2899A);
  static const Color roseBorder = Color(0xFFF3DCE5);
  static const Color softPinkFill = Color(0xFFFDECEF);
  static const Color chipUnselectedFill = Color(0xFFF6E9EE);

  // Macro & Metric Accent Colors (matching Home & Progress screen mockup)
  static const Color proteinCardBg = Color(0xFFEAF4FF);
  static const Color proteinAccent = Color(0xFF2B80FF);

  static const Color carbsCardBg = Color(0xFFFFF1E6);
  static const Color carbsAccent = Color(0xFFFF8A2B);

  static const Color fatsCardBg = Color(0xFFEEF0FF);
  static const Color fatsAccent = Color(0xFF4E73F8);

  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color waterBlue = Color(0xFF2196F3);
  static const Color streakAmber = Color(0xFFFF9800);
  static const Color leafGreen = Color(0xFF3BB54A);

  // Dark Mode Palette
  static const Color darkCanvas = Color(0xFF1A0F16);
  static const Color darkSurface = Color(0xFF271722);
  static const Color darkBorder = Color(0xFF3E2636);
  static const Color darkTextPrimary = Color(0xFFFAF0F5);
  static const Color darkTextSecondary = Color(0xFFCBB4C3);
}

class FitNepalSpacing {
  FitNepalSpacing._();

  static const double baseGrid = 8.0;
  static const double screenHorizontal = 20.0;
  static const double sectionGap = 20.0;
  static const double cardPadding = 16.0;
  static const double cardRadius = 24.0;
  static const double pillRadius = 999.0;
}

class FitNepalCategories {
  FitNepalCategories._();

  static const List<String> all = [
    'All',
    'Fruits',
    'Meals',
    'Snacks',
    'Drinks',
    'Dairy',
    'Custom',
  ];

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];
}

class FitNepalStrings {
  FitNepalStrings._();

  static String tr(String lang, String en, String ne) {
    return lang == 'ne' ? ne : en;
  }
}
