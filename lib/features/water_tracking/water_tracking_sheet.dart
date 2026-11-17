import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';

class WaterTrackingBottomSheet extends ConsumerStatefulWidget {
  const WaterTrackingBottomSheet({super.key});

  @override
  ConsumerState<WaterTrackingBottomSheet> createState() =>
      _WaterTrackingBottomSheetState();
}

class _WaterTrackingBottomSheetState
    extends ConsumerState<WaterTrackingBottomSheet> {
  final TextEditingController _customMlController =
      TextEditingController(text: '300');

  @override
  void dispose() {
    _customMlController.dispose();
    super.dispose();
  }

  Future<void> _addWater(int ml) async {
    final db = ref.read(appDatabaseProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final now = DateTime.now();
    final loggedTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );
    final insertedId = await db.logWaterAmount(ml, loggedAt: loggedTime);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added +$ml ml water 💧'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () {
            db.deleteWaterLogEntry(insertedId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailyNutritionSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final consumedMl = summary?.waterConsumedMl ?? 0;
    final targetMl = summary?.goal.waterTargetMl ?? 2500;
    final progress = summary?.clampedWaterProgress ?? 0.0;
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FitNepalColors.proteinCardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: FitNepalColors.waterBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hydration Tracker',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$consumedMl / $targetMl ml (${(progress * 100).round()}% of daily goal)',
                        style: const TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: FitNepalColors.waterBlue.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  FitNepalColors.waterBlue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Add Water',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final amount in const [150, 250, 500]) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton.icon(
                        onPressed: () => _addWater(amount),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: FitNepalColors.waterBlue,
                        ),
                        label: Text(
                          '${amount}ml',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: FitNepalColors.waterBlue,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: FitNepalColors.waterBlue.withOpacity(0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Custom Amount (ml)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customMlController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter ml (e.g. 350)',
                      suffixText: 'ml',
                      filled: true,
                      fillColor: isDark
                          ? FitNepalColors.darkCanvas
                          : FitNepalColors.canvasBlush,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final parsed =
                          int.tryParse(_customMlController.text.trim());
                      if (parsed == null || parsed < 10 || parsed > 5000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a sensible water amount (10–5000 ml).',
                            ),
                          ),
                        );
                        return;
                      }
                      _addWater(parsed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitNepalColors.berryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log Water',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            if (summary != null && summary.waterLogs.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                "Today's Water Entries",
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: summary.waterLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final entry = summary.waterLogs[index];
                    return Chip(
                      label: Text('${entry.amountMl} ml'),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        ref
                            .read(appDatabaseProvider)
                            .deleteWaterLogEntry(entry.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Goal Editor Sheet with positive sensible validation and Undo path per Section 4.
class GoalEditorBottomSheet extends ConsumerStatefulWidget {
  const GoalEditorBottomSheet({super.key});

  @override
  ConsumerState<GoalEditorBottomSheet> createState() =>
      _GoalEditorBottomSheetState();
}

class _GoalEditorBottomSheetState extends ConsumerState<GoalEditorBottomSheet> {
  late TextEditingController _kcalCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _waterCtrl;
  String _selectedUnits = 'metric';
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final currentGoal =
        ref.read(activeGoalProvider).valueOrNull ?? NutritionGoal.defaults();
    final profile = ref.read(userProfileProvider).valueOrNull;
    _selectedUnits = profile?.units ?? 'metric';

    _kcalCtrl =
        TextEditingController(text: currentGoal.calorieTarget.toString());
    _proteinCtrl = TextEditingController(
        text: currentGoal.proteinTargetG.round().toString());
    _carbsCtrl = TextEditingController(
        text: currentGoal.carbsTargetG.round().toString());
    _fatCtrl =
        TextEditingController(text: currentGoal.fatTargetG.round().toString());
    _waterCtrl =
        TextEditingController(text: currentGoal.waterTargetMl.toString());
  }

  @override
  void dispose() {
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    final kcal = int.tryParse(_kcalCtrl.text.trim());
    final prot = double.tryParse(_proteinCtrl.text.trim());
    final carbs = double.tryParse(_carbsCtrl.text.trim());
    final fat = double.tryParse(_fatCtrl.text.trim());
    final water = int.tryParse(_waterCtrl.text.trim());

    if (kcal == null || kcal < 800 || kcal > 8000) {
      setState(() => _validationError =
          'Daily calories must be between 800 and 8,000 kcal.');
      return;
    }
    if (prot == null || prot < 10 || prot > 500) {
      setState(
          () => _validationError = 'Protein target must be 10g to 500g.');
      return;
    }
    if (carbs == null || carbs < 20 || carbs > 1000) {
      setState(() => _validationError = 'Carbs target must be 20g to 1,000g.');
      return;
    }
    if (fat == null || fat < 10 || fat > 350) {
      setState(() => _validationError = 'Fats target must be 10g to 350g.');
      return;
    }
    if (water == null || water < 500 || water > 8000) {
      setState(
          () => _validationError = 'Water target must be 500 to 8,000 ml.');
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final previousGoal = await db.getActiveGoalOnce();
    final profile = await db.getProfileOnce();

    if (profile.units != _selectedUnits) {
      await db.updateProfile(profile.copyWith(units: _selectedUnits));
    }

    await db.saveGoal(
      NutritionGoal(
        id: 0,
        effectiveFrom: DateTime.now(),
        calorieTarget: kcal,
        proteinTargetG: prot,
        carbsTargetG: carbs,
        fatTargetG: fat,
        waterTargetMl: water,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Daily nutrition & water goals updated! 🎯'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amberAccent,
          onPressed: () {
            db.saveGoal(previousGoal);
          },
        ),
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Goals & Units',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _kcalCtrl.text = '2000';
                      _proteinCtrl.text = '120';
                      _carbsCtrl.text = '220';
                      _fatCtrl.text = '65';
                      _waterCtrl.text = '2500';
                      _validationError = null;
                    });
                  },
                  child: const Text(
                    'Reset Default',
                    style: TextStyle(
                      color: FitNepalColors.berryRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Measurement Units:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Metric (g, ml, kcal)'),
                  selected: _selectedUnits == 'metric',
                  onSelected: (_) => setState(() => _selectedUnits = 'metric'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Imperial (oz, fl oz)'),
                  selected: _selectedUnits == 'imperial',
                  onSelected: (_) =>
                      setState(() => _selectedUnits = 'imperial'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FitNepalColors.softPinkFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: FitNepalColors.berryRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: FitNepalColors.berryRed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildGoalField(
              label: 'Daily Calorie Target (kcal)',
              controller: _kcalCtrl,
              icon: Icons.local_fire_department_rounded,
              accent: FitNepalColors.berryRed,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildGoalField(
                    label: 'Protein (g)',
                    controller: _proteinCtrl,
                    icon: Icons.restaurant_rounded,
                    accent: FitNepalColors.proteinAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGoalField(
                    label: 'Carbs (g)',
                    controller: _carbsCtrl,
                    icon: Icons.grain_rounded,
                    accent: FitNepalColors.carbsAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGoalField(
                    label: 'Fats (g)',
                    controller: _fatCtrl,
                    icon: Icons.opacity_rounded,
                    accent: FitNepalColors.fatsAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildGoalField(
              label: 'Daily Water Target (ml)',
              controller: _waterCtrl,
              icon: Icons.water_drop_rounded,
              accent: FitNepalColors.waterBlue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Nutrition values are estimates. FitNepal is a personal tracking tool, not medical advice.',
              style: TextStyle(
                color: FitNepalColors.mutedPlum,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(
              label: 'Save Goals',
              leadingIcon: Icons.check_circle_outline_rounded,
              onPressed: _saveGoals,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color accent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: accent, size: 20),
            filled: true,
            fillColor:
                isDark ? FitNepalColors.darkCanvas : FitNepalColors.canvasBlush,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
