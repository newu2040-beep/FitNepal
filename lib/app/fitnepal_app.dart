import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class FitNepalApp extends ConsumerWidget {
  const FitNepalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final modeStr = profile?.themeMode ?? 'light';

    final ThemeMode themeMode;
    if (modeStr == 'dark') {
      themeMode = ThemeMode.dark;
    } else if (modeStr == 'system') {
      themeMode = ThemeMode.system;
    } else {
      themeMode = ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'FitNepal',
      debugShowCheckedModeBanner: false,
      theme: FitNepalTheme.lightTheme,
      darkTheme: FitNepalTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: fitNepalRouter,
    );
  }
}
