import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

class FitNepalPaletteTokens {
  final String id;
  final String nameEn;
  final String nameNe;
  final Color primary;
  final Color secondary;
  final Color lightCanvas;
  final Color darkCanvas;
  final Color darkSurface;

  const FitNepalPaletteTokens({
    required this.id,
    required this.nameEn,
    required this.nameNe,
    required this.primary,
    required this.secondary,
    required this.lightCanvas,
    required this.darkCanvas,
    required this.darkSurface,
  });
}

class FitNepalTheme {
  FitNepalTheme._();

  static const List<FitNepalPaletteTokens> palettes = [
    FitNepalPaletteTokens(
      id: 'berry',
      nameEn: 'FitNepal Berry (Signature)',
      nameNe: 'फिटनेपाल बेरी (मुख्य)',
      primary: Color(0xFFD91F4D),
      secondary: Color(0xFFE93A68),
      lightCanvas: Color(0xFFFFF7FA),
      darkCanvas: Color(0xFF1A0F16),
      darkSurface: Color(0xFF271722),
    ),
    FitNepalPaletteTokens(
      id: 'teal',
      nameEn: 'Himalayan Emerald',
      nameNe: 'हिमालयन पन्ना (हरियो)',
      primary: Color(0xFF0D9488),
      secondary: Color(0xFF14B8A6),
      lightCanvas: Color(0xFFF3FBF9),
      darkCanvas: Color(0xFF0C1917),
      darkSurface: Color(0xFF152825),
    ),
    FitNepalPaletteTokens(
      id: 'rhododendron',
      nameEn: 'Royal Rhododendron (Lali Gurans)',
      nameNe: 'लालीगुराँस बैजनी',
      primary: Color(0xFF9333EA),
      secondary: Color(0xFFA855F7),
      lightCanvas: Color(0xFFFAF5FF),
      darkCanvas: Color(0xFF160E21),
      darkSurface: Color(0xFF231733),
    ),
    FitNepalPaletteTokens(
      id: 'cobalt',
      nameEn: 'Everest Alpine Blue',
      nameNe: 'सगरमाथा निलो',
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF3B82F6),
      lightCanvas: Color(0xFFF4F8FF),
      darkCanvas: Color(0xFF0E1526),
      darkSurface: Color(0xFF18223A),
    ),
    FitNepalPaletteTokens(
      id: 'sunset',
      nameEn: 'Mustang Terracotta Sunset',
      nameNe: 'मुस्ताङ सूर्यास्त',
      primary: Color(0xFFEA580C),
      secondary: Color(0xFFF97316),
      lightCanvas: Color(0xFFFFF8F3),
      darkCanvas: Color(0xFF1E120C),
      darkSurface: Color(0xFF2D1B12),
    ),
    FitNepalPaletteTokens(
      id: 'gold',
      nameEn: 'Kathmandu Temple Gold',
      nameNe: 'काठमाडौं मन्दिर सुनौलो',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFF59E0B),
      lightCanvas: Color(0xFFFFFBF2),
      darkCanvas: Color(0xFF1C160B),
      darkSurface: Color(0xFF2B2211),
    ),
    FitNepalPaletteTokens(
      id: 'forest',
      nameEn: 'Chitwan Pine Forest',
      nameNe: 'चितवन वन हरियो',
      primary: Color(0xFF15803D),
      secondary: Color(0xFF22C55E),
      lightCanvas: Color(0xFFF3FAF5),
      darkCanvas: Color(0xFF0C1A11),
      darkSurface: Color(0xFF14291C),
    ),
    FitNepalPaletteTokens(
      id: 'indigo',
      nameEn: 'Pokhara Midnight Lake',
      nameNe: 'पोखरा फेवा इन्डिगो',
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF6366F1),
      lightCanvas: Color(0xFFF5F6FF),
      darkCanvas: Color(0xFF101124),
      darkSurface: Color(0xFF1A1C38),
    ),
    FitNepalPaletteTokens(
      id: 'crimson',
      nameEn: 'Gorkha Velvet Crimson',
      nameNe: 'गोर्खा मखमली सिम्रिक',
      primary: Color(0xFFBE123C),
      secondary: Color(0xFFF43F5E),
      lightCanvas: Color(0xFFFFF5F7),
      darkCanvas: Color(0xFF1C0D12),
      darkSurface: Color(0xFF2B141C),
    ),
    FitNepalPaletteTokens(
      id: 'slate',
      nameEn: 'Annapurna Monochrome Slate',
      nameNe: 'अन्नपूर्ण स्लेट',
      primary: Color(0xFF334155),
      secondary: Color(0xFF475569),
      lightCanvas: Color(0xFFF8FAFC),
      darkCanvas: Color(0xFF0F172A),
      darkSurface: Color(0xFF1E293B),
    ),
  ];

  static const List<({String id, String nameEn, String nameNe, String? family, double letterSpacing})>
      fonts = [
    (
      id: 'system',
      nameEn: 'System Default Font',
      nameNe: 'सिस्टम डिफल्ट फन्ट',
      family: null,
      letterSpacing: 0.0,
    ),
    (
      id: 'sans',
      nameEn: 'Modern Geometric Sans',
      nameNe: 'आधुनिक सान्स',
      family: 'sans-serif',
      letterSpacing: 0.0,
    ),
    (
      id: 'rounded',
      nameEn: 'Soft Rounded UI',
      nameNe: 'गोलो मैत्री अक्षर',
      family: 'sans-serif-medium',
      letterSpacing: 0.35,
    ),
    (
      id: 'serif',
      nameEn: 'Classic Editorial Serif',
      nameNe: 'क्लासिक सेरिफ',
      family: 'serif',
      letterSpacing: 0.1,
    ),
    (
      id: 'mono',
      nameEn: 'Technical Monospace',
      nameNe: 'प्राविधिक मोनोस्पेस',
      family: 'monospace',
      letterSpacing: -0.2,
    ),
    (
      id: 'condensed',
      nameEn: 'Athletic Condensed',
      nameNe: 'एथलेटिक कम्प्याक्ट',
      family: 'sans-serif-condensed',
      letterSpacing: 0.15,
    ),
    (
      id: 'light',
      nameEn: 'Airy Light Minimal',
      nameNe: 'हल्का मिनिमल',
      family: 'sans-serif-light',
      letterSpacing: 0.25,
    ),
  ];

  static FitNepalPaletteTokens resolvePalette(String id) {
    return palettes.firstWhere(
      (p) => p.id == id,
      orElse: () => palettes.first,
    );
  }

  static ({String id, String nameEn, String nameNe, String? family, double letterSpacing})
      resolveFont(String id) {
    return fonts.firstWhere(
      (f) => f.id == id,
      orElse: () => fonts.first,
    );
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    required String paletteId,
    required String fontId,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = resolvePalette(paletteId);
    final fontSpec = resolveFont(fontId);

    final bgCanvas = isDark ? palette.darkCanvas : palette.lightCanvas;
    final surfaceColor =
        isDark ? palette.darkSurface : FitNepalColors.surfaceWhite;
    final textPrimary =
        isDark ? FitNepalColors.darkTextPrimary : FitNepalColors.deepPlum;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontSpec.family,
      scaffoldBackgroundColor: bgCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        secondary: palette.secondary,
      ),
    );

    final adjustedTextTheme = base.textTheme
        .apply(
          fontFamily: fontSpec.family,
          bodyColor: textPrimary,
          displayColor: textPrimary,
        )
        .copyWith(
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            letterSpacing: fontSpec.letterSpacing,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            letterSpacing: fontSpec.letterSpacing,
          ),
        );

    return base.copyWith(
      textTheme: adjustedTextTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: fontSpec.family,
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: fontSpec.letterSpacing,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FitNepalSpacing.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.primary,
        contentTextStyle: TextStyle(
          fontFamily: fontSpec.family,
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
