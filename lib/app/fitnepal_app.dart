import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class FitNepalApp extends ConsumerWidget {
  const FitNepalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(liveProfileProvider);

    final ThemeMode themeMode;
    if (profile.themeMode == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (profile.themeMode == 'system') {
      themeMode = ThemeMode.system;
    } else {
      themeMode = ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'FitNepal',
      debugShowCheckedModeBanner: false,
      locale: Locale(profile.language == 'ne' ? 'ne' : 'en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ne'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FitNepalTheme.buildTheme(
        brightness: Brightness.light,
        paletteId: profile.colorPalette,
        fontId: profile.fontFamily,
      ),
      darkTheme: FitNepalTheme.buildTheme(
        brightness: Brightness.dark,
        paletteId: profile.colorPalette,
        fontId: profile.fontFamily,
      ),
      themeMode: themeMode,
      routerConfig: fitNepalRouter,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(profile.fontScale.clamp(0.85, 1.25)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
