import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';

class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final tips = [
      (
        title: FitNepalStrings.tr(
          lang,
          'Balancing Your Daily Dal Bhat Plate',
          'दैनिक दाल भात थालीको सन्तुलन',
        ),
        category: FitNepalStrings.tr(
          lang,
          'Nepali Nutrition',
          'नेपाली पोषण',
        ),
        body: FitNepalStrings.tr(
          lang,
          'Traditional Dal Bhat is a complete protein source when lentil dal is paired with rice. Fill half your thali with seasonal saag and tarkari, a quarter with thick dal, and a quarter with steamed bhat.',
          'दाल र भात सँगै खाँदा पूर्ण प्रोटिन प्राप्त हुन्छ। आफ्नो थालीको आधा भाग हरियो साग र तरकारी, चौथाइ भाग बाक्लो दाल र चौथाइ भाग भात राख्नुहोस्।',
        ),
        icon: Icons.rice_bowl_rounded,
        accent: primaryColor,
      ),
      (
        title: FitNepalStrings.tr(
          lang,
          'Smart Momo Portions',
          'मःम खाने स्मार्ट तरिका',
        ),
        category: FitNepalStrings.tr(
          lang,
          'Mindful Eating',
          'सन्तुलित आहार',
        ),
        body: FitNepalStrings.tr(
          lang,
          'Steamed chicken or vegetable momos (approx. 260–310 kcal per 8 pieces) have significantly less saturated fat than deep-fried momos. Pair with fresh tomato achar.',
          'स्टिम गरिएको चिकेन वा भेज मःममा तारेको मःमभन्दा निकै कम चिल्लो हुन्छ। ताजा गोलभेडाको अचारसँग खानुहोस्।',
        ),
        icon: Icons.lunch_dining_rounded,
        accent: FitNepalColors.carbsAccent,
      ),
      (
        title: FitNepalStrings.tr(
          lang,
          'Warm Morning Hydration',
          'बिहान मनतातो पानीको बानी',
        ),
        category: FitNepalStrings.tr(lang, 'Hydration', 'पानी र स्वास्थ्य'),
        body: FitNepalStrings.tr(
          lang,
          'Start your morning with 250–500 ml of warm water before morning Chiya. Consistent hydration across the day improves energy and digestion.',
          'बिहान चिया पिउनुअघि २५०–५०० मिलि मनतातो पानी पिउनुहोस्। दिनभरि पर्याप्त पानी पिउँदा ऊर्जा र पाचन राम्रो हुन्छ।',
        ),
        icon: Icons.water_drop_rounded,
        accent: FitNepalColors.waterBlue,
      ),
      (
        title: FitNepalStrings.tr(
          lang,
          'High-Protein Local Snacks',
          'उच्च प्रोटिनयुक्त नेपाली खाजा',
        ),
        category: FitNepalStrings.tr(lang, 'Protein Boost', 'प्रोटिन स्रोत'),
        body: FitNepalStrings.tr(
          lang,
          'Roasted Bhatmas Sadeko (soybeans), boiled eggs, Kwati sprout soup, and Juju Dhau / plain curd are affordable, traditional Nepali protein powerhouses.',
          'भटमास साँधेको, उसिनेको अण्डा, क्वाँटीको झोल र दही/जुजु धौ उत्कृष्ट स्थानीय प्रोटिनका स्रोत हुन्।',
        ),
        icon: Icons.fitness_center_rounded,
        accent: FitNepalColors.proteinAccent,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 14,
          ),
          children: [
            Text(
              FitNepalStrings.tr(
                lang,
                'Healthy Nepal Tips 💡',
                'स्वस्थ नेपाल सुझावहरू 💡',
              ),
              style: TextStyle(
                color: isDark
                    ? FitNepalColors.darkTextPrimary
                    : FitNepalColors.deepPlum,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              FitNepalStrings.tr(
                lang,
                'Offline nutrition & hydration guidance tailored for Nepali meals',
                'नेपाली खाना र जीवनशैलीका लागि अफलाइन पोषण मार्गदर्शन',
              ),
              style: const TextStyle(
                color: FitNepalColors.mutedPlum,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FitNepalCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: tip.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(tip.icon, color: tip.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tip.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                tip.category,
                                style: TextStyle(
                                  color: tip.accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tip.title,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip.body,
                              style: const TextStyle(
                                color: FitNepalColors.mutedPlum,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
