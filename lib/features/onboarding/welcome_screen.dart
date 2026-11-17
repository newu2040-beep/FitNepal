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

  Future<void> _handleGetStarted({bool loadShowcaseData = false}) async {
    setState(() => _isStarting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      if (loadShowcaseData) {
        await db.seedMockupShowcaseData();
      }
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
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final lang = profile?.language ?? 'en';

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
            // Bottom Nepal Himalayan Mountains & Pagoda Temple Artwork
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NepalMountainPagodaArtwork(height: 410),
            ),

            // Foreground Content
            SafeArea(
              child: Column(
                children: [
                  // Optional Units & Goals quick setup button in top right
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                            backgroundColor: Colors.white.withOpacity(0.65),
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

                  // Center FitNepal Heart + Person + Green Leaves Logo
                  const FitNepalHeartLogo(size: 120),
                  const SizedBox(height: 16),

                  // FitNepal Title
                  const Text(
                    'FitNepal',
                    style: TextStyle(
                      color: Color(0xFF6B092B),
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: Eat Healthy • Live Better
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

                  // Bottom CTA Section over the deep crimson temple base
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
                      onPressed: () =>
                          _handleGetStarted(loadShowcaseData: false),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Optional demo data action per Section 12:
                  // "Include demo data only as an optional action; a production first launch should start with an empty personal log."
                  GestureDetector(
                    onTap: _isStarting
                        ? null
                        : () => _handleGetStarted(loadShowcaseData: true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        FitNepalStrings.tr(
                          lang,
                          'Or explore with Mockup Sample Data →',
                          'वा नमूना डाटाको साथ हेर्नुहोस् →',
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Healthy Nepal, Happy Nepal 🇳🇵
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
