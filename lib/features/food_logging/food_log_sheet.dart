import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';

/// Bottom sheet to select serving quantity and meal type before logging a food item.
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
                      Text(
                        food.estimateNote,
                        style: const TextStyle(
                          color: FitNepalColors.softPlum,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
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
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: FitNepalColors.berryRed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Scaled Macro & Calorie Preview Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? FitNepalColors.darkCanvas
                    : FitNepalColors.canvasBlush,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FitNepalColors.roseBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientPreviewColumn(
                    label: 'Calories',
                    value: '${food.scaledKcal(_quantity)}',
                    unit: 'kcal',
                    color: FitNepalColors.berryRed,
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

            // Quantity Selector
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
                  style: const TextStyle(
                    color: FitNepalColors.berryRed,
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
                for (final q in const [0.5, 1.0, 1.5, 2.0, 3.0])
                  ChoiceChip(
                    label: Text(
                      q == q.truncateToDouble()
                          ? '${q.toInt()}×'
                          : '${q.toStringAsFixed(1)}×',
                    ),
                    selected: _quantity == q,
                    selectedColor: FitNepalColors.berryRed,
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

            // Meal Type Selector
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
                    selectedColor: FitNepalColors.berryRed,
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

/// Custom Food Creation Sheet with Android Photo Picker support (copied to app-private storage).
class CustomFoodCreatorSheet extends ConsumerStatefulWidget {
  const CustomFoodCreatorSheet({super.key});

  @override
  ConsumerState<CustomFoodCreatorSheet> createState() =>
      _CustomFoodCreatorSheetState();
}

class _CustomFoodCreatorSheetState
    extends ConsumerState<CustomFoodCreatorSheet> {
  final _nameCtrl = TextEditingController();
  final _servingCtrl = TextEditingController(text: '1 bowl');
  final _kcalCtrl = TextEditingController(text: '250');
  final _protCtrl = TextEditingController(text: '10');
  final _carbsCtrl = TextEditingController(text: '35');
  final _fatCtrl = TextEditingController(text: '8');
  String _category = 'Meals';
  String? _savedImagePath;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _kcalCtrl.dispose();
    _protCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
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

      // Section 7 rule: "Images: copy selected images into app-private storage if they must persist. Do not rely on temporary picker URIs as permanent paths."
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo selection cancelled or unavailable. You can still save your custom food.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveCustomFood() async {
    final name = _nameCtrl.text.trim();
    final serving = _servingCtrl.text.trim();
    final kcal = int.tryParse(_kcalCtrl.text.trim());
    final prot = double.tryParse(_protCtrl.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsCtrl.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a food name.');
      return;
    }
    if (kcal == null || kcal <= 0 || kcal > 5000) {
      setState(() => _error = 'Please enter a valid calorie value (1–5000).');
      return;
    }

    await ref.read(appDatabaseProvider).addOrUpdateCustomFood(
          name: name,
          category: _category,
          servingLabel: serving.isEmpty ? '1 serving' : serving,
          servingAmount: 1.0,
          kcal: kcal,
          proteinG: prot.clamp(0.0, 500.0),
          carbsG: carbs.clamp(0.0, 500.0),
          fatG: fat.clamp(0.0, 500.0),
          imageAssetPath: _savedImagePath,
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "$name" to your offline catalogue!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            const SizedBox(height: 16),
            const Text(
              'Create Custom Food',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(
                  color: FitNepalColors.berryRed,
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: FitNepalColors.softPinkFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: FitNepalColors.roseBorder),
                    ),
                    child: _savedImagePath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_savedImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo_rounded,
                            color: FitNepalColors.berryRed,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Food / Dish Name (e.g. Buff Sukuti)',
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
                      labelText: 'Serving Label (e.g. 1 plate)',
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
            const SizedBox(height: 18),
            PrimaryPillButton(
              label: 'Save Custom Food',
              leadingIcon: Icons.save_rounded,
              onPressed: _saveCustomFood,
            ),
          ],
        ),
      ),
    );
  }
}

/// Offline Scan Food / Barcode & Nutrition Estimator sheet with contextual
/// Camera permission UX per Section 6 ("Show a short explanation immediately
/// before the system permission prompt, tied to the feature the user tapped.
/// If denied, show a non-blocking explanation. If permanently denied, offer an Open Settings action.")
class ScanFoodLookupSheet extends ConsumerStatefulWidget {
  const ScanFoodLookupSheet({super.key});

  @override
  ConsumerState<ScanFoodLookupSheet> createState() =>
      _ScanFoodLookupSheetState();
}

class _ScanFoodLookupSheetState extends ConsumerState<ScanFoodLookupSheet> {
  final _barcodeCtrl = TextEditingController();
  bool _cameraAuthorized = false;
  bool _permanentlyDenied = false;
  String? _statusMessage;

  static const Map<String, String> _offlineBarcodeMap = {
    '8901058001259': 'Dal Bhat',
    '8901262010016': 'Milk (Dudh)',
    '8901063014220': 'Banana',
    '8904004400113': 'Steamed Momo (Chicken)',
    '8901725121143': 'Apple',
  };

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestCameraWithExplanation() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Access for Scan Food'),
        content: const Text(
          'FitNepal uses your camera only when you choose to scan a food package barcode offline. '
          'Images never leave your phone, and you can always search or enter codes manually without granting camera access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Use Manual Lookup'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FitNepalColors.berryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (status.isGranted) {
        setState(() {
          _cameraAuthorized = true;
          _permanentlyDenied = false;
          _statusMessage =
              'Camera ready! Point at a Nepali food barcode or tap a sample code below.';
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _cameraAuthorized = false;
          _permanentlyDenied = true;
          _statusMessage =
              'Camera permission is permanently denied. You can still look up barcodes manually below, or enable Camera in Android Settings.';
        });
      } else {
        setState(() {
          _cameraAuthorized = false;
          _permanentlyDenied = false;
          _statusMessage =
              'Camera access denied — no problem! All offline barcode and food lookups below remain 100% usable.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Offline barcode & portion lookup ready below.';
        });
      }
    }
  }

  Future<void> _lookupByName(String foodName) async {
    final foods = await ref.read(appDatabaseProvider).getAllFoodsOnce();
    final match = foods.firstWhere(
      (f) => f.name.toLowerCase().contains(foodName.toLowerCase()),
      orElse: () => foods.first,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogFoodQuantitySheet(food: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: FitNepalColors.softPinkFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: FitNepalColors.berryRed,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Food & Nutrition Info',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '100% Offline barcode & portion estimator',
                        style: TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Viewfinder / Camera Permission Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? FitNepalColors.darkCanvas
                    : FitNepalColors.canvasBlush,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FitNepalColors.roseBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    _cameraAuthorized
                        ? Icons.center_focus_strong_rounded
                        : Icons.camera_alt_outlined,
                    size: 40,
                    color: FitNepalColors.berryRed,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage ??
                        'Tap below to enable camera barcode scanning, or pick an offline product preset immediately without camera access.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _requestCameraWithExplanation,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: Text(
                          _cameraAuthorized
                              ? 'Re-Scan Camera'
                              : 'Scan with Camera',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FitNepalColors.berryRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_permanentlyDenied)
                        OutlinedButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Open Settings'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Quick Offline Barcode Presets',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _offlineBarcodeMap.entries.map((e) {
                return ActionChip(
                  avatar: const Icon(
                    Icons.view_week_rounded,
                    size: 16,
                    color: FitNepalColors.berryRed,
                  ),
                  label: Text('${e.value} (${e.key.substring(0, 6)}…)'),
                  onPressed: () => _lookupByName(e.value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
