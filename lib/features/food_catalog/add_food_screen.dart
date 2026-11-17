import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';
import '../food_logging/food_log_sheet.dart';

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

  Future<void> _quickAddFood(FoodItem food) async {
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added 1 × ${food.servingLabel} ${food.name} (+${food.kcal} kcal)',
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

  void _openQuantitySheet(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogFoodQuantitySheet(food: food),
    );
  }

  void _openScanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScanFoodLookupSheet(),
    );
  }

  void _openCustomFoodCreator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomFoodCreatorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(filteredFoodsProvider);
    final selectedCategory = ref.watch(selectedFoodCategoryProvider);
    final searchQuery = ref.watch(foodSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Add Food'),
        actions: [
          IconButton(
            tooltip: 'Create custom food',
            onPressed: _openCustomFoodCreator,
            icon: const Icon(Icons.post_add_rounded, size: 22),
          ),
          IconButton(
            tooltip: 'Scan food barcode',
            onPressed: _openScanSheet,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Pill Search Bar ("Search food...")
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitNepalSpacing.screenHorizontal,
                vertical: 8,
              ),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? FitNepalColors.darkSurface
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
                    hintText: 'Search food...',
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

            // 2. Horizontal Category Chips (All, Fruits, Meals, Snacks, Drinks, Dairy, Custom)
            CategoryChipBar(
              categories: FitNepalCategories.all,
              selectedCategory: selectedCategory,
              onSelected: (cat) {
                ref.read(selectedFoodCategoryProvider.notifier).state = cat;
              },
            ),
            const SizedBox(height: 12),

            // 3. Food Catalogue List
            Expanded(
              child: foodsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: FitNepalColors.berryRed,
                  ),
                ),
                error: (err, _) => Center(
                  child: EmptyStateCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load food catalogue',
                    message: err.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(filteredFoodsProvider),
                  ),
                ),
                data: (foods) {
                  if (foods.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: EmptyStateCard(
                          icon: Icons.search_off_rounded,
                          title: 'No matching food found',
                          message:
                              'Can\'t find "$searchQuery"? Add it as a custom food entry in seconds.',
                          actionLabel: 'Create Custom Food',
                          onAction: _openCustomFoodCreator,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
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
                        onRowTap: () => _openQuantitySheet(food),
                        onQuickAdd: () => _quickAddFood(food),
                      );
                    },
                  );
                },
              ),
            ),

            // 4. Bottom "Scan Food - Find nutrition info" Card (matches Screen 3 bottom card)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FitNepalSpacing.screenHorizontal,
                8,
                FitNepalSpacing.screenHorizontal,
                16,
              ),
              child: InkWell(
                onTap: _openScanSheet,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? FitNepalColors.darkSurface
                        : const Color(0xFFFDE6EE),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: FitNepalColors.berryRed.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: FitNepalColors.berryRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Food',
                              style: TextStyle(
                                color: FitNepalColors.berryRed,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Find nutrition info',
                              style: TextStyle(
                                color: FitNepalColors.mutedPlum,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: FitNepalColors.berryRed,
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
  final VoidCallback onRowTap;
  final VoidCallback onQuickAdd;

  const _FoodCatalogueRow({
    required this.food,
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
                            color: FitNepalColors.softPinkFill,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(
                              color: FitNepalColors.berryRed,
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
                    '${food.kcal} kcal / ${food.servingLabel}',
                    style: const TextStyle(
                      color: FitNepalColors.mutedPlum,
                      fontSize: 13.5,
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
                color: FitNepalColors.softPinkFill,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onQuickAdd,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.add_rounded,
                      color: FitNepalColors.berryRed,
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
