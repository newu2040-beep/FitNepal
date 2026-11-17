import 'package:drift/drift.dart';

@DataClassName('ProfileRow')
class Profiles extends Table {
  @override
  String get tableName => 'profile';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName =>
      text().named('display_name').withDefault(const Constant('Rahul Shah'))();
  TextColumn get avatarPath => text().named('avatar_path').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  TextColumn get language =>
      text().withDefault(const Constant('en'))(); // 'en' or 'ne'
  TextColumn get themeMode =>
      text().named('theme_mode').withDefault(const Constant('light'))();
  TextColumn get units =>
      text().withDefault(const Constant('metric'))(); // 'metric' or 'imperial'
  TextColumn get tagline => text()
      .withDefault(const Constant('Healthy Mind, Healthy Life ❤️'))();
}

@DataClassName('GoalRow')
class Goals extends Table {
  @override
  String get tableName => 'goals';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get effectiveFrom => integer().named('effective_from')();
  IntColumn get calorieTarget =>
      integer().named('calorie_target').withDefault(const Constant(2000))();
  RealColumn get proteinTargetG =>
      real().named('protein_target_g').withDefault(const Constant(120.0))();
  RealColumn get carbsTargetG =>
      real().named('carbs_target_g').withDefault(const Constant(220.0))();
  RealColumn get fatTargetG =>
      real().named('fat_target_g').withDefault(const Constant(65.0))();
  IntColumn get waterTargetMl =>
      integer().named('water_target_ml').withDefault(const Constant(2500))();
}

@DataClassName('FoodRow')
class Foods extends Table {
  @override
  String get tableName => 'foods';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text().named('normalized_name')();
  TextColumn get category => text()();
  TextColumn get servingLabel => text().named('serving_label')();
  RealColumn get servingAmount =>
      real().named('serving_amount').withDefault(const Constant(100.0))();
  IntColumn get kcal => integer()();
  RealColumn get proteinG => real().named('protein_g')();
  RealColumn get carbsG => real().named('carbs_g')();
  RealColumn get fatG => real().named('fat_g')();
  TextColumn get imageAssetPath =>
      text().named('image_asset_path').nullable()();
  BoolColumn get isCustom =>
      boolean().named('is_custom').withDefault(const Constant(false))();
  TextColumn get estimateNote => text()
      .named('estimate_note')
      .withDefault(const Constant('Estimated nutritional value'))();
}

@DataClassName('FoodLogRow')
class FoodLogs extends Table {
  @override
  String get tableName => 'food_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodId => integer()
      .named('food_id')
      .nullable()
      .references(Foods, #id, onDelete: KeyAction.setNull)();
  TextColumn get foodNameSnapshot => text().named('food_name_snapshot')();
  IntColumn get loggedAt => integer().named('logged_at')();
  TextColumn get mealType => text().named('meal_type')();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get servingLabel => text().named('serving_label')();
  IntColumn get kcalSnapshot => integer().named('kcal_snapshot')();
  RealColumn get proteinSnapshot => real().named('protein_snapshot')();
  RealColumn get carbsSnapshot => real().named('carbs_snapshot')();
  RealColumn get fatSnapshot => real().named('fat_snapshot')();
}

@DataClassName('WaterLogRow')
class WaterLogs extends Table {
  @override
  String get tableName => 'water_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get loggedAt => integer().named('logged_at')();
  IntColumn get amountMl => integer().named('amount_ml')();
}

@DataClassName('ReminderSettingRow')
class ReminderSettings extends Table {
  @override
  String get tableName => 'reminder_settings';

  IntColumn get id => integer().autoIncrement()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get daysOfWeek =>
      text().named('days_of_week').withDefault(const Constant('1,2,3,4,5,6,7'))();
  IntColumn get startMinute =>
      integer().named('start_minute').withDefault(const Constant(480))(); // 08:00
  IntColumn get endMinute =>
      integer().named('end_minute').withDefault(const Constant(1260))(); // 21:00
  IntColumn get intervalMinutes =>
      integer().named('interval_minutes').withDefault(const Constant(120))();
  TextColumn get reminderType =>
      text().named('reminder_type')(); // 'water' or 'meal'
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
