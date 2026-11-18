import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../water_tracking/water_tracking_sheet.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isStarting = false;

  Future<void> _handleGetStarted() async {
    setState(() => _isStarting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      await db.setAppSetting('onboarding_completed', 'true');
      if (mounted) {
        context.go('/home');
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDE8EF),
              Color(0xFFFAD3E0),
              Color(0xFFF3A7BE),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: NepalMountainPagodaArtwork(height: 410),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => ref
                              .read(liveProfileProvider.notifier)
                              .toggleLanguage(),
                          icon: const Icon(
                            Icons.translate_rounded,
                            size: 16,
                            color: FitNepalColors.deepPlum,
                          ),
                          label: Text(
                            lang == 'ne' ? 'नेपाली • EN' : 'English • ने',
                            style: const TextStyle(
                              color: FitNepalColors.deepPlum,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.72),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const GoalEditorBottomSheet(),
                            );
                          },
                          icon: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: FitNepalColors.deepPlum,
                          ),
                          label: Text(
                            FitNepalStrings.tr(
                              lang,
                              'Units & Goals',
                              'एकाइ र लक्ष्य',
                            ),
                            style: const TextStyle(
                              color: FitNepalColors.deepPlum,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.72),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  const FitNepalHeartLogo(size: 126),
                  const SizedBox(height: 16),

                  const Text(
                    'FitNepal',
                    style: TextStyle(
                      color: Color(0xFF6B092B),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B092B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'v5.0 ELITE • OFFLINE EDITION',
                      style: TextStyle(
                        color: Color(0xFF6B092B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    FitNepalStrings.tr(
                      lang,
                      'Eat Healthy  •  Live Better',
                      'स्वस्थ खानुहोस्  •  राम्रो बाँच्नुहोस्',
                    ),
                    style: const TextStyle(
                      color: FitNepalColors.deepPlum,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const Spacer(flex: 5),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: PrimaryPillButton(
                      label: FitNepalStrings.tr(
                        lang,
                        'Get Started',
                        'सुरु गर्नुहोस्',
                      ),
                      trailingIcon: Icons.arrow_forward_rounded,
                      isLoading: _isStarting,
                      height: 56,
                      onPressed: _handleGetStarted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FitNepalStrings.tr(
                          lang,
                          'Healthy Nepal, Happy Nepal ',
                          'स्वस्थ नेपाल, सुखी नेपाल ',
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text('🇳🇵', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
