import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_helpers.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';
import '../water_tracking/water_tracking_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state =
          LocalDateHelpers.startOfDay(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final summaryAsync = ref.watch(dailyNutritionSummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final lang = profile?.language ?? 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final summary = summaryAsync.valueOrNull ??
        DailyNutritionSummary(
          date: selectedDate,
          goal: NutritionGoal.defaults(),
          foodLogs: const [],
          waterLogs: const [],
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 14,
          ),
          children: [
            // 1. Greeting Header & Avatar (matches Screen 2 top row)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            FitNepalStrings.tr(lang, 'Namaste!', 'नमस्ते!'),
                            style: TextStyle(
                              color: isDark
                                  ? FitNepalColors.darkTextSecondary
                                  : FitNepalColors.mutedPlum,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _pickDate(context, ref),
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: FitNepalColors.softPinkFill,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 11,
                                    color: FitNepalColors.berryRed,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    LocalDateHelpers.formatFriendlyDate(
                                      selectedDate,
                                    ),
                                    style: const TextStyle(
                                      color: FitNepalColors.berryRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${profile?.displayName ?? 'Rahul Shah'} 👋',
                        style: TextStyle(
                          color: isDark
                              ? FitNepalColors.darkTextPrimary
                              : FitNepalColors.deepPlum,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                UserAvatarWidget(
                  avatarPath: profile?.avatarPath,
                  radius: 25,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Hero Calories Today Berry Red Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE52857),
                    Color(0xFFC1123E),
                    Color(0xFF9E0B30),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: FitNepalColors.berryRed.withOpacity(0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              FitNepalStrings.tr(
                                lang,
                                'Calories Today',
                                'आजको क्यालोरी',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${summary.caloriesConsumed}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              TextSpan(
                                text: ' / ${summary.calorieTarget} kcal',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.isOverCalorieTarget
                              ? 'Over target by ${summary.caloriesOverBy} kcal'
                              : '${summary.remainingCalories} kcal remaining',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCalorieRing(
                    progress: summary.clampedRingProgress,
                    centerLabel: '${summary.caloriePercentageInt}%',
                    size: 80,
                    strokeWidth: 8.5,
                    activeColor: Colors.white,
                    trackColor: Colors.white.withOpacity(0.24),
                    semanticLabel:
                        '${summary.caloriePercentageInt} percent of daily calorie target consumed',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Three Macro Cards Row (Protein 62g, Carbs 84g, Fats 28g)
            Row(
              children: [
                Expanded(
                  child: MacroMetricCard(
                    label: FitNepalStrings.tr(lang, 'Protein', 'प्रोटिन'),
                    consumedG: summary.proteinConsumedG,
                    targetG: summary.goal.proteinTargetG,
                    icon: Icons.restaurant_rounded,
                    backgroundColor: FitNepalColors.proteinCardBg,
                    accentColor: FitNepalColors.proteinAccent,
                    onTap: () => context.go('/progress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MacroMetricCard(
                    label: FitNepalStrings.tr(lang, 'Carbs', 'कार्ब्स'),
                    consumedG: summary.carbsConsumedG,
                    targetG: summary.goal.carbsTargetG,
                    icon: Icons.grain_rounded,
                    backgroundColor: FitNepalColors.carbsCardBg,
                    accentColor: FitNepalColors.carbsAccent,
                    onTap: () => context.go('/progress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MacroMetricCard(
                    label: FitNepalStrings.tr(lang, 'Fats', 'चिल्लो'),
                    consumedG: summary.fatConsumedG,
                    targetG: summary.goal.fatTargetG,
                    icon: Icons.opacity_rounded,
                    backgroundColor: FitNepalColors.fatsCardBg,
                    accentColor: FitNepalColors.fatsAccent,
                    onTap: () => context.go('/progress'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. "You're on track!" Status Card (matches Screen 2 middle card)
            FitNepalCard(
              onTap: () => context.go('/progress'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FitNepalColors.softPinkFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: FitNepalColors.berryRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.isOverCalorieTarget
                              ? FitNepalStrings.tr(
                                  lang,
                                  'Above daily calorie target',
                                  'दैनिक लक्ष्यभन्दा माथि',
                                )
                              : FitNepalStrings.tr(
                                  lang,
                                  "You're on track!",
                                  'तपाईं सही ट्र्याकमा हुनुहुन्छ!',
                                ),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.isOverCalorieTarget
                              ? 'Over by ${summary.caloriesOverBy} kcal — balance with hydration & light activity.'
                              : FitNepalStrings.tr(
                                  lang,
                                  'Keep going for your goal.',
                                  'आफ्नो लक्ष्यको लागि निरन्तरता दिनुहोस्।',
                                ),
                          style: const TextStyle(
                            color: FitNepalColors.mutedPlum,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: FitNepalColors.mutedPlum,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Quick Actions Header & 4 Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(lang, 'Quick Actions', 'द्रुत कार्यहरू'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/add-food'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          FitNepalStrings.tr(lang, 'See all', 'सबै हेर्नुहोस्'),
                          style: const TextStyle(
                            color: FitNepalColors.berryRed,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: FitNepalColors.berryRed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickActionTile(
                  label: FitNepalStrings.tr(lang, 'Add Food', 'खाना थप्नुहोस्'),
                  icon: Icons.restaurant_rounded,
                  bgColor: const Color(0xFFFDE5EC),
                  iconColor: FitNepalColors.berryRed,
                  onTap: () => context.push('/add-food'),
                ),
                _QuickActionTile(
                  label:
                      FitNepalStrings.tr(lang, 'Track Water', 'पानी ट्र्याक'),
                  icon: Icons.water_drop_rounded,
                  bgColor: const Color(0xFFE6F2FF),
                  iconColor: FitNepalColors.waterBlue,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const WaterTrackingBottomSheet(),
                    );
                  },
                ),
                _QuickActionTile(
                  label: FitNepalStrings.tr(lang, 'View Progress', 'प्रगति'),
                  icon: Icons.bar_chart_rounded,
                  bgColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF8E24AA),
                  onTap: () => context.go('/progress'),
                ),
                _QuickActionTile(
                  label: FitNepalStrings.tr(lang, 'Set Goal', 'लक्ष्य'),
                  icon: Icons.emoji_events_rounded,
                  bgColor: const Color(0xFFFFF0DB),
                  iconColor: const Color(0xFFF57C00),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const GoalEditorBottomSheet(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 6. Hydration Summary Strip (Required content per Section 2)
            FitNepalCard(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const WaterTrackingBottomSheet(),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: FitNepalColors.waterBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          FitNepalStrings.tr(
                            lang,
                            'Hydration Today',
                            'आजको पानीको मात्रा',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${summary.waterConsumedMl} / ${summary.goal.waterTargetMl} ml',
                        style: const TextStyle(
                          color: FitNepalColors.waterBlue,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: summary.clampedWaterProgress,
                      minHeight: 7,
                      backgroundColor:
                          FitNepalColors.waterBlue.withOpacity(0.14),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        FitNepalColors.waterBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final ml in const [150, 250, 500])
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text('+$ml ml'),
                          onPressed: () {
                            ref
                                .read(appDatabaseProvider)
                                .logWaterAmount(ml, loggedAt: DateTime.now());
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Today's Logged Meals Section (Required content per Section 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(
                    lang,
                    "Today's Logged Meals",
                    'आजको खाना विवरण',
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (summary.foodLogs.isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(appDatabaseProvider)
                          .seedMockupShowcaseData();
                    },
                    icon: const Icon(
                      Icons.auto_fix_high_rounded,
                      size: 16,
                      color: FitNepalColors.berryRed,
                    ),
                    label: const Text(
                      'Load Sample Day',
                      style: TextStyle(
                        color: FitNepalColors.berryRed,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (summary.foodLogs.isEmpty)
              EmptyStateCard(
                icon: Icons.restaurant_menu_rounded,
                title: 'No meals logged for this day yet',
                message:
                    'Tap "Add Food" to log Dal Bhat, Momo, fruits, or custom dishes — or load the Mockup Sample Day.',
                actionLabel: 'Add First Meal',
                onAction: () => context.push('/add-food'),
              )
            else
              ...summary.foodLogs.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FitNepalCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: FitNepalColors.softPinkFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lunch_dining_rounded,
                            color: FitNepalColors.berryRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.foodNameSnapshot,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${entry.mealType} • ${entry.quantity} × ${entry.servingLabel} • P ${entry.proteinSnapshot.round()}g  C ${entry.carbsSnapshot.round()}g  F ${entry.fatSnapshot.round()}g',
                                style: const TextStyle(
                                  color: FitNepalColors.mutedPlum,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.kcalSnapshot} kcal',
                          style: const TextStyle(
                            color: FitNepalColors.berryRed,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete log entry',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            ref
                                .read(appDatabaseProvider)
                                .deleteFoodLogEntry(entry.id);
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: FitNepalColors.mutedPlum,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: isDark ? FitNepalColors.darkSurface : bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? FitNepalColors.darkTextPrimary
                    : FitNepalColors.deepPlum,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
