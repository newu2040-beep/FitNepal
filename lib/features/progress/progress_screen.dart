import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/date_helpers.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  Future<void> _pickAnchorDate(BuildContext context, WidgetRef ref) async {
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
    final selectedTab = ref.watch(progressTabProvider);
    final selectedRange = ref.watch(progressRangeProvider);
    final selectedBarIndex = ref.watch(selectedBarIndexProvider);
    final analyticsAsync = ref.watch(progressAnalyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 14,
          ),
          children: [
            // 1. Top Header: "Your Progress" + Calendar Icon Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Progress',
                  style: TextStyle(
                    color: isDark
                        ? FitNepalColors.darkTextPrimary
                        : FitNepalColors.deepPlum,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                InkWell(
                  onTap: () => _pickAnchorDate(context, ref),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? FitNepalColors.darkSurface
                          : FitNepalColors.softPinkFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: FitNepalColors.deepPlum,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Segmented Pill Tabs: Overview | Nutrition | Trends
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? FitNepalColors.darkSurface
                    : const Color(0xFFF6EAF0),
                borderRadius: BorderRadius.circular(FitNepalSpacing.pillRadius),
              ),
              child: Row(
                children: [
                  for (final tab in const ['Overview', 'Nutrition', 'Trends'])
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(progressTabProvider.notifier).state = tab,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedTab == tab
                                ? FitNepalColors.berryRed
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              FitNepalSpacing.pillRadius,
                            ),
                            boxShadow: selectedTab == tab
                                ? [
                                    BoxShadow(
                                      color: FitNepalColors.berryRed
                                          .withOpacity(0.24),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: selectedTab == tab
                                  ? Colors.white
                                  : (isDark
                                      ? FitNepalColors.darkTextSecondary
                                      : FitNepalColors.deepPlum),
                              fontSize: 13.5,
                              fontWeight: selectedTab == tab
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            analyticsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FitNepalColors.berryRed,
                  ),
                ),
              ),
              error: (err, _) => EmptyStateCard(
                icon: Icons.bar_chart_rounded,
                title: 'Unable to load progress data',
                message: err.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(progressAnalyticsProvider),
              ),
              data: (data) {
                final safeBarIdx = data.buckets.isEmpty
                    ? 0
                    : selectedBarIndex.clamp(0, data.buckets.length - 1);
                final activeBucket = data.buckets.isEmpty
                    ? null
                    : data.buckets[safeBarIdx];

                if (selectedTab == 'Nutrition') {
                  return _NutritionTabContent(data: data);
                } else if (selectedTab == 'Trends') {
                  return _TrendsTabContent(data: data);
                }

                // Default 'Overview' tab matching Screen 4 of the mockup
                return Column(
                  children: [
                    // 3. Goal Ring + Calories / Protein / Water Legend Card
                    FitNepalCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          AnimatedCalorieRing(
                            progress: (data.goalMetPercentage / 100.0)
                                .clamp(0.0, 1.0),
                            centerLabel: '${data.goalMetPercentage}%',
                            subLabel: 'Goal Met',
                            size: 126,
                            strokeWidth: 13,
                            activeColor: FitNepalColors.berryRed,
                            trackColor: const Color(0xFFF9DCE5),
                            centerTextStyle: TextStyle(
                              color: isDark
                                  ? FitNepalColors.darkTextPrimary
                                  : FitNepalColors.deepPlum,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            subTextStyle: const TextStyle(
                              color: FitNepalColors.mutedPlum,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            semanticLabel:
                                '${data.goalMetPercentage} percent of goal met',
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendMetricItem(
                                  dotColor: FitNepalColors.berryRed,
                                  label: 'Calories',
                                  valueText:
                                      '${LocalDateHelpers.formatNumber(data.averageCalories)} / ${LocalDateHelpers.formatNumber(data.calorieTarget)}',
                                ),
                                const SizedBox(height: 14),
                                _LegendMetricItem(
                                  dotColor: FitNepalColors.progressGreen,
                                  label: 'Protein',
                                  valueText:
                                      '${data.averageProteinG.round()} / ${data.proteinTargetG.round()}g',
                                ),
                                const SizedBox(height: 14),
                                _LegendMetricItem(
                                  dotColor: FitNepalColors.waterBlue,
                                  label: 'Water',
                                  valueText:
                                      '${data.averageWaterLiters.toStringAsFixed(1)} / ${data.waterTargetLiters.toStringAsFixed(1)}L',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Bar Chart Card ("This Week v" + Mon..Sun bars + 1,920 kcal tooltip)
                    FitNepalCard(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PopupMenuButton<String>(
                                initialValue: selectedRange,
                                onSelected: (val) {
                                  ref
                                      .read(progressRangeProvider.notifier)
                                      .state = val;
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'Today',
                                    child: Text('Today'),
                                  ),
                                  PopupMenuItem(
                                    value: 'This Week',
                                    child: Text('This Week'),
                                  ),
                                  PopupMenuItem(
                                    value: 'This Month',
                                    child: Text('This Month'),
                                  ),
                                ],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedRange,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),

                              // Dark plum floating pill showing selected bar kcal
                              if (activeBucket != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FitNepalColors.deepPlum,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '${LocalDateHelpers.formatNumber(activeBucket.calories)} kcal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            height: 175,
                            child: BarChart(
                              BarChartData(
                                maxY: math.max(
                                  2400.0,
                                  data.buckets.fold<double>(
                                    2000.0,
                                    (m, b) => math.max(m, b.calories * 1.2),
                                  ),
                                ),
                                minY: 0,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1000,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: FitNepalColors.roseBorder
                                        .withOpacity(0.55),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchCallback: (event, response) {
                                    if (response?.spot != null &&
                                        event.isInterestedForInteractions) {
                                      ref
                                          .read(selectedBarIndexProvider
                                              .notifier)
                                          .state = response!
                                              .spot!.touchedBarGroupIndex;
                                    }
                                  },
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) =>
                                        FitNepalColors.deepPlum,
                                    tooltipRoundedRadius: 12,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final b = data.buckets[groupIndex];
                                      return BarTooltipItem(
                                        '${LocalDateHelpers.formatNumber(b.calories)} kcal',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      interval: 1000,
                                      getTitlesWidget: (val, _) {
                                        final k = (val / 1000).round();
                                        return Text(
                                          '$k',
                                          style: const TextStyle(
                                            color: FitNepalColors.softPlum,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      getTitlesWidget: (val, _) {
                                        final idx = val.toInt();
                                        if (idx < 0 ||
                                            idx >= data.buckets.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final isSelected = idx == safeBarIdx;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            data.buckets[idx].shortLabel,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? FitNepalColors.berryRed
                                                  : FitNepalColors.mutedPlum,
                                              fontSize: 11.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(
                                  data.buckets.length,
                                  (idx) {
                                    final b = data.buckets[idx];
                                    final isSelected = idx == safeBarIdx;
                                    return BarChartGroupData(
                                      x: idx,
                                      barRods: [
                                        BarChartRodData(
                                          toY: math.max(
                                            80.0,
                                            b.calories.toDouble(),
                                          ),
                                          width: 16,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                            bottom: Radius.circular(4),
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: isSelected
                                                ? const [
                                                    FitNepalColors.berryRed,
                                                    Color(0xFFF58AA5),
                                                  ]
                                                : const [
                                                    Color(0xFFEC5B7E),
                                                    Color(0xFFFAD3DF),
                                                  ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Insights Card (matches Screen 4 bottom pink card)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? FitNepalColors.darkSurface
                            : const Color(0xFFFDE6EE),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: FitNepalColors.berryRed.withOpacity(0.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: Color(0xFFF59E0B),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Insights',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "You're ${data.goalMetPercentage}% towards your weekly goal.",
                                  style: const TextStyle(
                                    color: FitNepalColors.mutedPlum,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendMetricItem extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String valueText;

  const _LegendMetricItem({
    required this.dotColor,
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: FitNepalColors.mutedPlum,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  color: isDark
                      ? FitNepalColors.darkTextPrimary
                      : FitNepalColors.deepPlum,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionTabContent extends StatelessWidget {
  final ProgressAnalyticsData data;

  const _NutritionTabContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalProt =
        data.buckets.fold<double>(0.0, (s, b) => s + b.proteinG);
    final totalCarbs =
        data.buckets.fold<double>(0.0, (s, b) => s + b.carbsG);
    final totalFat = data.buckets.fold<double>(0.0, (s, b) => s + b.fatG);
    final divisor = math.max(1, data.buckets.length);

    return Column(
      children: [
        FitNepalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Average Daily Macro Split',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _MacroProgressRow(
                label: 'Protein',
                currentG: totalProt / divisor,
                targetG: data.proteinTargetG,
                color: FitNepalColors.proteinAccent,
              ),
              const SizedBox(height: 12),
              _MacroProgressRow(
                label: 'Carbohydrates',
                currentG: totalCarbs / divisor,
                targetG: 220,
                color: FitNepalColors.carbsAccent,
              ),
              const SizedBox(height: 12),
              _MacroProgressRow(
                label: 'Healthy Fats',
                currentG: totalFat / divisor,
                targetG: 65,
                color: FitNepalColors.fatsAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final double currentG;
  final double targetG;
  final Color color;

  const _MacroProgressRow({
    required this.label,
    required this.currentG,
    required this.targetG,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (currentG / math.max(1.0, targetG)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '${currentG.round()}g / ${targetG.round()}g',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _TrendsTabContent extends StatelessWidget {
  final ProgressAnalyticsData data;

  const _TrendsTabContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final b in data.buckets.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FitNepalCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${b.shortLabel} • ${LocalDateHelpers.dateKey(b.date)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Protein ${b.proteinG.round()}g • Water ${b.waterMl} ml',
                        style: const TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${LocalDateHelpers.formatNumber(b.calories)} kcal',
                    style: const TextStyle(
                      color: FitNepalColors.berryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
