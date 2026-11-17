import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const List<({String title, String category, String body, IconData icon, Color accent})>
      _nepaliTips = [
    (
      title: 'Balancing Your Daily Dal Bhat Plate',
      category: 'Nepali Nutrition',
      body:
          'Traditional Dal Bhat is a complete protein source when lentil dal is paired with rice. Try filling half your thali with seasonal saag and tarkari, a quarter with thick dal, and a quarter with steamed bhat or brown rice.',
      icon: Icons.rice_bowl_rounded,
      accent: FitNepalColors.berryRed,
    ),
    (
      title: 'Smart Momo Portions',
      category: 'Mindful Eating',
      body:
          'Steamed chicken or vegetable momos (approx. 260–310 kcal per 8 pieces) have significantly less saturated fat than deep-fried or kothey momos. Pair with fresh tomato-cilantro achar instead of heavy mayo dips.',
      icon: Icons.lunch_dining_rounded,
      accent: FitNepalColors.carbsAccent,
    ),
    (
      title: 'Altitude & Warm Hydration Habits',
      category: 'Hydration',
      body:
          'Start your morning with 250–500 ml of warm water before morning Chiya. Consistent hydration across the day improves energy and prevents mistaking thirst for afternoon snack cravings.',
      icon: Icons.water_drop_rounded,
      accent: FitNepalColors.waterBlue,
    ),
    (
      title: 'High-Protein Local Snacks',
      category: 'Protein Boost',
      body:
          'Roasted Bhatmas Sadeko (soybeans), boiled eggs, Kwati sprout soup, and Juju Dhau / plain curd are affordable, traditional Nepali protein powerhouses that support muscle recovery.',
      icon: Icons.fitness_center_rounded,
      accent: FitNepalColors.proteinAccent,
    ),
    (
      title: 'Reducing Hidden Sugar in Masala Chiya',
      category: 'Daily Habits',
      body:
          'Two cups of sweet milk tea daily can add 150–220 kcal. Flavor your chiya naturally with crushed cardamom (sukumel), fresh ginger (aduwa), cinnamon, and black pepper while halving the sugar.',
      icon: Icons.emoji_food_beverage_rounded,
      accent: FitNepalColors.progressGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 14,
          ),
          children: [
            Text(
              'Healthy Nepal Tips 💡',
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
            const Text(
              'Offline nutrition & hydration guidance tailored for Nepali meals',
              style: TextStyle(
                color: FitNepalColors.mutedPlum,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            for (final tip in _nepaliTips)
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
