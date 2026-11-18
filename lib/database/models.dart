import 'dart:math' as math;

class UserProfile {
  final int id;
  final String displayName;
  final String? avatarPath;
  final DateTime createdAt;
  final String language; // 'en' | 'ne'
  final String themeMode; // 'light' | 'dark' | 'system'
  final String units; // 'metric' | 'imperial'
  final String tagline;
  final int age; // 10..100
  final String gender; // Strictly 'Male' | 'Female'
  final double heightCm; // 100..230
  final double weightKg; // 25..250
  final String activityLevel; // 'Sedentary' | 'Light' | 'Moderate' | 'Active'
  final String colorPalette; // 'berry' | 'teal' | 'rhododendron' | 'cobalt' | 'sunset'
  final String fontFamily; // 'sans' | 'rounded' | 'serif' | 'mono' | 'condensed'
  final double fontScale; // 0.9 .. 1.2

  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    required this.createdAt,
    required this.language,
    required this.themeMode,
    required this.units,
    this.tagline = 'Healthy Mind, Healthy Life ❤️',
    this.age = 25,
    this.gender = 'Male',
    this.heightCm = 170.0,
    this.weightKg = 68.0,
    this.activityLevel = 'Moderate',
    this.colorPalette = 'berry',
    this.fontFamily = 'sans',
    this.fontScale = 1.0,
  });

  /// Normalized gender guaranteed to be either 'Male' or 'Female'.
  String get normalizedGender => gender == 'Female' ? 'Female' : 'Male';

  /// Body Mass Index (BMI) calculated in real-time from heightCm and weightKg.
  double get bmi {
    final hMeters = (heightCm.clamp(100.0, 240.0)) / 100.0;
    return weightKg.clamp(25.0, 250.0) / (hMeters * hMeters);
  }

  String get bmiLabel => bmi.toStringAsFixed(1);

  /// Mifflin-St Jeor recommended daily calories based on Age, Gender (Male/Female), Height, Weight & Activity.
  int get recommendedDailyKcal {
    final baseBmr = (10.0 * weightKg) +
        (6.25 * heightCm) -
        (5.0 * age) +
        (normalizedGender == 'Male' ? 5.0 : -161.0);
    final double multiplier;
    switch (activityLevel) {
      case 'Sedentary':
        multiplier = 1.2;
        break;
      case 'Light':
        multiplier = 1.375;
        break;
      case 'Active':
        multiplier = 1.725;
        break;
      case 'Moderate':
      default:
        multiplier = 1.55;
        break;
    }
    return (baseBmr * multiplier).round().clamp(1200, 4500);
  }

  double get recommendedProteinG =>
      ((recommendedDailyKcal * 0.25) / 4.0).roundToDouble();
  double get recommendedCarbsG =>
      ((recommendedDailyKcal * 0.48) / 4.0).roundToDouble();
  double get recommendedFatG =>
      ((recommendedDailyKcal * 0.27) / 9.0).roundToDouble();
  int get recommendedWaterMl =>
      (weightKg * 35.0).round().clamp(1500, 4500);

  UserProfile copyWith({
    int? id,
    String? displayName,
    String? avatarPath,
    bool clearAvatar = false,
    DateTime? createdAt,
    String? language,
    String? themeMode,
    String? units,
    String? tagline,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? colorPalette,
    String? fontFamily,
    double? fontScale,
  }) {
    final nextGender = gender ?? this.gender;
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      units: units ?? this.units,
      tagline: tagline ?? this.tagline,
      age: (age ?? this.age).clamp(10, 100),
      gender: nextGender == 'Female' ? 'Female' : 'Male',
      heightCm: (heightCm ?? this.heightCm).clamp(100.0, 240.0),
      weightKg: (weightKg ?? this.weightKg).clamp(25.0, 250.0),
      activityLevel: activityLevel ?? this.activityLevel,
      colorPalette: colorPalette ?? this.colorPalette,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: (fontScale ?? this.fontScale).clamp(0.85, 1.25),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarPath': avatarPath,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'language': language,
        'themeMode': themeMode,
        'units': units,
        'tagline': tagline,
        'age': age,
        'gender': normalizedGender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'colorPalette': colorPalette,
        'fontFamily': fontFamily,
        'fontScale': fontScale,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawGender = (json['gender'] as String?) ?? 'Male';
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 1,
      displayName: (json['displayName'] as String?) ?? 'Rahul Shah',
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      language: (json['language'] as String?) ?? 'en',
      themeMode: (json['themeMode'] as String?) ?? 'light',
      units: (json['units'] as String?) ?? 'metric',
      tagline:
          (json['tagline'] as String?) ?? 'Healthy Mind, Healthy Life ❤️',
      age: ((json['age'] as num?)?.toInt() ?? 25).clamp(10, 100),
      gender: rawGender == 'Female' ? 'Female' : 'Male',
      heightCm: ((json['heightCm'] as num?)?.toDouble() ?? 170.0)
          .clamp(100.0, 240.0),
      weightKg: ((json['weightKg'] as num?)?.toDouble() ?? 68.0)
          .clamp(25.0, 250.0),
      activityLevel: (json['activityLevel'] as String?) ?? 'Moderate',
      colorPalette: (json['colorPalette'] as String?) ?? 'berry',
      fontFamily: (json['fontFamily'] as String?) ?? 'sans',
      fontScale:
          ((json['fontScale'] as num?)?.toDouble() ?? 1.0).clamp(0.85, 1.25),
    );
  }
}

