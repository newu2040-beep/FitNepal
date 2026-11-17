import 'package:fitnepal/core/date_helpers.dart';
import 'package:fitnepal/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Section 4 Nutrition & Hydration Calculations', () {
    test('Mockup day totals: 720 / 2000 kcal = 36% and 1280 remaining', () {
      final goal = NutritionGoal.defaults(); // 2000 kcal, 2500 ml
      final now = DateTime(2026, 11, 17, 12, 0);

      final logs = [
        FoodLogEntry(
          id: 1,
          foodId: 3,
          foodNameSnapshot: 'Dal Bhat',
          loggedAt: now,
          mealType: 'Lunch',
          quantity: 1.0,
          servingLabel: 'plate',
          kcalSnapshot: 350,
          proteinSnapshot: 26.0,
          carbsSnapshot: 52.0,
          fatSnapshot: 9.0,
        ),
        FoodLogEntry(
          id: 2,
          foodId: 4,
          foodNameSnapshot: 'Chicken Curry',
          loggedAt: now,
          mealType: 'Lunch',
          quantity: 1.0,
          servingLabel: '100g',
          kcalSnapshot: 220,
          proteinSnapshot: 31.0,
          carbsSnapshot: 8.0,
          fatSnapshot: 14.0,
        ),
        FoodLogEntry(
          id: 3,
          foodId: 2,
          foodNameSnapshot: 'Banana & Oats',
          loggedAt: now,
          mealType: 'Breakfast',
          quantity: 1.0,
          servingLabel: 'bowl',
          kcalSnapshot: 150,
          proteinSnapshot: 5.0,
          carbsSnapshot: 24.0,
          fatSnapshot: 5.0,
        ),
      ];

      final waterLogs = [
        WaterLogEntry(id: 1, loggedAt: now, amountMl: 1000),
        WaterLogEntry(id: 2, loggedAt: now, amountMl: 800),
      ];

      final summary = DailyNutritionSummary(
        date: now,
        goal: goal,
        foodLogs: logs,
        waterLogs: waterLogs,
      );

      expect(summary.caloriesConsumed, 720);
      expect(summary.remainingCalories, 1280);
      expect(summary.isOverCalorieTarget, isFalse);
      expect(summary.caloriePercentageInt, 36);
      expect(summary.clampedRingProgress, closeTo(0.36, 0.001));
      expect(summary.proteinConsumedG, 62.0);
      expect(summary.carbsConsumedG, 84.0);
      expect(summary.fatConsumedG, 28.0);
      expect(summary.waterConsumedMl, 1800);
      expect(summary.waterConsumedLiters, closeTo(1.8, 0.01));
    });

    test('Over-goal clamping: ring clamps at 1.0 while true percentage exceeds 100%', () {
      final goal = NutritionGoal.defaults(); // 2000 kcal
      final now = DateTime(2026, 11, 17, 19, 0);

      final summary = DailyNutritionSummary(
        date: now,
        goal: goal,
        foodLogs: [
          FoodLogEntry(
            id: 1,
            foodNameSnapshot: 'Festive Feast',
            loggedAt: now,
            mealType: 'Dinner',
            quantity: 1.0,
            servingLabel: 'meal',
            kcalSnapshot: 2500,
            proteinSnapshot: 110,
            carbsSnapshot: 280,
            fatSnapshot: 90,
          ),
        ],
        waterLogs: const [],
      );

      expect(summary.isOverCalorieTarget, isTrue);
      expect(summary.remainingCalories, 0);
      expect(summary.caloriesOverBy, 500);
      expect(summary.caloriePercentageInt, 125);
      expect(summary.clampedRingProgress, 1.0);
    });

    test('FoodItem quantity scaling scales kcal and macros accurately', () {
      const dalBhat = FoodItem(
        id: 3,
        name: 'Dal Bhat',
        normalizedName: 'dal bhat',
        category: 'Meals',
        servingLabel: 'plate',
        servingAmount: 1.0,
        kcal: 350,
        proteinG: 12.0,
        carbsG: 62.0,
        fatG: 6.0,
      );

      expect(dalBhat.scaledKcal(1.5), 525);
      expect(dalBhat.scaledProtein(1.5), 18.0);
      expect(dalBhat.scaledCarbs(1.5), 93.0);
      expect(dalBhat.scaledFat(1.5), 9.0);
    });

    test('LocalDateHelpers computes exact local midnight calendar boundaries', () {
      final sample = DateTime(2026, 11, 17, 23, 45, 12);
      final start = LocalDateHelpers.startOfDay(sample);
      final end = LocalDateHelpers.endOfDayExclusive(sample);

      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(end.day, 18);
      expect(end.hour, 0);
      expect(LocalDateHelpers.dateKey(sample), '2026-11-17');

      final week = LocalDateHelpers.weekDaysMondayToSunday(sample);
      expect(week.length, 7);
      expect(week.first.weekday, DateTime.monday);
      expect(week.last.weekday, DateTime.sunday);
    });
  });
}
