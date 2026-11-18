import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/food_artwork.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';
import '../backup_restore/backup_restore_sheet.dart';
import '../reminders/reminders_sheet.dart';
import '../water_tracking/water_tracking_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAvatarImage(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory(p.join(appDir.path, 'avatars'));
      if (!avatarsDir.existsSync()) {
        await avatarsDir.create(recursive: true);
      }
      final ext =
          p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
      final destPath = p.join(
        avatarsDir.path,
        'avatar_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(picked.path).copy(destPath);

      await ref
          .read(liveProfileProvider.notifier)
          .updateRealtime(profile.copyWith(avatarPath: destPath));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo selection cancelled or unavailable. Profile continues to work normally.',
            ),
          ),
        );
      }
    }
  }

  void _openFullProfileStudio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FullProfileCustomizationSheet(),
    );
  }

  void _openThemeAndFontStudio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeAndTypographyStudioSheet(),
    );
  }

  void _showAboutSheet(BuildContext context, WidgetRef ref, String lang) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const FitNepalHeartLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                FitNepalStrings.tr(
                  lang,
                  'FitNepal v5.0 Elite 🇳🇵',
                  'फिटनेपाल v5.0 एलिट 🇳🇵',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          FitNepalStrings.tr(
            lang,
            'FitNepal v5.0 Elite — Offline-First Android Nutrition, Calorie, Macro & Hydration Tracker.\n\n'
                '• 100% Manual & Accurate Logging: Add and edit all meals, custom foods, calories, macros, water, and goals manually.\n'
                '• Multi-Format Report Export: Export your logs in PDF, CSV, TXT, MD, or JSON format anytime.\n'
                '• 10 Custom Color Themes & 7 Font Styles (including Android System Default Font).\n'
                '• Real-Time Push Alerts with 6 Inbuilt Nepali Reminder Tones.\n'
                '• Made with ❤️ in Nepal.',
            'फिटनेपाल v5.0 एलिट — १००% अफलाइन पोषण, क्यालोरी र पानी ट्र्याकर।\n\n'
                '• सम्पूर्ण खाना, लक्ष्य र प्रोफाइल म्यानुअल रूपमा थप्न र सम्पादन गर्न सकिन्छ।\n'
                '• PDF, CSV, TXT र MD फर्म्याटमा रिपोर्ट एक्सपोर्ट सुविधा।\n'
                '• १० वटा थिम र सिस्टम डिफल्ट फन्ट समर्थन।\n'
                '• नेपालमा ❤️ का साथ निर्मित।',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(FitNepalStrings.tr(lang, 'Close', 'बन्द गर्नुहोस्')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final stats = ref.watch(profileStatsProvider).valueOrNull ??
        (streakDays: 0, totalPoints: 0, goalsCompleted: 0);
    final reminders = ref.watch(remindersProvider).valueOrNull ?? const [];
    final activeRemindersCount = reminders.where((r) => r.enabled).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final paletteSpec = FitNepalTheme.resolvePalette(profile.colorPalette);
    final fontSpec = FitNepalTheme.resolveFont(profile.fontFamily);

    final formattedPoints = stats.totalPoints >= 1000
        ? '${(stats.totalPoints / 1000.0).toStringAsFixed(1)}k'
        : '${stats.totalPoints}';

    final genderDisplay = profile.normalizedGender == 'Female'
        ? FitNepalStrings.tr(lang, 'Female', 'महिला')
        : FitNepalStrings.tr(lang, 'Male', 'पुरुष');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 12,
          ),
          children: [
            // 1. Top Bar: Quick Language Pill + Settings Gear Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () =>
                      ref.read(liveProfileProvider.notifier).toggleLanguage(),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 15,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang == 'ne' ? 'नेपाली • EN' : 'English • ने',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _openFullProfileStudio(context),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.surface
                          : primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: primaryColor,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),

            // 2. Centered Avatar with Edit Pencil Badge + Name + Tagline + Live Bio Pills
            Center(
              child: Column(
                children: [
                  UserAvatarWidget(
                    avatarPath: profile.avatarPath,
                    gender: profile.normalizedGender,
                    radius: 52,
                    showEditBadge: true,
                    onTap: () => _pickAvatarImage(context, ref, profile),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openFullProfileStudio(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayName,
                            style: TextStyle(
                              color: isDark
                                  ? FitNepalColors.darkTextPrimary
                                  : FitNepalColors.deepPlum,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => _openFullProfileStudio(context),
                    child: Text(
                      profile.tagline,
                      style: const TextStyle(
                        color: FitNepalColors.mutedPlum,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Real-time Personal Attributes Pill Strip (Gender: Male/Female, Age, Height, Weight, BMI)
                  GestureDetector(
                    onTap: () => _openFullProfileStudio(context),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        _BioBadgeChip(
                          icon: profile.normalizedGender == 'Female'
                              ? Icons.female_rounded
                              : Icons.male_rounded,
                          label: genderDisplay,
                          color: primaryColor,
                        ),
                        _BioBadgeChip(
                          icon: Icons.cake_outlined,
                          label:
                              '${profile.age} ${FitNepalStrings.tr(lang, 'yrs', 'वर्ष')}',
                          color: FitNepalColors.proteinAccent,
                        ),
                        _BioBadgeChip(
                          icon: Icons.height_rounded,
                          label: '${profile.heightCm.round()} cm',
                          color: FitNepalColors.carbsAccent,
                        ),
                        _BioBadgeChip(
                          icon: Icons.monitor_weight_outlined,
                          label: '${profile.weightKg.round()} kg',
                          color: FitNepalColors.fatsAccent,
                        ),
                        _BioBadgeChip(
                          icon: Icons.favorite_border_rounded,
                          label: 'BMI ${profile.bmiLabel}',
                          color: FitNepalColors.progressGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Three Stat Cards Row: 124 Streak | 1.2k Points | 7 Goals
            Row(
              children: [
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '🔥',
                    value: '${stats.streakDays}',
                    label: FitNepalStrings.tr(lang, 'Streak', 'स्ट्रिक'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '⭐',
                    value: formattedPoints,
                    label: FitNepalStrings.tr(lang, 'Points', 'अंक'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '🏆',
                    value: '${stats.goalsCompleted}',
                    label: FitNepalStrings.tr(lang, 'Goals', 'लक्ष्य'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Settings Menu Card
            FitNepalCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(
                children: [
                  _SettingsMenuRow(
                    icon: Icons.person_pin_rounded,
                    iconColor: primaryColor,
                    title: FitNepalStrings.tr(
                      lang,
                      'Edit Profile (Age, Gender, Body)',
                      'प्रोफाइल सम्पादन (उमेर, लिङ्ग, शरीर)',
                    ),
                    trailingLabel: '$genderDisplay, ${profile.age}',
                    onTap: () => _openFullProfileStudio(context),
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.track_changes_rounded,
                    iconColor: primaryColor,
                    title: FitNepalStrings.tr(
                      lang,
                      'My Goals',
                      'मेरो लक्ष्यहरू',
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const GoalEditorBottomSheet(),
                      );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.notifications_rounded,
                    iconColor: FitNepalColors.proteinAccent,
                    title: FitNepalStrings.tr(
                      lang,
                      'Notifications',
                      'सूचना तथा रिमाइन्डर',
                    ),
                    badgeText: '$activeRemindersCount',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const RemindersBottomSheet(),
                      );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.palette_rounded,
                    iconColor: FitNepalColors.fatsAccent,
                    title: FitNepalStrings.tr(
                      lang,
                      'Theme & Font Studio',
                      'थिम र फन्ट सेटिङ',
                    ),
                    trailingLabel:
                        '${lang == 'ne' ? paletteSpec.nameNe.split(' ').first : paletteSpec.nameEn.split(' ').first} • ${fontSpec.id.toUpperCase()}',
                    onTap: () => _openThemeAndFontStudio(context),
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.language_rounded,
                    iconColor: FitNepalColors.deepPlum,
                    title: FitNepalStrings.tr(
                      lang,
                      'Language',
                      'भाषा (Language)',
                    ),
                    trailingLabel:
                        profile.language == 'ne' ? 'नेपाली' : 'English',
                    onTap: () => _showLanguageSelectorSheet(
                      context,
                      ref,
                      profile,
                    ),
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: const Color(0xFFD32F2F),
                    title: FitNepalStrings.tr(
                      lang,
                      'Export Report (PDF, CSV, TXT, MD)',
                      'रिपोर्ट एक्सपोर्ट (PDF, CSV, TXT, MD)',
                    ),
                    trailingLabel: 'PDF/CSV',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PrivacyAndBackupSheet(),
                      );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.lock_rounded,
                    iconColor: FitNepalColors.proteinAccent,
                    title: FitNepalStrings.tr(
                      lang,
                      'Privacy, Backup & Data Controls',
                      'गोपनीयता र डाटा सुरक्षा',
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const PrivacyAndBackupSheet(),
                      );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.info_rounded,
                    iconColor: FitNepalColors.waterBlue,
                    title: FitNepalStrings.tr(
                      lang,
                      'About FitNepal v5.0 Elite',
                      'फिटनेपाल v5.0 एलिटको बारेमा',
                    ),
                    onTap: () => _showAboutSheet(context, ref, lang),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Bottom "Log Out" Soft Pink Pill Button
            InkWell(
              onTap: () async {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      FitNepalStrings.tr(
                        lang,
                        'Local Profile Session',
                        'स्थानीय प्रोफाइल सेसन',
                      ),
                    ),
                    content: Text(
                      FitNepalStrings.tr(
                        lang,
                        'FitNepal is 100% offline with no remote account. '
                            'Would you like to return to the Welcome screen (keeping all your local data safe) or open Data Controls?',
                        'फिटनेपाल १००% अफलाइन छ। के तपाईं स्वागत स्क्रिनमा फर्कन चाहनुहुन्छ वा डाटा कन्ट्रोल खोल्न चाहनुहुन्छ?',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(
                          FitNepalStrings.tr(lang, 'Cancel', 'रद्द'),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop('data'),
                        child: Text(
                          FitNepalStrings.tr(
                            lang,
                            'Data Controls',
                            'डाटा कन्ट्रोल',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop('welcome'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          FitNepalStrings.tr(
                            lang,
                            'Welcome Screen',
                            'स्वागत स्क्रिन',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (choice == 'welcome') {
                  context.go('/welcome');
                } else if (choice == 'data') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const PrivacyAndBackupSheet(),
                  );
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : primaryColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FitNepalStrings.tr(lang, 'Log Out', 'लग आउट'),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectorSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final live = ref.watch(liveProfileProvider);
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            decoration: BoxDecoration(
              color: isDark ? FitNepalColors.darkSurface : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
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
                Text(
                  FitNepalStrings.tr(
                    live.language,
                    'Select App Language (Real-Time)',
                    'एपको भाषा छान्नुहोस् (तुरुन्तै लागू हुन्छ)',
                  ),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageOptionCard(
                        flag: '🇬🇧',
                        title: 'English',
                        subtitle: 'Default International',
                        isSelected: live.language == 'en',
                        primaryColor: primaryColor,
                        onTap: () {
                          ref
                              .read(liveProfileProvider.notifier)
                              .setLanguage('en');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LanguageOptionCard(
                        flag: '🇳🇵',
                        title: 'नेपाली',
                        subtitle: 'Nepali (नेपाल)',
                        isSelected: live.language == 'ne',
                        primaryColor: primaryColor,
                        onTap: () {
                          ref
                              .read(liveProfileProvider.notifier)
                              .setLanguage('ne');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryColor : FitNepalColors.roseBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? primaryColor : null,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: FitNepalColors.mutedPlum,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BioBadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BioBadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Real-Time Profile Customisation Sheet:
/// - Display Name & Bio/Tagline
/// - Gender: Strictly Male and Female only (updates portrait & BMR in real-time!)
/// - Age (10..100 yrs)
/// - Height (cm) & Weight (kg)
/// - Activity Level
/// - Real-Time BMI + Mifflin-St Jeor Daily Calorie Calculator with 1-tap Apply to Goals
class FullProfileCustomizationSheet extends ConsumerStatefulWidget {
  const FullProfileCustomizationSheet({super.key});

  @override
  ConsumerState<FullProfileCustomizationSheet> createState() =>
      _FullProfileCustomizationSheetState();
}

class _FullProfileCustomizationSheetState
    extends ConsumerState<FullProfileCustomizationSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;

  @override
  void initState() {
    super.initState();
    final p = ref.read(liveProfileProvider);
    _nameCtrl = TextEditingController(text: p.displayName);
    _taglineCtrl = TextEditingController(text: p.tagline);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  void _updateField(UserProfile updated) {
    ref.read(liveProfileProvider.notifier).updateRealtime(updated);
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
            Row(
              children: [
                UserAvatarWidget(
                  avatarPath: profile.avatarPath,
                  gender: profile.normalizedGender,
                  radius: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FitNepalStrings.tr(
                          lang,
                          'Full Profile Customisation',
                          'पूर्ण प्रोफाइल सेटिङ',
                        ),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        FitNepalStrings.tr(
                          lang,
                          'Every change updates across FitNepal in real-time',
                          'सबै परिवर्तनहरू तुरुन्तै लागू हुन्छन्',
                        ),
                        style: const TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Name & Tagline (Real-time onChanged)
            TextField(
              controller: _nameCtrl,
              onChanged: (val) {
                _updateField(
                  profile.copyWith(
                    displayName: val.trim().isEmpty ? 'Rahul Shah' : val.trim(),
                  ),
                );
              },
              decoration: InputDecoration(
                labelText: FitNepalStrings.tr(
                  lang,
                  'Display Name',
                  'तपाईंको नाम',
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taglineCtrl,
              onChanged: (val) {
                _updateField(
                  profile.copyWith(
                    tagline: val.trim().isEmpty
                        ? 'Healthy Mind, Healthy Life ❤️'
                        : val,
                  ),
                );
              },
              decoration: InputDecoration(
                labelText: FitNepalStrings.tr(
                  lang,
                  'Bio / Tagline',
                  'ट्यागलाइन / बायो',
                ),
                prefixIcon: const Icon(Icons.favorite_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Gender Selector: Strictly Male and Female ONLY
            Text(
              FitNepalStrings.tr(
                lang,
                'Gender (Male / Female)',
                'लिङ्ग (पुरुष / महिला)',
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _GenderSelectorCard(
                    label: FitNepalStrings.tr(lang, 'Male', 'पुरुष (Male)'),
                    icon: Icons.male_rounded,
                    isSelected: profile.normalizedGender == 'Male',
                    activeColor: FitNepalColors.proteinAccent,
                    onTap: () => _updateField(profile.copyWith(gender: 'Male')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderSelectorCard(
                    label: FitNepalStrings.tr(lang, 'Female', 'महिला (Female)'),
                    icon: Icons.female_rounded,
                    isSelected: profile.normalizedGender == 'Female',
                    activeColor: primaryColor,
                    onTap: () =>
                        _updateField(profile.copyWith(gender: 'Female')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Age Slider + Stepper Buttons (Real-time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(lang, 'Age', 'उमेर (Age)'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _updateField(profile.copyWith(age: profile.age - 1)),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '${profile.age} ${FitNepalStrings.tr(lang, 'years', 'वर्ष')}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _updateField(profile.copyWith(age: profile.age + 1)),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
            Slider(
              value: profile.age.toDouble().clamp(10.0, 100.0),
              min: 10,
              max: 100,
              divisions: 90,
              activeColor: primaryColor,
              onChanged: (v) =>
                  _updateField(profile.copyWith(age: v.round())),
            ),

            // 4. Height (cm) & Weight (kg) Sliders (Real-time)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(lang, 'Height', 'उचाइ (Height)'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${profile.heightCm.round()} cm',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Slider(
              value: profile.heightCm.clamp(120.0, 220.0),
              min: 120,
              max: 220,
              divisions: 100,
              activeColor: FitNepalColors.carbsAccent,
              onChanged: (v) =>
                  _updateField(profile.copyWith(heightCm: v.roundToDouble())),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(lang, 'Weight', 'तौल (Weight)'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${profile.weightKg.round()} kg',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            Slider(
              value: profile.weightKg.clamp(30.0, 160.0),
              min: 30,
              max: 160,
              divisions: 130,
              activeColor: FitNepalColors.fatsAccent,
              onChanged: (v) =>
                  _updateField(profile.copyWith(weightKg: v.roundToDouble())),
            ),

            // 5. Activity Level Selector
            Text(
              FitNepalStrings.tr(
                lang,
                'Activity Level',
                'दैनिक सक्रियता स्तर',
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final act in const [
                  'Sedentary',
                  'Light',
                  'Moderate',
                  'Active',
                ])
                  ChoiceChip(
                    label: Text(act),
                    selected: profile.activityLevel == act,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: profile.activityLevel == act
                          ? Colors.white
                          : null,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) =>
                        _updateField(profile.copyWith(activityLevel: act)),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. Real-Time Smart BMI & Calorie Recommendation Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BMI: ${profile.bmiLabel}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${FitNepalStrings.tr(lang, 'Recommended', 'सिफारिस')}: ${profile.recommendedDailyKcal} kcal/day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Protein ${profile.recommendedProteinG.round()}g • Carbs ${profile.recommendedCarbsG.round()}g • Fats ${profile.recommendedFatG.round()}g • Water ${profile.recommendedWaterMl} ml',
                    style: const TextStyle(
                      color: FitNepalColors.mutedPlum,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(appDatabaseProvider).saveGoal(
                              NutritionGoal(
                                id: 0,
                                effectiveFrom: DateTime.now(),
                                calorieTarget: profile.recommendedDailyKcal,
                                proteinTargetG: profile.recommendedProteinG,
                                carbsTargetG: profile.recommendedCarbsG,
                                fatTargetG: profile.recommendedFatG,
                                waterTargetMl: profile.recommendedWaterMl,
                              ),
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Applied smart goals (${profile.recommendedDailyKcal} kcal) based on your ${profile.normalizedGender}, ${profile.age}y profile!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        FitNepalStrings.tr(
                          lang,
                          'Apply Recommended Goals to Dashboard',
                          'सिफारिस गरिएका लक्ष्यहरू लागू गर्नुहोस्',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryPillButton(
              label: FitNepalStrings.tr(lang, 'Done', 'सम्पन्न भयो'),
              backgroundColor: primaryColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderSelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _GenderSelectorCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : FitNepalColors.roseBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : FitNepalColors.mutedPlum,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : null,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real-Time Theme & Typography Studio Sheet:
/// - Theme Mode: Light | Dark | System
/// - 5 Color Palettes (Berry, Emerald Teal, Royal Rhododendron, Everest Cobalt, Mustang Sunset)
/// - 5 Font Styles (Sans, Rounded, Serif, Monospace, Condensed)
/// - Font Scale Slider (90% to 120%)
class ThemeAndTypographyStudioSheet extends ConsumerWidget {
  const ThemeAndTypographyStudioSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(liveProfileProvider);
    final notifier = ref.read(liveProfileProvider.notifier);
    final lang = profile.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
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
              FitNepalStrings.tr(
                lang,
                'Theme, Color Palette & Font Studio',
                'थिम, रङ र फन्ट स्टुडियो',
              ),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            // 1. Brightness Mode
            Text(
              FitNepalStrings.tr(lang, 'Brightness Mode', 'मोड छान्नुहोस्'),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in [
                  ('light', FitNepalStrings.tr(lang, 'Light', 'उज्यालो'), Icons.light_mode_rounded),
                  ('dark', FitNepalStrings.tr(lang, 'Dark', 'अँध्यारो'), Icons.dark_mode_rounded),
                  ('system', FitNepalStrings.tr(lang, 'System', 'सिस्टम'), Icons.brightness_auto_rounded),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        avatar: Icon(
                          m.$3,
                          size: 16,
                          color: profile.themeMode == m.$1
                              ? Colors.white
                              : primaryColor,
                        ),
                        label: Text(m.$2),
                        selected: profile.themeMode == m.$1,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color:
                              profile.themeMode == m.$1 ? Colors.white : null,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => notifier.setThemeMode(m.$1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Color Palettes (5 live palettes)
            Text(
              FitNepalStrings.tr(
                lang,
                'Color Theme Palette (Real-Time)',
                'रङ थिम छान्नुहोस्',
              ),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: FitNepalTheme.palettes.map((pal) {
                final isSelected = profile.colorPalette == pal.id;
                return InkWell(
                  onTap: () => notifier.setColorPalette(pal.id),
                  borderRadius: BorderRadius.circular(99),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? pal.primary.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color:
                            isSelected ? pal.primary : FitNepalColors.roseBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: pal.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lang == 'ne' ? pal.nameNe : pal.nameEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? pal.primary : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 3. Font Family Styles (5 live font families)
            Text(
              FitNepalStrings.tr(
                lang,
                'Typography / Font Family',
                'अक्षरको शैली (Font Family)',
              ),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FitNepalTheme.fonts.map((f) {
                final isSelected = profile.fontFamily == f.id;
                return ChoiceChip(
                  label: Text(
                    lang == 'ne' ? f.nameNe : f.nameEn,
                    style: TextStyle(
                      fontFamily: f.family,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  onSelected: (_) => notifier.setFontFamily(f.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Text Size Scaling Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FitNepalStrings.tr(
                    lang,
                    'Font Size Scale',
                    'अक्षरको आकार',
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${(profile.fontScale * 100).round()}%',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Slider(
              value: profile.fontScale.clamp(0.85, 1.25),
              min: 0.85,
              max: 1.25,
              divisions: 8,
              activeColor: primaryColor,
              onChanged: (v) => notifier.setFontScale(v),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _ProfileStatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? FitNepalColors.darkTextPrimary
                  : FitNepalColors.deepPlum,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: FitNepalColors.mutedPlum,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badgeText;
  final String? trailingLabel;
  final VoidCallback onTap;

  const _SettingsMenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badgeText,
    this.trailingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (trailingLabel != null) ...[
              Text(
                trailingLabel!,
                style: const TextStyle(
                  color: FitNepalColors.mutedPlum,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: FitNepalColors.mutedPlum,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 46,
      endIndent: 12,
      color: FitNepalColors.roseBorder.withOpacity(0.55),
    );
  }
}