class NutritionGoal {
  final int id;
  final DateTime effectiveFrom;
  final int calorieTarget;
  final double proteinTargetG;
  final double carbsTargetG;
  final double fatTargetG;
  final int waterTargetMl;

  const NutritionGoal({
    required this.id,
    required this.effectiveFrom,
    required this.calorieTarget,
    required this.proteinTargetG,
    required this.carbsTargetG,
    required this.fatTargetG,
    required this.waterTargetMl,
  });

  factory NutritionGoal.defaults() => NutritionGoal(
        id: 1,
        effectiveFrom: DateTime(2025, 1, 1),
        calorieTarget: 2000,
        proteinTargetG: 120.0,
        carbsTargetG: 220.0,
        fatTargetG: 65.0,
        waterTargetMl: 2500,
      );

  NutritionGoal copyWith({
    int? id,
    DateTime? effectiveFrom,
    int? calorieTarget,
    double? proteinTargetG,
    double? carbsTargetG,
    double? fatTargetG,
    int? waterTargetMl,
  }) {
    return NutritionGoal(
      id: id ?? this.id,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      carbsTargetG: carbsTargetG ?? this.carbsTargetG,
      fatTargetG: fatTargetG ?? this.fatTargetG,
      waterTargetMl: waterTargetMl ?? this.waterTargetMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'effectiveFrom': effectiveFrom.millisecondsSinceEpoch,
        'calorieTarget': calorieTarget,
        'proteinTargetG': proteinTargetG,
        'carbsTargetG': carbsTargetG,
        'fatTargetG': fatTargetG,
        'waterTargetMl': waterTargetMl,
      };

  factory NutritionGoal.fromJson(Map<String, dynamic> json) => NutritionGoal(
        id: (json['id'] as num?)?.toInt() ?? 1,
        effectiveFrom: DateTime.fromMillisecondsSinceEpoch(
          (json['effectiveFrom'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        calorieTarget: (json['calorieTarget'] as num?)?.toInt() ?? 2000,
        proteinTargetG: (json['proteinTargetG'] as num?)?.toDouble() ?? 120.0,
        carbsTargetG: (json['carbsTargetG'] as num?)?.toDouble() ?? 220.0,
        fatTargetG: (json['fatTargetG'] as num?)?.toDouble() ?? 65.0,
        waterTargetMl: (json['waterTargetMl'] as num?)?.toInt() ?? 2500,
      );
}

class FoodItem {
  final int id;
  final String name;
  final String normalizedName;
  final String category;
  final String servingLabel;
  final double servingAmount;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? imageAssetPath;
  final bool isCustom;
  final String estimateNote;

  const FoodItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.category,
    required this.servingLabel,
    required this.servingAmount,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.imageAssetPath,
    this.isCustom = false,
    this.estimateNote = 'Estimated nutritional value',
  });

  int scaledKcal(double quantity) => (kcal * quantity).round();
  double scaledProtein(double quantity) =>
      double.parse((proteinG * quantity).toStringAsFixed(1));
  double scaledCarbs(double quantity) =>
      double.parse((carbsG * quantity).toStringAsFixed(1));
  double scaledFat(double quantity) =>
      double.parse((fatG * quantity).toStringAsFixed(1));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'normalizedName': normalizedName,
        'category': category,
        'servingLabel': servingLabel,
        'servingAmount': servingAmount,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'imageAssetPath': imageAssetPath,
        'isCustom': isCustom,
        'estimateNote': estimateNote,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? 'Food',
        normalizedName: ((json['normalizedName'] as String?) ??
                (json['name'] as String?) ??
                'food')
            .toLowerCase(),
        category: (json['category'] as String?) ?? 'Meals',
        servingLabel: (json['servingLabel'] as String?) ?? '100g',
        servingAmount: (json['servingAmount'] as num?)?.toDouble() ?? 100.0,
        kcal: (json['kcal'] as num?)?.toInt() ?? 100,
        proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
        carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
        fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
        imageAssetPath: json['imageAssetPath'] as String?,
        isCustom: (json['isCustom'] as bool?) ?? false,
        estimateNote:
            (json['estimateNote'] as String?) ?? 'Estimated nutritional value',
      );
}

class FoodLogEntry {
  final int id;
  final int? foodId;
  final String foodNameSnapshot;
  final DateTime loggedAt;
  final String mealType; // 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack'
  final double quantity;
  final String servingLabel;
  final int kcalSnapshot;
  final double proteinSnapshot;
  final double carbsSnapshot;
  final double fatSnapshot;

