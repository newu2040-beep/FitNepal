import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/date_helpers.dart';
import 'models.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Goals,
    Foods,
    FoodLogs,
    WaterLogs,
    ReminderSettings,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fitnepal_local_db');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          await _seedInitialData();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Safe, non-destructive schema migration per Section 5:
          // "Use migrations for every schema change. Never delete the database as a shortcut during updates."
          if (from < 2) {
            await _createIndexes();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await _createIndexes();
          await _ensureSeeded();
        },
      );

  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS profile (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        display_name TEXT NOT NULL DEFAULT 'Rahul Shah',
        avatar_path TEXT NULL,
        created_at INTEGER NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        theme_mode TEXT NOT NULL DEFAULT 'light',
        units TEXT NOT NULL DEFAULT 'metric',
        tagline TEXT NOT NULL DEFAULT 'Healthy Mind, Healthy Life ❤️'
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        effective_from INTEGER NOT NULL,
        calorie_target INTEGER NOT NULL DEFAULT 2000,
        protein_target_g REAL NOT NULL DEFAULT 120.0,
        carbs_target_g REAL NOT NULL DEFAULT 220.0,
        fat_target_g REAL NOT NULL DEFAULT 65.0,
        water_target_ml INTEGER NOT NULL DEFAULT 2500
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS foods (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        category TEXT NOT NULL,
        serving_label TEXT NOT NULL,
        serving_amount REAL NOT NULL DEFAULT 100.0,
        kcal INTEGER NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        image_asset_path TEXT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        estimate_note TEXT NOT NULL DEFAULT 'Estimated nutritional value'
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS food_logs (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NULL REFERENCES foods(id) ON DELETE SET NULL,
        food_name_snapshot TEXT NOT NULL,
        logged_at INTEGER NOT NULL,
        meal_type TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1.0,
        serving_label TEXT NOT NULL,
        kcal_snapshot INTEGER NOT NULL,
        protein_snapshot REAL NOT NULL,
        carbs_snapshot REAL NOT NULL,
        fat_snapshot REAL NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS water_logs (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        logged_at INTEGER NOT NULL,
        amount_ml INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS reminder_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        enabled INTEGER NOT NULL DEFAULT 1,
        days_of_week TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        start_minute INTEGER NOT NULL DEFAULT 480,
        end_minute INTEGER NOT NULL DEFAULT 1260,
        interval_minutes INTEGER NOT NULL DEFAULT 120,
        reminder_type TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_normalized_name ON foods (normalized_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_foods_category ON foods (category)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_food_logs_logged_at ON food_logs (logged_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_water_logs_logged_at ON water_logs (logged_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_goals_effective_from ON goals (effective_from)',
    );
  }

  Future<void> _seedInitialData() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await customInsert(
      'INSERT INTO profile (id, display_name, avatar_path, created_at, language, theme_mode, units, tagline) '
      'VALUES (1, ?, NULL, ?, ?, ?, ?, ?)',
      variables: [
        const Variable<String>('Rahul Shah'),
        Variable<int>(nowMs),
        const Variable<String>('en'),
        const Variable<String>('light'),
        const Variable<String>('metric'),
        const Variable<String>('Healthy Mind, Healthy Life ❤️'),
      ],
      updates: {profiles},
    );

    await customInsert(
      'INSERT INTO goals (id, effective_from, calorie_target, protein_target_g, carbs_target_g, fat_target_g, water_target_ml) '
      'VALUES (1, ?, 2000, 120.0, 220.0, 65.0, 2500)',
      variables: [
        Variable<int>(DateTime(2025, 1, 1).millisecondsSinceEpoch),
      ],
      updates: {goals},
    );

    // Seed default meal and water reminders (matching badge "2" in mockup)
    await customInsert(
      'INSERT INTO reminder_settings (enabled, days_of_week, start_minute, end_minute, interval_minutes, reminder_type) '
      'VALUES (1, ?, 480, 1260, 120, ?)',
      variables: [
        const Variable<String>('1,2,3,4,5,6,7'),
        const Variable<String>('water'),
      ],
      updates: {reminderSettings},
    );
    await customInsert(
      'INSERT INTO reminder_settings (enabled, days_of_week, start_minute, end_minute, interval_minutes, reminder_type) '
      'VALUES (1, ?, 480, 1200, 300, ?)',
      variables: [
        const Variable<String>('1,2,3,4,5,6,7'),
        const Variable<String>('meal'),
      ],
      updates: {reminderSettings},
    );

    await _seedStarterFoods();
  }

  Future<void> _ensureSeeded() async {
    final profileCountRow = await customSelect(
      'SELECT COUNT(*) AS cnt FROM profile',
    ).getSingle();
    if ((profileCountRow.data['cnt'] as int? ?? 0) == 0) {
      await _seedInitialData();
      return;
    }

    final foodCountRow = await customSelect(
      'SELECT COUNT(*) AS cnt FROM foods',
    ).getSingle();
    if ((foodCountRow.data['cnt'] as int? ?? 0) == 0) {
      await _seedStarterFoods();
    }
  }

  Future<void> _seedStarterFoods() async {
    List<Map<String, dynamic>> rawFoods = _fallbackStarterFoods;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/seed/starter_foods.json');
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      rawFoods = decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      // Fallback for unit tests where rootBundle may not be initialized
    }

    await transaction(() async {
      for (final item in rawFoods) {
        final food = FoodItem.fromJson(item);
        await customInsert(
          'INSERT OR IGNORE INTO foods (id, name, normalized_name, category, serving_label, serving_amount, kcal, protein_g, carbs_g, fat_g, image_asset_path, is_custom, estimate_note) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable<int>(food.id),
            Variable<String>(food.name),
            Variable<String>(food.normalizedName.toLowerCase()),
            Variable<String>(food.category),
            Variable<String>(food.servingLabel),
            Variable<double>(food.servingAmount),
            Variable<int>(food.kcal),
            Variable<double>(food.proteinG),
            Variable<double>(food.carbsG),
            Variable<double>(food.fatG),
            Variable<String>(food.imageAssetPath),
            Variable<bool>(food.isCustom),
            Variable<String>(food.estimateNote),
          ],
          updates: {foods},
        );
      }
    });
  }

  // ===========================================================================
  // PROFILE DAO
  // ===========================================================================
  Stream<UserProfile> watchProfile() {
    return customSelect(
      'SELECT * FROM profile ORDER BY id ASC LIMIT 1',
      readsFrom: {profiles},
    ).watch().map((rows) {
      if (rows.isEmpty) {
        return UserProfile(
          id: 1,
          displayName: 'Rahul Shah',
          createdAt: DateTime.now(),
          language: 'en',
          themeMode: 'light',
          units: 'metric',
        );
      }
      final r = rows.first.data;
      return UserProfile(
        id: (r['id'] as int?) ?? 1,
        displayName: (r['display_name'] as String?) ?? 'Rahul Shah',
        avatarPath: r['avatar_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (r['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        language: (r['language'] as String?) ?? 'en',
        themeMode: (r['theme_mode'] as String?) ?? 'light',
        units: (r['units'] as String?) ?? 'metric',
        tagline:
            (r['tagline'] as String?) ?? 'Healthy Mind, Healthy Life ❤️',
      );
    });
  }

  Future<UserProfile> getProfileOnce() async {
    final rows = await customSelect(
      'SELECT * FROM profile ORDER BY id ASC LIMIT 1',
      readsFrom: {profiles},
    ).get();
    if (rows.isEmpty) {
      return UserProfile(
        id: 1,
        displayName: 'Rahul Shah',
        createdAt: DateTime.now(),
        language: 'en',
        themeMode: 'light',
        units: 'metric',
      );
    }
    final r = rows.first.data;
    return UserProfile(
      id: (r['id'] as int?) ?? 1,
      displayName: (r['display_name'] as String?) ?? 'Rahul Shah',
      avatarPath: r['avatar_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (r['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      language: (r['language'] as String?) ?? 'en',
      themeMode: (r['theme_mode'] as String?) ?? 'light',
      units: (r['units'] as String?) ?? 'metric',
      tagline: (r['tagline'] as String?) ?? 'Healthy Mind, Healthy Life ❤️',
    );
  }

  Future<void> updateProfile(UserProfile updated) async {
    await customUpdate(
      'UPDATE profile SET display_name = ?, avatar_path = ?, language = ?, theme_mode = ?, units = ?, tagline = ? WHERE id = ?',
      variables: [
        Variable<String>(updated.displayName.trim().isEmpty
            ? 'Rahul Shah'
            : updated.displayName.trim()),
        Variable<String>(updated.avatarPath),
        Variable<String>(updated.language),
        Variable<String>(updated.themeMode),
        Variable<String>(updated.units),
        Variable<String>(updated.tagline),
        Variable<int>(updated.id),
      ],
      updates: {profiles},
    );
  }

  // ===========================================================================
  // GOALS DAO
  // ===========================================================================
  Stream<NutritionGoal> watchActiveGoal() {
    return customSelect(
      'SELECT * FROM goals ORDER BY effective_from DESC, id DESC LIMIT 1',
      readsFrom: {goals},
    ).watch().map((rows) {
      if (rows.isEmpty) return NutritionGoal.defaults();
      return _mapGoalRow(rows.first.data);
    });
  }

  Future<NutritionGoal> getActiveGoalOnce() async {
    final rows = await customSelect(
      'SELECT * FROM goals ORDER BY effective_from DESC, id DESC LIMIT 1',
      readsFrom: {goals},
    ).get();
    if (rows.isEmpty) return NutritionGoal.defaults();
    return _mapGoalRow(rows.first.data);
  }

  NutritionGoal _mapGoalRow(Map<String, Object?> r) {
    return NutritionGoal(
      id: (r['id'] as int?) ?? 1,
      effectiveFrom: DateTime.fromMillisecondsSinceEpoch(
        (r['effective_from'] as int?) ??
            DateTime(2025, 1, 1).millisecondsSinceEpoch,
      ),
      calorieTarget: (r['calorie_target'] as int?) ?? 2000,
      proteinTargetG: ((r['protein_target_g'] as num?) ?? 120.0).toDouble(),
      carbsTargetG: ((r['carbs_target_g'] as num?) ?? 220.0).toDouble(),
      fatTargetG: ((r['fat_target_g'] as num?) ?? 65.0).toDouble(),
      waterTargetMl: (r['water_target_ml'] as int?) ?? 2500,
    );
  }

  Future<void> saveGoal(NutritionGoal goal) async {
    await customInsert(
      'INSERT INTO goals (effective_from, calorie_target, protein_target_g, carbs_target_g, fat_target_g, water_target_ml) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(goal.calorieTarget.clamp(500, 10000)),
        Variable<double>(goal.proteinTargetG.clamp(10.0, 600.0)),
        Variable<double>(goal.carbsTargetG.clamp(10.0, 1200.0)),
        Variable<double>(goal.fatTargetG.clamp(5.0, 400.0)),
        Variable<int>(goal.waterTargetMl.clamp(500, 10000)),
      ],
      updates: {goals},
    );
  }

  // ===========================================================================
  // FOOD CATALOGUE DAO
  // ===========================================================================
  Stream<List<FoodItem>> watchFoods({
    String searchQuery = '',
    String category = 'All',
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return customSelect(
      'SELECT * FROM foods ORDER BY is_custom DESC, id ASC',
      readsFrom: {foods},
    ).watch().map((rows) {
      final all = rows.map((r) => _mapFoodRow(r.data)).toList();
      return all.where((food) {
        final matchesCategory = category == 'All' ||
            (category == 'Custom' && food.isCustom) ||
            food.category.toLowerCase() == category.toLowerCase();
        if (!matchesCategory) return false;
        if (normalizedQuery.isEmpty) return true;
        return food.name.toLowerCase().contains(normalizedQuery) ||
            food.normalizedName.toLowerCase().contains(normalizedQuery) ||
            food.category.toLowerCase().contains(normalizedQuery);
      }).toList();
    });
  }

  Future<List<FoodItem>> getAllFoodsOnce() async {
    final rows = await customSelect(
      'SELECT * FROM foods ORDER BY id ASC',
      readsFrom: {foods},
    ).get();
    return rows.map((r) => _mapFoodRow(r.data)).toList();
  }

  FoodItem _mapFoodRow(Map<String, Object?> r) {
    final isCustomRaw = r['is_custom'];
    final isCustom = isCustomRaw == 1 || isCustomRaw == true;
    return FoodItem(
      id: (r['id'] as int?) ?? 0,
      name: (r['name'] as String?) ?? 'Food',
      normalizedName: (r['normalized_name'] as String?) ?? '',
      category: (r['category'] as String?) ?? 'Meals',
      servingLabel: (r['serving_label'] as String?) ?? '100g',
      servingAmount: ((r['serving_amount'] as num?) ?? 100.0).toDouble(),
      kcal: (r['kcal'] as int?) ?? 0,
      proteinG: ((r['protein_g'] as num?) ?? 0.0).toDouble(),
      carbsG: ((r['carbs_g'] as num?) ?? 0.0).toDouble(),
      fatG: ((r['fat_g'] as num?) ?? 0.0).toDouble(),
      imageAssetPath: r['image_asset_path'] as String?,
      isCustom: isCustom,
      estimateNote:
          (r['estimate_note'] as String?) ?? 'Estimated nutritional value',
    );
  }

  Future<int> addOrUpdateCustomFood({
    int? id,
    required String name,
    required String category,
    required String servingLabel,
    required double servingAmount,
    required int kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? imageAssetPath,
    String estimateNote = 'User custom food entry (estimate)',
  }) async {
    final cleanName = name.trim();
    final normalized = '$cleanName $category'.toLowerCase();
    if (id != null) {
      await customUpdate(
        'UPDATE foods SET name = ?, normalized_name = ?, category = ?, serving_label = ?, serving_amount = ?, kcal = ?, protein_g = ?, carbs_g = ?, fat_g = ?, image_asset_path = ?, estimate_note = ? WHERE id = ?',
        variables: [
          Variable<String>(cleanName),
          Variable<String>(normalized),
          Variable<String>(category),
          Variable<String>(servingLabel),
          Variable<double>(servingAmount),
          Variable<int>(kcal),
          Variable<double>(proteinG),
          Variable<double>(carbsG),
          Variable<double>(fatG),
          Variable<String>(imageAssetPath),
          Variable<String>(estimateNote),
          Variable<int>(id),
        ],
        updates: {foods},
      );
      return id;
    } else {
      return await customInsert(
        'INSERT INTO foods (name, normalized_name, category, serving_label, serving_amount, kcal, protein_g, carbs_g, fat_g, image_asset_path, is_custom, estimate_note) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)',
        variables: [
          Variable<String>(cleanName),
          Variable<String>(normalized),
          Variable<String>(category),
          Variable<String>(servingLabel),
          Variable<double>(servingAmount),
          Variable<int>(kcal),
          Variable<double>(proteinG),
          Variable<double>(carbsG),
          Variable<double>(fatG),
          Variable<String>(imageAssetPath),
          Variable<String>(estimateNote),
        ],
        updates: {foods},
      );
    }
  }

  /// Removes a custom food while preserving historical food_logs snapshots
  /// per Section 5 ("Food-log snapshots must remain readable even if a custom food is removed").
  Future<void> deleteCustomFood(int foodId) async {
    await transaction(() async {
      await customUpdate(
        'UPDATE food_logs SET food_id = NULL WHERE food_id = ?',
        variables: [Variable<int>(foodId)],
        updates: {foodLogs},
      );
      await customUpdate(
        'DELETE FROM foods WHERE id = ? AND is_custom = 1',
        variables: [Variable<int>(foodId)],
        updates: {foods},
      );
    });
  }

  // ===========================================================================
  // FOOD LOGGING DAO (with immutable nutrient snapshots)
  // ===========================================================================
  Stream<List<FoodLogEntry>> watchFoodLogsForDate(DateTime localDate) {
    final bounds = LocalDateHelpers.dayBoundsEpochMs(localDate);
    return customSelect(
      'SELECT * FROM food_logs WHERE logged_at >= ? AND logged_at < ? ORDER BY logged_at DESC, id DESC',
      variables: [
        Variable<int>(bounds.startMs),
        Variable<int>(bounds.endMs),
      ],
      readsFrom: {foodLogs},
    ).watch().map(
          (rows) => rows.map((r) => _mapFoodLogRow(r.data)).toList(),
        );
  }

  Stream<List<FoodLogEntry>> watchFoodLogsInRange(
    DateTime startLocal,
    DateTime endExclusiveLocal,
  ) {
    final startMs = LocalDateHelpers.startOfDay(startLocal).millisecondsSinceEpoch;
    final endMs =
        LocalDateHelpers.startOfDay(endExclusiveLocal).millisecondsSinceEpoch;
    return customSelect(
      'SELECT * FROM food_logs WHERE logged_at >= ? AND logged_at < ? ORDER BY logged_at ASC',
      variables: [
        Variable<int>(startMs),
        Variable<int>(endMs),
      ],
      readsFrom: {foodLogs},
    ).watch().map(
          (rows) => rows.map((r) => _mapFoodLogRow(r.data)).toList(),
        );
  }

  FoodLogEntry _mapFoodLogRow(Map<String, Object?> r) {
    return FoodLogEntry(
      id: (r['id'] as int?) ?? 0,
      foodId: r['food_id'] as int?,
      foodNameSnapshot: (r['food_name_snapshot'] as String?) ?? 'Food',
      loggedAt: DateTime.fromMillisecondsSinceEpoch(
        (r['logged_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      mealType: (r['meal_type'] as String?) ?? 'Lunch',
      quantity: ((r['quantity'] as num?) ?? 1.0).toDouble(),
      servingLabel: (r['serving_label'] as String?) ?? 'serving',
      kcalSnapshot: (r['kcal_snapshot'] as int?) ?? 0,
      proteinSnapshot: ((r['protein_snapshot'] as num?) ?? 0.0).toDouble(),
      carbsSnapshot: ((r['carbs_snapshot'] as num?) ?? 0.0).toDouble(),
      fatSnapshot: ((r['fat_snapshot'] as num?) ?? 0.0).toDouble(),
    );
  }

  Future<int> logFoodItem({
    required FoodItem food,
    required double quantity,
    required String mealType,
    DateTime? loggedAt,
  }) async {
    final timestamp = (loggedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final safeQty = quantity.clamp(0.1, 50.0);
    return await customInsert(
      'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<int>(food.id),
        Variable<String>(food.name),
        Variable<int>(timestamp),
        Variable<String>(mealType),
        Variable<double>(safeQty),
        Variable<String>(food.servingLabel),
        Variable<int>(food.scaledKcal(safeQty)),
        Variable<double>(food.scaledProtein(safeQty)),
        Variable<double>(food.scaledCarbs(safeQty)),
        Variable<double>(food.scaledFat(safeQty)),
      ],
      updates: {foodLogs},
    );
  }

  Future<void> updateFoodLogEntry({
    required FoodLogEntry entry,
    required double newQuantity,
    required String newMealType,
  }) async {
    final oldQty = entry.quantity <= 0 ? 1.0 : entry.quantity;
    final ratio = newQuantity / oldQty;
    final updatedKcal = (entry.kcalSnapshot * ratio).round();
    final updatedProtein =
        double.parse((entry.proteinSnapshot * ratio).toStringAsFixed(1));
    final updatedCarbs =
        double.parse((entry.carbsSnapshot * ratio).toStringAsFixed(1));
    final updatedFat =
        double.parse((entry.fatSnapshot * ratio).toStringAsFixed(1));

    await customUpdate(
      'UPDATE food_logs SET quantity = ?, meal_type = ?, kcal_snapshot = ?, protein_snapshot = ?, carbs_snapshot = ?, fat_snapshot = ? WHERE id = ?',
      variables: [
        Variable<double>(newQuantity),
        Variable<String>(newMealType),
        Variable<int>(updatedKcal),
        Variable<double>(updatedProtein),
        Variable<double>(updatedCarbs),
        Variable<double>(updatedFat),
        Variable<int>(entry.id),
      ],
      updates: {foodLogs},
    );
  }

  Future<void> deleteFoodLogEntry(int logId) async {
    await customUpdate(
      'DELETE FROM food_logs WHERE id = ?',
      variables: [Variable<int>(logId)],
      updates: {foodLogs},
    );
  }

  // ===========================================================================
  // WATER LOGGING DAO
  // ===========================================================================
  Stream<List<WaterLogEntry>> watchWaterLogsForDate(DateTime localDate) {
    final bounds = LocalDateHelpers.dayBoundsEpochMs(localDate);
    return customSelect(
      'SELECT * FROM water_logs WHERE logged_at >= ? AND logged_at < ? ORDER BY logged_at DESC, id DESC',
      variables: [
        Variable<int>(bounds.startMs),
        Variable<int>(bounds.endMs),
      ],
      readsFrom: {waterLogs},
    ).watch().map(
          (rows) => rows.map((r) => _mapWaterLogRow(r.data)).toList(),
        );
  }

  Stream<List<WaterLogEntry>> watchWaterLogsInRange(
    DateTime startLocal,
    DateTime endExclusiveLocal,
  ) {
    final startMs = LocalDateHelpers.startOfDay(startLocal).millisecondsSinceEpoch;
    final endMs =
        LocalDateHelpers.startOfDay(endExclusiveLocal).millisecondsSinceEpoch;
    return customSelect(
      'SELECT * FROM water_logs WHERE logged_at >= ? AND logged_at < ? ORDER BY logged_at ASC',
      variables: [
        Variable<int>(startMs),
        Variable<int>(endMs),
      ],
      readsFrom: {waterLogs},
    ).watch().map(
          (rows) => rows.map((r) => _mapWaterLogRow(r.data)).toList(),
        );
  }

  WaterLogEntry _mapWaterLogRow(Map<String, Object?> r) {
    return WaterLogEntry(
      id: (r['id'] as int?) ?? 0,
      loggedAt: DateTime.fromMillisecondsSinceEpoch(
        (r['logged_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      amountMl: (r['amount_ml'] as int?) ?? 250,
    );
  }

  Future<int> logWaterAmount(int amountMl, {DateTime? loggedAt}) async {
    final safeMl = amountMl.clamp(10, 5000);
    final timestamp = (loggedAt ?? DateTime.now()).millisecondsSinceEpoch;
    return await customInsert(
      'INSERT INTO water_logs (logged_at, amount_ml) VALUES (?, ?)',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(safeMl),
      ],
      updates: {waterLogs},
    );
  }

  Future<void> deleteWaterLogEntry(int id) async {
    await customUpdate(
      'DELETE FROM water_logs WHERE id = ?',
      variables: [Variable<int>(id)],
      updates: {waterLogs},
    );
  }

  // ===========================================================================
  // REMINDER SETTINGS DAO
  // ===========================================================================
  Stream<List<ReminderConfig>> watchReminders() {
    return customSelect(
      'SELECT * FROM reminder_settings ORDER BY id ASC',
      readsFrom: {reminderSettings},
    ).watch().map(
          (rows) => rows.map((r) => _mapReminderRow(r.data)).toList(),
        );
  }

  ReminderConfig _mapReminderRow(Map<String, Object?> r) {
    final enabledRaw = r['enabled'];
    return ReminderConfig(
      id: (r['id'] as int?) ?? 0,
      enabled: enabledRaw == 1 || enabledRaw == true,
      daysOfWeek: (r['days_of_week'] as String?) ?? '1,2,3,4,5,6,7',
      startMinute: (r['start_minute'] as int?) ?? 480,
      endMinute: (r['end_minute'] as int?) ?? 1260,
      intervalMinutes: (r['interval_minutes'] as int?) ?? 120,
      reminderType: (r['reminder_type'] as String?) ?? 'water',
    );
  }

  Future<void> saveReminder(ReminderConfig config) async {
    await customUpdate(
      'UPDATE reminder_settings SET enabled = ?, days_of_week = ?, start_minute = ?, end_minute = ?, interval_minutes = ?, reminder_type = ? WHERE id = ?',
      variables: [
        Variable<bool>(config.enabled),
        Variable<String>(config.daysOfWeek),
        Variable<int>(config.startMinute),
        Variable<int>(config.endMinute),
        Variable<int>(config.intervalMinutes),
        Variable<String>(config.reminderType),
        Variable<int>(config.id),
      ],
      updates: {reminderSettings},
    );
  }

  // ===========================================================================
  // APP SETTINGS DAO
  // ===========================================================================
  Stream<Map<String, String>> watchAppSettings() {
    return customSelect(
      'SELECT * FROM app_settings',
      readsFrom: {appSettings},
    ).watch().map((rows) {
      final map = <String, String>{};
      for (final r in rows) {
        final k = r.data['key'] as String?;
        final v = r.data['value'] as String?;
        if (k != null && v != null) {
          map[k] = v;
        }
      }
      return map;
    });
  }

  Future<String?> getAppSetting(String key) async {
    final rows = await customSelect(
      'SELECT value FROM app_settings WHERE key = ? LIMIT 1',
      variables: [Variable<String>(key)],
      readsFrom: {appSettings},
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data['value'] as String?;
  }

  Future<void> setAppSetting(String key, String value) async {
    await customInsert(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      variables: [
        Variable<String>(key),
        Variable<String>(value),
      ],
      updates: {appSettings},
    );
  }

  // ===========================================================================
  // STREAK, POINTS & STATS DAO
  // ===========================================================================
  Stream<({int streakDays, int totalPoints, int goalsCompleted})>
      watchProfileStats() {
    return customSelect(
      'SELECT logged_at, kcal_snapshot FROM food_logs ORDER BY logged_at DESC',
      readsFrom: {foodLogs, waterLogs, goals, appSettings},
    ).watch().asyncMap((foodRows) async {
      final demoActive = await getAppSetting('showcase_mode') == 'true';
      if (demoActive && foodRows.isNotEmpty) {
        // Matches the exact mockup stats (124 Streak, 1.2k Points, 7 Goals)
        return (streakDays: 124, totalPoints: 1240, goalsCompleted: 7);
      }
      final waterRows = await customSelect(
        'SELECT logged_at, amount_ml FROM water_logs',
        readsFrom: {waterLogs},
      ).get();

      final activeDays = <String>{};
      for (final r in foodRows) {
        final ms = r.data['logged_at'] as int?;
        if (ms != null) {
          activeDays.add(
            LocalDateHelpers.dateKey(DateTime.fromMillisecondsSinceEpoch(ms)),
          );
        }
      }
      for (final r in waterRows) {
        final ms = r.data['logged_at'] as int?;
        if (ms != null) {
          activeDays.add(
            LocalDateHelpers.dateKey(DateTime.fromMillisecondsSinceEpoch(ms)),
          );
        }
      }

      int streak = 0;
      DateTime cursor = LocalDateHelpers.startOfDay(DateTime.now());
      while (activeDays.contains(LocalDateHelpers.dateKey(cursor))) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      final totalLogs = foodRows.length + waterRows.length;
      final points = (totalLogs * 25) + (streak * 50);
      final goalsCount = activeDays.length.clamp(0, 999);
      return (
        streakDays: streak,
        totalPoints: points,
        goalsCompleted: goalsCount,
      );
    });
  }

  // ===========================================================================
  // OPTIONAL DEMO / MOCKUP SHOWCASE DATA SEEDER (Section 12 compliant)
  // ===========================================================================
  /// Populates the exact numbers shown in the 5-screen FitNepal specification
  /// mockup (Today: 720 / 2000 kcal, 36%, Protein 62g, Carbs 84g, Fats 28g,
  /// Water 1.8 / 2.5L, plus Mon–Sun weekly history culminating in 1,920 kcal).
  Future<void> seedMockupShowcaseData() async {
    final now = DateTime.now();
    final todayStart = LocalDateHelpers.startOfDay(now);

    await transaction(() async {
      // Clear today & past week logs first so totals match exact mockup figures
      final weekAgoMs =
          todayStart.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      await customUpdate(
        'DELETE FROM food_logs WHERE logged_at >= ?',
        variables: [Variable<int>(weekAgoMs)],
        updates: {foodLogs},
      );
      await customUpdate(
        'DELETE FROM water_logs WHERE logged_at >= ?',
        variables: [Variable<int>(weekAgoMs)],
        updates: {waterLogs},
      );

      // Today's exact mockup breakdown:
      // Total: 720 kcal, 62g Protein, 84g Carbs, 28g Fats
      final breakfastMs =
          todayStart.add(const Duration(hours: 8, minutes: 15)).millisecondsSinceEpoch;
      final lunchMs =
          todayStart.add(const Duration(hours: 13, minutes: 0)).millisecondsSinceEpoch;
      final snackMs =
          todayStart.add(const Duration(hours: 16, minutes: 30)).millisecondsSinceEpoch;

      await customInsert(
        'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
        'VALUES (3, ?, ?, ?, 1.0, ?, 350, 26.0, 52.0, 9.0)',
        variables: [
          const Variable<String>('Dal Bhat'),
          Variable<int>(lunchMs),
          const Variable<String>('Lunch'),
          const Variable<String>('plate'),
        ],
        updates: {foodLogs},
      );

      await customInsert(
        'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
        'VALUES (4, ?, ?, ?, 1.0, ?, 220, 31.0, 8.0, 14.0)',
        variables: [
          const Variable<String>('Chicken Curry'),
          Variable<int>(lunchMs + 60000),
          const Variable<String>('Lunch'),
          const Variable<String>('100g'),
        ],
        updates: {foodLogs},
      );

      await customInsert(
        'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
        'VALUES (2, ?, ?, ?, 1.0, ?, 100, 3.0, 16.0, 3.0)',
        variables: [
          const Variable<String>('Banana & Oats Bowl'),
          Variable<int>(breakfastMs),
          const Variable<String>('Breakfast'),
          const Variable<String>('bowl'),
        ],
        updates: {foodLogs},
      );

      await customInsert(
        'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
        'VALUES (5, ?, ?, ?, 1.0, ?, 50, 2.0, 8.0, 2.0)',
        variables: [
          const Variable<String>('Veg Salad'),
          Variable<int>(snackMs),
          const Variable<String>('Snack'),
          const Variable<String>('bowl'),
        ],
        updates: {foodLogs},
      );

      // Today's water logs totaling 1,800 ml (1.8L / 2.5L)
      final waterAmounts = [500, 500, 400, 400];
      for (var i = 0; i < waterAmounts.length; i++) {
        await customInsert(
          'INSERT INTO water_logs (logged_at, amount_ml) VALUES (?, ?)',
          variables: [
            Variable<int>(
              todayStart
                  .add(Duration(hours: 9 + (i * 2)))
                  .millisecondsSinceEpoch,
            ),
            Variable<int>(waterAmounts[i]),
          ],
          updates: {waterLogs},
        );
      }

      // Past 6 days for the weekly bar chart (Mon..Sun pattern)
      final historicalKcal = [1250, 1180, 1560, 1340, 1620, 1410, 1920];
      for (var d = 1; d <= 6; d++) {
        final dayDate = todayStart.subtract(Duration(days: d));
        final dayKcal = historicalKcal[(7 - d) % historicalKcal.length];
        await customInsert(
          'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
          'VALUES (3, ?, ?, ?, 1.0, ?, ?, 68.0, 175.0, 42.0)',
          variables: [
            const Variable<String>('Nepali Home Thali & Meals'),
            Variable<int>(
              dayDate.add(const Duration(hours: 13)).millisecondsSinceEpoch,
            ),
            const Variable<String>('Lunch'),
            const Variable<String>('daily total'),
            Variable<int>(dayKcal),
          ],
          updates: {foodLogs},
        );
        await customInsert(
          'INSERT INTO water_logs (logged_at, amount_ml) VALUES (?, 1950)',
          variables: [
            Variable<int>(
              dayDate.add(const Duration(hours: 14)).millisecondsSinceEpoch,
            ),
          ],
          updates: {waterLogs},
        );
      }

      await setAppSetting('showcase_mode', 'true');
    });
  }

  // ===========================================================================
  // BACKUP, RESTORE & DESTRUCTIVE DATA CONTROLS (Section 7)
  // ===========================================================================
  static const int backupSchemaVersion = 1;

  Future<Map<String, dynamic>> exportBackupPayload() async {
    final profile = await getProfileOnce();
    final goalRows = await customSelect('SELECT * FROM goals').get();
    final foodRows =
        await customSelect('SELECT * FROM foods WHERE is_custom = 1').get();
    final foodLogRows = await customSelect('SELECT * FROM food_logs').get();
    final waterLogRows = await customSelect('SELECT * FROM water_logs').get();
    final reminderRows =
        await customSelect('SELECT * FROM reminder_settings').get();
    final settingRows = await customSelect('SELECT * FROM app_settings').get();

    return {
      'app': 'FitNepal',
      'schemaVersion': backupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'goals': goalRows.map((r) => _mapGoalRow(r.data).toJson()).toList(),
      'customFoods': foodRows.map((r) => _mapFoodRow(r.data).toJson()).toList(),
      'foodLogs':
          foodLogRows.map((r) => _mapFoodLogRow(r.data).toJson()).toList(),
      'waterLogs':
          waterLogRows.map((r) => _mapWaterLogRow(r.data).toJson()).toList(),
      'reminders':
          reminderRows.map((r) => _mapReminderRow(r.data).toJson()).toList(),
      'appSettings': {
        for (final r in settingRows)
          (r.data['key'] as String): (r.data['value'] as String),
      },
    };
  }

  /// Validates a backup JSON string and returns a structured preview before import.
  ({
    bool isValid,
    String? errorMessage,
    int customFoodsCount,
    int foodLogsCount,
    int waterLogsCount,
    int goalsCount,
    String? profileName,
    Map<String, dynamic>? parsedPayload,
  }) validateBackupJson(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return (
        isValid: false,
        errorMessage: 'Backup file is empty.',
        customFoodsCount: 0,
        foodLogsCount: 0,
        waterLogsCount: 0,
        goalsCount: 0,
        profileName: null,
        parsedPayload: null,
      );
    }
    if (rawJson.length > 15 * 1024 * 1024) {
      return (
        isValid: false,
        errorMessage: 'Backup file exceeds maximum safe size (15 MB).',
        customFoodsCount: 0,
        foodLogsCount: 0,
        waterLogsCount: 0,
        goalsCount: 0,
        profileName: null,
        parsedPayload: null,
      );
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return (
          isValid: false,
          errorMessage: 'Backup root must be a JSON object.',
          customFoodsCount: 0,
          foodLogsCount: 0,
          waterLogsCount: 0,
          goalsCount: 0,
          profileName: null,
          parsedPayload: null,
        );
      }
      if (decoded['app'] != 'FitNepal') {
        return (
          isValid: false,
          errorMessage: 'Unrecognized backup identifier (expected FitNepal).',
          customFoodsCount: 0,
          foodLogsCount: 0,
          waterLogsCount: 0,
          goalsCount: 0,
          profileName: null,
          parsedPayload: null,
        );
      }
      final version = decoded['schemaVersion'];
      if (version is! int || version < 1 || version > backupSchemaVersion) {
        return (
          isValid: false,
          errorMessage: 'Unsupported backup schema version: $version.',
          customFoodsCount: 0,
          foodLogsCount: 0,
          waterLogsCount: 0,
          goalsCount: 0,
          profileName: null,
          parsedPayload: null,
        );
      }

      final customFoods = (decoded['customFoods'] as List?) ?? const [];
      final foodLogsList = (decoded['foodLogs'] as List?) ?? const [];
      final waterLogsList = (decoded['waterLogs'] as List?) ?? const [];
      final goalsList = (decoded['goals'] as List?) ?? const [];
      final profileMap = decoded['profile'] as Map<String, dynamic>?;

      return (
        isValid: true,
        errorMessage: null,
        customFoodsCount: customFoods.length,
        foodLogsCount: foodLogsList.length,
        waterLogsCount: waterLogsList.length,
        goalsCount: goalsList.length,
        profileName: profileMap?['displayName'] as String?,
        parsedPayload: decoded,
      );
    } catch (e) {
      return (
        isValid: false,
        errorMessage: 'Malformed JSON backup: ${e.toString()}',
        customFoodsCount: 0,
        foodLogsCount: 0,
        waterLogsCount: 0,
        goalsCount: 0,
        profileName: null,
        parsedPayload: null,
      );
    }
  }

  /// Restores a validated backup payload with an automatic temporary in-memory
  /// rollback copy before destructive restore per Section 7 ("Safety: create a
  /// temporary rollback copy before destructive restore").
  Future<void> restoreBackupPayload(
    Map<String, dynamic> payload, {
    required bool replaceExisting,
  }) async {
    final rollbackSnapshot = await exportBackupPayload();
    try {
      await _applyBackupTransaction(payload, replaceExisting: replaceExisting);
    } catch (e) {
      // Rollback to pre-restore snapshot on any failure
      await _applyBackupTransaction(rollbackSnapshot, replaceExisting: true);
      rethrow;
    }
  }

  Future<void> _applyBackupTransaction(
    Map<String, dynamic> payload, {
    required bool replaceExisting,
  }) async {
    await transaction(() async {
      if (replaceExisting) {
        await customUpdate('DELETE FROM food_logs', updates: {foodLogs});
        await customUpdate('DELETE FROM water_logs', updates: {waterLogs});
        await customUpdate(
          'DELETE FROM foods WHERE is_custom = 1',
          updates: {foods},
        );
        await customUpdate('DELETE FROM goals', updates: {goals});
      }

      final profileMap = payload['profile'] as Map<String, dynamic>?;
      if (profileMap != null) {
        final p = UserProfile.fromJson(profileMap);
        await updateProfile(p.copyWith(id: 1));
      }

      final goalsList = (payload['goals'] as List?) ?? const [];
      for (final gRaw in goalsList) {
        if (gRaw is Map<String, dynamic>) {
          final g = NutritionGoal.fromJson(gRaw);
          await saveGoal(g);
        }
      }

      final customFoodsList = (payload['customFoods'] as List?) ?? const [];
      for (final fRaw in customFoodsList) {
        if (fRaw is Map<String, dynamic>) {
          final f = FoodItem.fromJson(fRaw);
          await addOrUpdateCustomFood(
            name: f.name,
            category: f.category,
            servingLabel: f.servingLabel,
            servingAmount: f.servingAmount,
            kcal: f.kcal,
            proteinG: f.proteinG,
            carbsG: f.carbsG,
            fatG: f.fatG,
            imageAssetPath: f.imageAssetPath,
            estimateNote: f.estimateNote,
          );
        }
      }

      final foodLogsList = (payload['foodLogs'] as List?) ?? const [];
      for (final lRaw in foodLogsList) {
        if (lRaw is Map<String, dynamic>) {
          final l = FoodLogEntry.fromJson(lRaw);
          await customInsert(
            'INSERT INTO food_logs (food_id, food_name_snapshot, logged_at, meal_type, quantity, serving_label, kcal_snapshot, protein_snapshot, carbs_snapshot, fat_snapshot) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            variables: [
              const Variable<int>(null),
              Variable<String>(l.foodNameSnapshot),
              Variable<int>(l.loggedAt.millisecondsSinceEpoch),
              Variable<String>(l.mealType),
              Variable<double>(l.quantity),
              Variable<String>(l.servingLabel),
              Variable<int>(l.kcalSnapshot),
              Variable<double>(l.proteinSnapshot),
              Variable<double>(l.carbsSnapshot),
              Variable<double>(l.fatSnapshot),
            ],
            updates: {foodLogs},
          );
        }
      }

      final waterLogsList = (payload['waterLogs'] as List?) ?? const [];
      for (final wRaw in waterLogsList) {
        if (wRaw is Map<String, dynamic>) {
          final w = WaterLogEntry.fromJson(wRaw);
          await customInsert(
            'INSERT INTO water_logs (logged_at, amount_ml) VALUES (?, ?)',
            variables: [
              Variable<int>(w.loggedAt.millisecondsSinceEpoch),
              Variable<int>(w.amountMl),
            ],
            updates: {waterLogs},
          );
        }
      }
    });
  }

  /// Granular Delete Control 1: Clear Today's Logs
  Future<void> clearTodayLogs(DateTime today) async {
    final bounds = LocalDateHelpers.dayBoundsEpochMs(today);
    await transaction(() async {
      await customUpdate(
        'DELETE FROM food_logs WHERE logged_at >= ? AND logged_at < ?',
        variables: [Variable<int>(bounds.startMs), Variable<int>(bounds.endMs)],
        updates: {foodLogs},
      );
      await customUpdate(
        'DELETE FROM water_logs WHERE logged_at >= ? AND logged_at < ?',
        variables: [Variable<int>(bounds.startMs), Variable<int>(bounds.endMs)],
        updates: {waterLogs},
      );
      await setAppSetting('showcase_mode', 'false');
    });
  }

  /// Granular Delete Control 2: Clear All History
  Future<void> clearAllHistory() async {
    await transaction(() async {
      await customUpdate('DELETE FROM food_logs', updates: {foodLogs});
      await customUpdate('DELETE FROM water_logs', updates: {waterLogs});
      await setAppSetting('showcase_mode', 'false');
    });
  }

  /// Granular Delete Control 3: Reset Goals to Default
  Future<void> resetGoalsToDefault() async {
    await transaction(() async {
      await customUpdate('DELETE FROM goals', updates: {goals});
      await saveGoal(NutritionGoal.defaults());
    });
  }

  /// Granular Delete Control 4: Delete All Local Data
  Future<void> deleteAllLocalData() async {
    await transaction(() async {
      await customUpdate('DELETE FROM food_logs', updates: {foodLogs});
      await customUpdate('DELETE FROM water_logs', updates: {waterLogs});
      await customUpdate(
        'DELETE FROM foods WHERE is_custom = 1',
        updates: {foods},
      );
      await customUpdate('DELETE FROM goals', updates: {goals});
      await customUpdate('DELETE FROM app_settings', updates: {appSettings});
      await saveGoal(NutritionGoal.defaults());
      await updateProfile(
        UserProfile(
          id: 1,
          displayName: 'Rahul Shah',
          avatarPath: null,
          createdAt: DateTime.now(),
          language: 'en',
          themeMode: 'light',
          units: 'metric',
          tagline: 'Healthy Mind, Healthy Life ❤️',
        ),
      );
    });
  }

  static const List<Map<String, dynamic>> _fallbackStarterFoods = [
    {
      'id': 1,
      'name': 'Apple',
      'normalizedName': 'apple',
      'category': 'Fruits',
      'servingLabel': '100g',
      'servingAmount': 100.0,
      'kcal': 52,
      'proteinG': 0.3,
      'carbsG': 14.0,
      'fatG': 0.2,
      'imageAssetPath': 'apple',
      'isCustom': false,
      'estimateNote': 'Standard fresh red apple (estimate)',
    },
    {
      'id': 2,
      'name': 'Banana',
      'normalizedName': 'banana kera',
      'category': 'Fruits',
      'servingLabel': '100g',
      'servingAmount': 100.0,
      'kcal': 89,
      'proteinG': 1.1,
      'carbsG': 23.0,
      'fatG': 0.3,
      'imageAssetPath': 'banana',
      'isCustom': false,
      'estimateNote': 'Ripe medium banana (estimate)',
    },
    {
      'id': 3,
      'name': 'Dal Bhat',
      'normalizedName': 'dal bhat tarkari nepali thali',
      'category': 'Meals',
      'servingLabel': 'plate',
      'servingAmount': 1.0,
      'kcal': 350,
      'proteinG': 12.0,
      'carbsG': 62.0,
      'fatG': 6.0,
      'imageAssetPath': 'dal_bhat',
      'isCustom': false,
      'estimateNote': 'Traditional Nepali Dal Bhat plate (estimate)',
    },
    {
      'id': 4,
      'name': 'Chicken Curry',
      'normalizedName': 'chicken curry kukhura ko masu',
      'category': 'Meals',
      'servingLabel': '100g',
      'servingAmount': 100.0,
      'kcal': 220,
      'proteinG': 24.0,
      'carbsG': 5.0,
      'fatG': 11.5,
      'imageAssetPath': 'chicken_curry',
      'isCustom': false,
      'estimateNote': 'Nepali style spiced chicken curry (estimate)',
    },
    {
      'id': 5,
      'name': 'Veg Salad',
      'normalizedName': 'veg salad green bowl',
      'category': 'Meals',
      'servingLabel': 'bowl',
      'servingAmount': 1.0,
      'kcal': 50,
      'proteinG': 2.0,
      'carbsG': 9.0,
      'fatG': 0.8,
      'imageAssetPath': 'veg_salad',
      'isCustom': false,
      'estimateNote': 'Fresh mixed garden salad bowl (estimate)',
    },
  ];
}
