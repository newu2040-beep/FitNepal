import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';
import '../reminders/reminders_sheet.dart';

/// Bottom sheet to select serving quantity, edit nutrients manually if desired,
/// and choose meal type before logging a food item.
class LogFoodQuantitySheet extends ConsumerStatefulWidget {
  final FoodItem food;

  const LogFoodQuantitySheet({super.key, required this.food});

  @override
  ConsumerState<LogFoodQuantitySheet> createState() =>
      _LogFoodQuantitySheetState();
}

class _LogFoodQuantitySheetState extends ConsumerState<LogFoodQuantitySheet> {
  double _quantity = 1.0;
  String _selectedMealType = 'Lunch';

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = 'Breakfast';
    } else if (hour < 15) {
      _selectedMealType = 'Lunch';
    } else if (hour < 18) {
      _selectedMealType = 'Snack';
    } else {
      _selectedMealType = 'Dinner';
    }
  }

  Future<void> _confirmLog() async {
    final db = ref.read(appDatabaseProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final now = DateTime.now();
    final loggedAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final logId = await db.logFoodItem(
      food: widget.food,
      quantity: _quantity,
      mealType: _selectedMealType,
      loggedAt: loggedAt,
    );

    final pushEnabled =
        await db.getAppSetting('realtime_push_on_log') != 'false';
    if (pushEnabled) {
      final toneId =
          await db.getAppSetting('reminder_tone_id') ?? 'singing_bowl';
      await LocalNotificationHelper.pushRealtimeNotification(
        title: 'Meal Logged • ${widget.food.name} 🍛',
        body:
            '+${widget.food.scaledKcal(_quantity)} kcal (${widget.food.scaledProtein(_quantity)}g Protein) added to $_selectedMealType',
        toneId: toneId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${widget.food.name} (${widget.food.scaledKcal(_quantity)} kcal) to $_selectedMealType',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () {
            db.deleteFoodLogEntry(logId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? FitNepalColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FitNepalColors.roseBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                FoodArtworkThumbnail(
                  imageAssetPath: food.imageAssetPath,
                  category: food.category,
                  size: 60,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${food.kcal} kcal per ${food.servingLabel} • ${food.category}',
                        style: const TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit food values manually',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          CustomFoodCreatorSheet(existingFood: food),
                    );
                  },
                  icon: Icon(Icons.edit_outlined, color: primaryColor),
                ),
                if (food.isCustom)
                  IconButton(
                    tooltip: 'Delete custom food',
                    onPressed: () async {
                      await ref
                          .read(appDatabaseProvider)
                          .deleteCustomFood(food.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? FitNepalColors.darkCanvas
                    : primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientPreviewColumn(
                    label: 'Calories',
                    value: '${food.scaledKcal(_quantity)}',
                    unit: 'kcal',
                    color: primaryColor,
                  ),
                  _NutrientPreviewColumn(
                    label: 'Protein',
                    value: '${food.scaledProtein(_quantity)}',
                    unit: 'g',
                    color: FitNepalColors.proteinAccent,
                  ),
                  _NutrientPreviewColumn(
                    label: 'Carbs',
                    value: '${food.scaledCarbs(_quantity)}',
                    unit: 'g',
                    color: FitNepalColors.carbsAccent,
                  ),
                  _NutrientPreviewColumn(
                    label: 'Fats',
                    value: '${food.scaledFat(_quantity)}',
                    unit: 'g',
                    color: FitNepalColors.fatsAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Serving Quantity (${food.servingLabel})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_quantity.toStringAsFixed(_quantity.truncateToDouble() == _quantity ? 0 : 1)} × ${food.servingLabel}',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in const [0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
                  ChoiceChip(
                    label: Text(
                      q == q.truncateToDouble()
                          ? '${q.toInt()}×'
                          : '${q.toStringAsFixed(1)}×',
                    ),
                    selected: _quantity == q,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: _quantity == q
                          ? Colors.white
                          : (isDark
                              ? FitNepalColors.darkTextPrimary
                              : FitNepalColors.deepPlum),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _quantity = q),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'Meal Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final meal in FitNepalCategories.mealTypes)
                  ChoiceChip(
                    label: Text(meal),
                    selected: _selectedMealType == meal,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedMealType == meal
                          ? Colors.white
                          : (isDark
                              ? FitNepalColors.darkTextPrimary
                              : FitNepalColors.deepPlum),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedMealType = meal),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            PrimaryPillButton(
              label:
                  'Add to $_selectedMealType (${food.scaledKcal(_quantity)} kcal)',
              leadingIcon: Icons.add_circle_outline_rounded,
              onPressed: _confirmLog,
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientPreviewColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientPreviewColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FitNepalColors.mutedPlum,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: FitNepalColors.softPlum,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Comprehensive Manual Food & Meal Entry Studio:
/// Lets the user add any food, meal, drink, or nutrition values manually,
/// optionally log it immediately to today's meals, and/or save it to the catalogue.
class CustomFoodCreatorSheet extends ConsumerStatefulWidget {
  final FoodItem? existingFood;
  final bool logImmediatelyDefault;

  const CustomFoodCreatorSheet({
    super.key,
    this.existingFood,
    this.logImmediatelyDefault = true,
  });

  @override
  ConsumerState<CustomFoodCreatorSheet> createState() =>
      _CustomFoodCreatorSheetState();
}

class _CustomFoodCreatorSheetState
    extends ConsumerState<CustomFoodCreatorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _servingCtrl;
  late final TextEditingController _kcalCtrl;
  late final TextEditingController _protCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _qtyCtrl;
  String _category = 'Meals';
  String _mealType = 'Lunch';
  String? _savedImagePath;
  bool _alsoLogNow = true;
  bool _saveToCatalogue = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ex = widget.existingFood;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _servingCtrl = TextEditingController(text: ex?.servingLabel ?? '1 serving');
    _kcalCtrl = TextEditingController(text: (ex?.kcal ?? 250).toString());
    _protCtrl = TextEditingController(
        text: (ex?.proteinG ?? 12.0).toStringAsFixed(1));
    _carbsCtrl = TextEditingController(
        text: (ex?.carbsG ?? 32.0).toStringAsFixed(1));
    _fatCtrl =
        TextEditingController(text: (ex?.fatG ?? 8.0).toStringAsFixed(1));
    _qtyCtrl = TextEditingController(text: '1.0');
    _category = ex?.category ?? 'Meals';
    _savedImagePath = ex?.imageAssetPath;
    _alsoLogNow = ex == null ? widget.logImmediatelyDefault : false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _kcalCtrl.dispose();
    _protCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoodPhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'food_images'));
      if (!imagesDir.existsSync()) {
        await imagesDir.create(recursive: true);
      }
      final ext =
          p.extension(xfile.path).isEmpty ? '.jpg' : p.extension(xfile.path);
      final targetPath = p.join(
        imagesDir.path,
        'food_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(xfile.path).copy(targetPath);
      if (mounted) {
        setState(() => _savedImagePath = targetPath);
      }
    } catch (_) {}
  }

  Future<void> _saveManualFoodAndLog() async {
    final name = _nameCtrl.text.trim();
    final serving = _servingCtrl.text.trim();
    final kcal = int.tryParse(_kcalCtrl.text.trim());
    final prot = double.tryParse(_protCtrl.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsCtrl.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatCtrl.text.trim()) ?? 0.0;
    final qty = (double.tryParse(_qtyCtrl.text.trim()) ?? 1.0).clamp(0.1, 25.0);

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a food or meal name.');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 8000) {
      setState(() => _error = 'Please enter a valid calorie value (0–8000).');
      return;
    }

    final db = ref.read(appDatabaseProvider);
    int? foodId = widget.existingFood?.id;

    if (_saveToCatalogue || widget.existingFood != null) {
      foodId = await db.addOrUpdateCustomFood(
        id: widget.existingFood?.id,
        name: name,
        category: _category,
        servingLabel: serving.isEmpty ? '1 serving' : serving,
        servingAmount: 1.0,
        kcal: kcal,
        proteinG: prot.clamp(0.0, 500.0),
        carbsG: carbs.clamp(0.0, 800.0),
        fatG: fat.clamp(0.0, 500.0),
        imageAssetPath: _savedImagePath,
      );
    }

    if (_alsoLogNow) {
      final selectedDate = ref.read(selectedDateProvider);
      final now = DateTime.now();
      final loggedAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final tempFood = FoodItem(
        id: foodId ?? 0,
        name: name,
        normalizedName: name.toLowerCase(),
        category: _category,
        servingLabel: serving.isEmpty ? '1 serving' : serving,
        servingAmount: 1.0,
        kcal: kcal,
        proteinG: prot,
        carbsG: carbs,
        fatG: fat,
        imageAssetPath: _savedImagePath,
        isCustom: true,
      );

      await db.logFoodItem(
        food: tempFood,
        quantity: qty,
        mealType: _mealType,
        loggedAt: loggedAt,
      );

      final pushEnabled =
          await db.getAppSetting('realtime_push_on_log') != 'false';
      if (pushEnabled) {
        final toneId =
            await db.getAppSetting('reminder_tone_id') ?? 'singing_bowl';
        await LocalNotificationHelper.pushRealtimeNotification(
          title: 'Manual Meal Logged • $name 🍛',
          body:
              '+${tempFood.scaledKcal(qty)} kcal (${tempFood.scaledProtein(qty)}g P, ${tempFood.scaledCarbs(qty)}g C, ${tempFood.scaledFat(qty)}g F)',
          toneId: toneId,
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _alsoLogNow
              ? 'Logged "$name" (+${(kcal * qty).round()} kcal) to $_mealType!'
              : 'Saved "$name" to your food catalogue!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? FitNepalColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FitNepalColors.roseBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.existingFood != null
                  ? FitNepalStrings.tr(
                      lang,
                      'Edit Food & Nutrition Values',
                      'खाना र पोषण विवरण सम्पादन',
                    )
                  : FitNepalStrings.tr(
                      lang,
                      'Manual Food & Nutrition Entry',
                      'म्यानुअल खाना र पोषण प्रविष्टि',
                    ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              FitNepalStrings.tr(
                lang,
                'Enter exact calories, protein, carbs, fats, serving & meal manually',
                'आफ्नो खानाको क्यालोरी, प्रोटिन, कार्ब्स र चिल्लो आफैं भर्नुहोस्',
              ),
              style: const TextStyle(
                color: FitNepalColors.mutedPlum,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                GestureDetector(
                  onTap: _pickFoodPhoto,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: _savedImagePath != null &&
                            _savedImagePath!.startsWith('/') &&
                            File(_savedImagePath!).existsSync()
                        ? ClipOval(
                            child: Image.file(
                              File(_savedImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo_rounded,
                            color: primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: FitNepalStrings.tr(
                        lang,
                        'Food / Dish Name (e.g. Homemade Dal Bhat)',
                        'खानाको नाम',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Meals', 'Fruits', 'Snacks', 'Drinks', 'Dairy']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _servingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Serving Unit (e.g. 1 plate)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kcalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories (kcal)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _protCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fats (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.existingFood == null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: primaryColor,
                title: Text(
                  FitNepalStrings.tr(
                    lang,
                    'Log to Today\'s Meals Immediately',
                    'आजको खानामा तुरुन्तै थप्नुहोस्',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                value: _alsoLogNow,
                onChanged: (v) => setState(() => _alsoLogNow = v),
              ),
              if (_alsoLogNow)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _mealType,
                        decoration: const InputDecoration(
                          labelText: 'Meal Type',
                          border: OutlineInputBorder(),
                        ),
                        items: FitNepalCategories.mealTypes
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _mealType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity (e.g. 1.0)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: primaryColor,
                title: Text(
                  FitNepalStrings.tr(
                    lang,
                    'Save to My Food Catalogue for Future Use',
                    'भविष्यको लागि खाना सूचीमा सुरक्षित गर्नुहोस्',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: _saveToCatalogue,
                onChanged: (v) => setState(() => _saveToCatalogue = v),
              ),
            ],
            const SizedBox(height: 14),
            PrimaryPillButton(
              label: widget.existingFood != null
                  ? FitNepalStrings.tr(lang, 'Update Food', 'अद्यावधिक गर्नुहोस्')
                  : (_alsoLogNow
                      ? FitNepalStrings.tr(
                          lang,
                          'Log & Save Manual Entry',
                          'खाना थप्नुहोस् र सुरक्षित गर्नुहोस्',
                        )
                      : FitNepalStrings.tr(
                          lang,
                          'Save to Food Catalogue',
                          'खाना सूचीमा सुरक्षित गर्नुहोस्',
                        )),
              leadingIcon: Icons.check_circle_outline_rounded,
              onPressed: _saveManualFoodAndLog,
            ),
          ],
        ),
      ),
    );
  }
}