  const FoodLogEntry({
    required this.id,
    this.foodId,
    required this.foodNameSnapshot,
    required this.loggedAt,
    required this.mealType,
    required this.quantity,
    required this.servingLabel,
    required this.kcalSnapshot,
    required this.proteinSnapshot,
    required this.carbsSnapshot,
    required this.fatSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'foodNameSnapshot': foodNameSnapshot,
        'loggedAt': loggedAt.millisecondsSinceEpoch,
        'mealType': mealType,
        'quantity': quantity,
        'servingLabel': servingLabel,
        'kcalSnapshot': kcalSnapshot,
        'proteinSnapshot': proteinSnapshot,
        'carbsSnapshot': carbsSnapshot,
        'fatSnapshot': fatSnapshot,
      };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) => FoodLogEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        foodId: (json['foodId'] as num?)?.toInt(),
        foodNameSnapshot: (json['foodNameSnapshot'] as String?) ?? 'Food',
        loggedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['loggedAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        mealType: (json['mealType'] as String?) ?? 'Lunch',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        servingLabel: (json['servingLabel'] as String?) ?? 'serving',
        kcalSnapshot: (json['kcalSnapshot'] as num?)?.toInt() ?? 0,
        proteinSnapshot: (json['proteinSnapshot'] as num?)?.toDouble() ?? 0.0,
        carbsSnapshot: (json['carbsSnapshot'] as num?)?.toDouble() ?? 0.0,
        fatSnapshot: (json['fatSnapshot'] as num?)?.toDouble() ?? 0.0,
      );
}

class WaterLogEntry {
  final int id;
  final DateTime loggedAt;
  final int amountMl;

  const WaterLogEntry({
    required this.id,
    required this.loggedAt,
    required this.amountMl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'loggedAt': loggedAt.millisecondsSinceEpoch,
        'amountMl': amountMl,
      };

  factory WaterLogEntry.fromJson(Map<String, dynamic> json) => WaterLogEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        loggedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['loggedAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        amountMl: (json['amountMl'] as num?)?.toInt() ?? 250,
      );
}

class ReminderConfig {
  final int id;
  final bool enabled;
  final String daysOfWeek;
  final int startMinute;
  final int endMinute;
  final int intervalMinutes;
  final String reminderType;

