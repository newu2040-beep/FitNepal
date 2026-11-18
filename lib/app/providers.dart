import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/date_helpers.dart';
import '../database/app_database.dart';
import '../database/models.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

class LiveProfileNotifier extends StateNotifier<UserProfile> {
  final AppDatabase _db;
  StreamSubscription<UserProfile>? _sub;

  LiveProfileNotifier(this._db)
      : super(
          UserProfile(
            id: 1,
            displayName: 'Rahul Shah',
            createdAt: DateTime.now(),
            language: 'en',
            themeMode: 'light',
            units: 'metric',
            fontFamily: 'system',
          ),
        ) {
    _sub = _db.watchProfile().listen((dbProfile) {
      state = dbProfile;
    });
  }

  Future<void> updateRealtime(UserProfile updated) async {
    state = updated;
    await _db.updateProfile(updated);
  }

  Future<void> toggleLanguage() async {
    final nextLang = state.language == 'en' ? 'ne' : 'en';
    await updateRealtime(state.copyWith(language: nextLang));
  }

  Future<void> setLanguage(String lang) async {
    await updateRealtime(state.copyWith(language: lang == 'ne' ? 'ne' : 'en'));
  }

  Future<void> setThemeMode(String mode) async {
    await updateRealtime(state.copyWith(themeMode: mode));
  }

  Future<void> setColorPalette(String palette) async {
    await updateRealtime(state.copyWith(colorPalette: palette));
  }

  Future<void> setFontFamily(String font) async {
    await updateRealtime(state.copyWith(fontFamily: font));
  }

  Future<void> setFontScale(double scale) async {
    await updateRealtime(state.copyWith(fontScale: scale));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final liveProfileProvider =
    StateNotifierProvider<LiveProfileNotifier, UserProfile>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LiveProfileNotifier(db);
});

final userProfileProvider = Provider<AsyncValue<UserProfile>>((ref) {
  final profile = ref.watch(liveProfileProvider);
  return AsyncValue.data(profile);
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return LocalDateHelpers.startOfDay(DateTime.now());
});

final foodSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedFoodCategoryProvider = StateProvider<String>((ref) => 'All');

final progressTabProvider = StateProvider<String>((ref) => 'Overview');
final progressRangeProvider = StateProvider<String>((ref) => 'This Week');
final selectedBarIndexProvider = StateProvider<int>((ref) => 6);

final activeGoalProvider = StreamProvider<NutritionGoal>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchActiveGoal();
});

final filteredFoodsProvider = StreamProvider<List<FoodItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = ref.watch(foodSearchQueryProvider);
  final category = ref.watch(selectedFoodCategoryProvider);
  return db.watchFoods(searchQuery: query, category: category);
});

final dailyFoodLogsProvider = StreamProvider<List<FoodLogEntry>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.watchFoodLogsForDate(date);
});

final dailyWaterLogsProvider = StreamProvider<List<WaterLogEntry>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final date = ref.watch(selectedDateProvider);
  return db.watchWaterLogsForDate(date);
});

final dailyNutritionSummaryProvider =
    Provider<AsyncValue<DailyNutritionSummary>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final goalAsync = ref.watch(activeGoalProvider);
  final foodLogsAsync = ref.watch(dailyFoodLogsProvider);
  final waterLogsAsync = ref.watch(dailyWaterLogsProvider);

  final goal = goalAsync.valueOrNull ?? NutritionGoal.defaults();
  final foods = foodLogsAsync.valueOrNull ?? const <FoodLogEntry>[];
  final water = waterLogsAsync.valueOrNull ?? const <WaterLogEntry>[];

  return AsyncValue.data(
    DailyNutritionSummary(
      date: date,
      goal: goal,
      foodLogs: foods,
      waterLogs: water,
    ),
  );
});

final remindersProvider = StreamProvider<List<ReminderConfig>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchReminders();
});

final appSettingsProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAppSettings();
});

final profileStatsProvider =
    StreamProvider<({int streakDays, int totalPoints, int goalsCompleted})>(
        (ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchProfileStats();
});

class ProgressAnalyticsData {
  final String rangeLabel;
  final List<DailyBucketSummary> buckets;
  final int averageCalories;
  final int calorieTarget;
  final double averageProteinG;
  final double proteinTargetG;
  final double averageWaterLiters;
  final double waterTargetLiters;
  final int goalMetPercentage;

