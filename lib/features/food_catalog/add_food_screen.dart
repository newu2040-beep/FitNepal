import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';
import '../food_logging/food_log_sheet.dart';
import '../reminders/reminders_sheet.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(foodSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _quickAddFood(FoodItem food, String lang) async {
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

    final hour = now.hour;
    final mealType = hour < 11
        ? 'Breakfast'
        : (hour < 15 ? 'Lunch' : (hour < 18 ? 'Snack' : 'Dinner'));

    final logId = await db.logFoodItem(
      food: food,
      quantity: 1.0,
      mealType: mealType,
      loggedAt: loggedAt,
    );

    final pushEnabled =
        await db.getAppSetting('realtime_push_on_log') != 'false';
    if (pushEnabled) {
      final toneId =
          await db.getAppSetting('reminder_tone_id') ?? 'singing_bowl';
      await LocalNotificationHelper.pushRealtimeNotification(
        title: 'Quick Added • ${food.name} 🍛',
        body: '+${food.kcal} kcal (${food.proteinG}g Protein) logged to $mealType',
        toneId: toneId,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FitNepalStrings.tr(
            lang,
            'Added 1 × ${food.servingLabel} ${food.name} (+${food.kcal} kcal)',
            'थपियो: १ × ${food.servingLabel} ${food.name} (+${food.kcal} kcal)',
          ),
        ),
        action: SnackBarAction(
          label: FitNepalStrings.tr(lang, 'UNDO', 'फिर्ता'),
          textColor: Colors.amberAccent,
          onPressed: () {
            db.deleteFoodLogEntry(logId);
          },
        ),
      ),
    );
  }

  void _openQuantitySheet(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogFoodQuantitySheet(food: food),
    );
  }

  void _openManualFoodEntry({bool logImmediately = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomFoodCreatorSheet(
        logImmediatelyDefault: logImmediately,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final foodsAsync = ref.watch(filteredFoodsProvider);
    final selectedCategory = ref.watch(selectedFoodCategoryProvider);
    final searchQuery = ref.watch(foodSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: FitNepalStrings.tr(lang, 'Back', 'पछाडि'),
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(FitNepalStrings.tr(lang, 'Add Food', 'खाना थप्नुहोस्')),
        actions: [
          IconButton(
            tooltip: FitNepalStrings.tr(
              lang,
              'Add food or meal manually',
              'आफैं खाना थप्नुहोस्',
            ),
            onPressed: () => _openManualFoodEntry(logImmediately: true),
            icon: const Icon(Icons.edit_note_rounded, size: 26),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitNepalSpacing.screenHorizontal,
                vertical: 8,
              ),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : const Color(0xFFF6ECF0),
                  borderRadius:
                      BorderRadius.circular(FitNepalSpacing.pillRadius),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(foodSearchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: FitNepalStrings.tr(
                      lang,
                      'Search food...',
                      'खाना खोज्नुहोस् (जस्तै: Dal Bhat, Momo)...',
                    ),
                    hintStyle: const TextStyle(
                      color: FitNepalColors.softPlum,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: FitNepalColors.mutedPlum,
                      size: 22,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(foodSearchQueryProvider.notifier)
                                  .state = '';
                            },
                            icon: const Icon(Icons.clear_rounded, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            CategoryChipBar(
              categories: FitNepalCategories.all,
              selectedCategory: selectedCategory,
              onSelected: (cat) {
                ref.read(selectedFoodCategoryProvider.notifier).state = cat;
              },
            ),
            const SizedBox(height: 12),

            Expanded(
              child: foodsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
                error: (err, _) => Center(
                  child: EmptyStateCard(
                    icon: Icons.error_outline_rounded,
                    title: FitNepalStrings.tr(
                      lang,
                      'Could not load food catalogue',
                      'खाना सूची लोड हुन सकेन',
                    ),
                    message: err.toString(),
                    actionLabel:
                        FitNepalStrings.tr(lang, 'Retry', 'पुनः प्रयास'),
                    onAction: () => ref.invalidate(filteredFoodsProvider),
                  ),
                ),
                data: (foods) {
                  if (foods.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: EmptyStateCard(
                          icon: Icons.post_add_rounded,
                          title: FitNepalStrings.tr(
                            lang,
                            'No matching food found',
                            'कुनै मिल्दो खाना भेटिएन',
                          ),
                          message: FitNepalStrings.tr(
                            lang,
                            'Add "$searchQuery" manually with your exact calories, protein, carbs, and fats.',
                            '"$searchQuery" को क्यालोरी र पोषण विवरण आफैं थप्नुहोस्।',
                          ),
                          actionLabel: FitNepalStrings.tr(
                            lang,
                            'Add Food Manually',
                            'म्यानुअल खाना थप्नुहोस्',
                          ),
                          onAction: () =>
                              _openManualFoodEntry(logImmediately: true),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: FitNepalSpacing.screenHorizontal,
                      vertical: 4,
                    ),
                    itemCount: foods.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 16,
                      color: FitNepalColors.roseBorder.withOpacity(0.55),
                    ),
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return _FoodCatalogueRow(
                        food: food,
                        lang: lang,
                        primaryColor: primaryColor,
                        onRowTap: () => _openQuantitySheet(food),
                        onQuickAdd: () => _quickAddFood(food, lang),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Manual Entry Card (replaces misleading Scan Food card)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FitNepalSpacing.screenHorizontal,
                8,
                FitNepalSpacing.screenHorizontal,
                16,
              ),
              child: InkWell(
                onTap: () => _openManualFoodEntry(logImmediately: true),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).colorScheme.surface
                        : primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.1 : 0.85),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.post_add_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FitNepalStrings.tr(
                                lang,
                                'Add Custom Food / Meal Manually',
                                'म्यानुअल रूपमा नयाँ खाना थप्नुहोस्',
                              ),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              FitNepalStrings.tr(
                                lang,
                                'Enter custom calories, protein, carbs, fats & serving',
                                'क्यालोरी, प्रोटिन, कार्ब्स र चिल्लो आफैं प्रविष्ट गर्नुहोस्',
                              ),
                              style: const TextStyle(
                                color: FitNepalColors.mutedPlum,
                                fontSize: 12.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodCatalogueRow extends StatelessWidget {
  final FoodItem food;
  final String lang;
  final Color primaryColor;
  final VoidCallback onRowTap;
  final VoidCallback onQuickAdd;

  const _FoodCatalogueRow({
    required this.food,
    required this.lang,
    required this.primaryColor,
    required this.onRowTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onRowTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            FoodArtworkThumbnail(
              imageAssetPath: food.imageAssetPath,
              category: food.category,
              size: 56,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            color: isDark
                                ? FitNepalColors.darkTextPrimary
                                : FitNepalColors.deepPlum,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (food.isCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            FitNepalStrings.tr(lang, 'Custom', 'कस्टम'),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${food.kcal} kcal / ${food.servingLabel} • P ${food.proteinG}g  C ${food.carbsG}g  F ${food.fatG}g',
                    style: const TextStyle(
                      color: FitNepalColors.mutedPlum,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Quick add ${food.name}',
              child: Material(
                color: primaryColor.withOpacity(0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onQuickAdd,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.add_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