  const ReminderConfig({
    required this.id,
    required this.enabled,
    required this.daysOfWeek,
    required this.startMinute,
    required this.endMinute,
    required this.intervalMinutes,
    required this.reminderType,
  });

  List<int> get activeDays => daysOfWeek
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toList();

  String get formattedWindow {
    String fmt(int mins) {
      final h = (mins ~/ 60) % 24;
      final m = mins % 60;
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $period';
    }

    return '${fmt(startMinute)} – ${fmt(endMinute)}';
  }

  ReminderConfig copyWith({
    int? id,
    bool? enabled,
    String? daysOfWeek,
    int? startMinute,
    int? endMinute,
    int? intervalMinutes,
    String? reminderType,
  }) {
    return ReminderConfig(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      reminderType: reminderType ?? this.reminderType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'daysOfWeek': daysOfWeek,
        'startMinute': startMinute,
        'endMinute': endMinute,
        'intervalMinutes': intervalMinutes,
        'reminderType': reminderType,
      };

  factory ReminderConfig.fromJson(Map<String, dynamic> json) => ReminderConfig(
        id: (json['id'] as num?)?.toInt() ?? 0,
        enabled: (json['enabled'] as bool?) ?? true,
        daysOfWeek: (json['daysOfWeek'] as String?) ?? '1,2,3,4,5,6,7',
        startMinute: (json['startMinute'] as num?)?.toInt() ?? 480,
        endMinute: (json['endMinute'] as num?)?.toInt() ?? 1260,
        intervalMinutes: (json['intervalMinutes'] as num?)?.toInt() ?? 120,
        reminderType: (json['reminderType'] as String?) ?? 'water',
      );
}

class DailyNutritionSummary {
  final DateTime date;
  final NutritionGoal goal;
  final List<FoodLogEntry> foodLogs;
  final List<WaterLogEntry> waterLogs;

  const DailyNutritionSummary({
    required this.date,
    required this.goal,
    required this.foodLogs,
    required this.waterLogs,
  });

  int get caloriesConsumed =>
      foodLogs.fold<int>(0, (sum, item) => sum + item.kcalSnapshot);

  int get calorieTarget => math.max(1, goal.calorieTarget);

  int get remainingCalories => math.max(0, calorieTarget - caloriesConsumed);

  bool get isOverCalorieTarget => caloriesConsumed > calorieTarget;

  int get caloriesOverBy => math.max(0, caloriesConsumed - calorieTarget);

  double get trueCaloriePercentage => (caloriesConsumed / calorieTarget) * 100.0;

  int get caloriePercentageInt => trueCaloriePercentage.round();

  double get clampedRingProgress =>
      (caloriesConsumed / calorieTarget).clamp(0.0, 1.0);

  double get proteinConsumedG =>
      foodLogs.fold<double>(0.0, (sum, item) => sum + item.proteinSnapshot);

  double get carbsConsumedG =>
      foodLogs.fold<double>(0.0, (sum, item) => sum + item.carbsSnapshot);

  double get fatConsumedG =>
      foodLogs.fold<double>(0.0, (sum, item) => sum + item.fatSnapshot);

  int get waterConsumedMl =>
      waterLogs.fold<int>(0, (sum, item) => sum + item.amountMl);

  double get waterConsumedLiters => waterConsumedMl / 1000.0;

  double get waterTargetLiters => goal.waterTargetMl / 1000.0;

  double get clampedWaterProgress =>
      (waterConsumedMl / math.max(1, goal.waterTargetMl)).clamp(0.0, 1.0);
}

class DailyBucketSummary {
  final DateTime date;
  final String shortLabel;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;

  const DailyBucketSummary({
    required this.date,
    required this.shortLabel,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
  });
}