  const ProgressAnalyticsData({
    required this.rangeLabel,
    required this.buckets,
    required this.averageCalories,
    required this.calorieTarget,
    required this.averageProteinG,
    required this.proteinTargetG,
    required this.averageWaterLiters,
    required this.waterTargetLiters,
    required this.goalMetPercentage,
  });
}

/// 100% real user data analytics provider (all demo overrides removed).
final progressAnalyticsProvider =
    StreamProvider<ProgressAnalyticsData>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final anchorDate = ref.watch(selectedDateProvider);
  final range = ref.watch(progressRangeProvider);
  final goal = ref.watch(activeGoalProvider).valueOrNull ??
      NutritionGoal.defaults();

  late final List<DateTime> dates;
  if (range == 'Today') {
    dates = [LocalDateHelpers.startOfDay(anchorDate)];
  } else if (range == 'This Month') {
    dates = LocalDateHelpers.trailingDays(anchorDate, 7);
  } else {
    dates = LocalDateHelpers.weekDaysMondayToSunday(anchorDate);
  }

  final rangeStart = dates.first;
  final rangeEndExclusive = LocalDateHelpers.endOfDayExclusive(dates.last);

  final controller = StreamController<ProgressAnalyticsData>();

  List<FoodLogEntry> latestFoods = const [];
  List<WaterLogEntry> latestWaters = const [];

  void recompute() {
    final buckets = <DailyBucketSummary>[];
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var i = 0; i < dates.length; i++) {
      final d = dates[i];
      final dayFoods = latestFoods
          .where((f) => LocalDateHelpers.isSameLocalDay(f.loggedAt, d))
          .toList();
      final dayWater = latestWaters
          .where((w) => LocalDateHelpers.isSameLocalDay(w.loggedAt, d))
          .toList();

      final kcal = dayFoods.fold<int>(0, (s, e) => s + e.kcalSnapshot);
      final prot = dayFoods.fold<double>(0.0, (s, e) => s + e.proteinSnapshot);
      final carbs = dayFoods.fold<double>(0.0, (s, e) => s + e.carbsSnapshot);
      final fat = dayFoods.fold<double>(0.0, (s, e) => s + e.fatSnapshot);
      final waterMl = dayWater.fold<int>(0, (s, e) => s + e.amountMl);

      final label = range == 'This Week' && i < weekdayLabels.length
          ? weekdayLabels[i]
          : LocalDateHelpers.formatShortWeekday(d);

      buckets.add(
        DailyBucketSummary(
          date: d,
          shortLabel: label,
          calories: kcal,
          proteinG: prot,
          carbsG: carbs,
          fatG: fat,
          waterMl: waterMl,
        ),
      );
    }

    final nonEmptyDays =
        buckets.where((b) => b.calories > 0 || b.waterMl > 0).toList();
    final divisor = nonEmptyDays.isEmpty ? 1 : nonEmptyDays.length;
    final totalKcal = buckets.fold<int>(0, (s, b) => s + b.calories);
    final totalProt = buckets.fold<double>(0.0, (s, b) => s + b.proteinG);
    final totalWater = buckets.fold<int>(0, (s, b) => s + b.waterMl);

    final avgKcal = (totalKcal / divisor).round();
    final avgProt = totalProt / divisor;
    final avgWaterL = (totalWater / divisor) / 1000.0;

    final pct =
        ((avgKcal / (goal.calorieTarget <= 0 ? 2000 : goal.calorieTarget)) *
                100)
            .round()
            .clamp(0, 100);

    controller.add(
      ProgressAnalyticsData(
        rangeLabel: range,
        buckets: buckets,
        averageCalories: avgKcal,
        calorieTarget: goal.calorieTarget,
        averageProteinG: avgProt,
        proteinTargetG: goal.proteinTargetG,
        averageWaterLiters: avgWaterL,
        waterTargetLiters: goal.waterTargetMl / 1000.0,
        goalMetPercentage: pct,
      ),
    );
  }

  final sub1 = db
      .watchFoodLogsInRange(rangeStart, rangeEndExclusive)
      .listen((foods) {
    latestFoods = foods;
    recompute();
  });
  final sub2 = db
      .watchWaterLogsInRange(rangeStart, rangeEndExclusive)
      .listen((waters) {
    latestWaters = waters;
    recompute();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});
