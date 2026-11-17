import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../app/providers.dart';
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

      // Section 7 rule: "Images: copy selected images into app-private storage if they must persist. Do not rely on temporary picker URIs as permanent paths."
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
          .read(appDatabaseProvider)
          .updateProfile(profile.copyWith(avatarPath: destPath));
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

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final nameCtrl = TextEditingController(text: profile.displayName);
    final taglineCtrl = TextEditingController(text: profile.tagline);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: taglineCtrl,
              decoration: const InputDecoration(
                labelText: 'Tagline / Bio',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FitNepalColors.berryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ref.read(appDatabaseProvider).updateProfile(
            profile.copyWith(
              displayName: nameCtrl.text.trim().isEmpty
                  ? 'Rahul Shah'
                  : nameCtrl.text.trim(),
              tagline: taglineCtrl.text.trim().isEmpty
                  ? 'Healthy Mind, Healthy Life ❤️'
                  : taglineCtrl.text.trim(),
            ),
          );
    }
  }

  void _showAboutSheet(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About FitNepal 🇳🇵'),
        content: const Text(
          'FitNepal v1.0.0 — Offline-First Android Nutrition, Calorie, Macro & Hydration Tracker.\n\n'
          '• Built with Flutter, Material 3, Riverpod, GoRouter, and local Drift/SQLite persistence.\n'
          '• Nutrition values are estimates. FitNepal is a personal tracking tool, not medical advice.\n'
          '• Made with ❤️ in Nepal.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(appDatabaseProvider).seedMockupShowcaseData();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Loaded Mockup Sample Data (720/2000 kcal, 62g P, 84g C, 28g F)!',
                    ),
                  ),
                );
              }
            },
            child: const Text('Load Mockup Sample Data'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: FitNepalColors.berryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull ??
        UserProfile(
          id: 1,
          displayName: 'Rahul Shah',
          createdAt: DateTime.now(),
          language: 'en',
          themeMode: 'light',
          units: 'metric',
        );
    final stats = ref.watch(profileStatsProvider).valueOrNull ??
        (streakDays: 124, totalPoints: 1240, goalsCompleted: 7);
    final reminders = ref.watch(remindersProvider).valueOrNull ?? const [];
    final activeRemindersCount = reminders.where((r) => r.enabled).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formattedPoints = stats.totalPoints >= 1000
        ? '${(stats.totalPoints / 1000.0).toStringAsFixed(1)}k'
        : '${stats.totalPoints}';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: FitNepalSpacing.screenHorizontal,
            vertical: 12,
          ),
          children: [
            // 1. Top Settings Gear Icon (matches Screen 5 top right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _showEditProfileDialog(context, ref, profile),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? FitNepalColors.darkSurface
                          : FitNepalColors.softPinkFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: FitNepalColors.deepPlum,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),

            // 2. Centered Avatar with Edit Pencil Badge + Name + Tagline
            Center(
              child: Column(
                children: [
                  UserAvatarWidget(
                    avatarPath: profile.avatarPath,
                    radius: 52,
                    showEditBadge: true,
                    onTap: () => _pickAvatarImage(context, ref, profile),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, ref, profile),
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
                  const SizedBox(height: 4),
                  Text(
                    profile.tagline,
                    style: const TextStyle(
                      color: FitNepalColors.mutedPlum,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Three Stat Cards Row: 124 Streak | 1.2k Points | 7 Goals
            Row(
              children: [
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '🔥',
                    value: '${stats.streakDays}',
                    label: 'Streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '⭐',
                    value: formattedPoints,
                    label: 'Points',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileStatCard(
                    emoji: '🏆',
                    value: '${stats.goalsCompleted}',
                    label: 'Goals',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. Settings Menu Card (My Goals, Notifications, Theme, Language, Privacy & Security, About FitNepal)
            FitNepalCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(
                children: [
                  _SettingsMenuRow(
                    icon: Icons.track_changes_rounded,
                    iconColor: FitNepalColors.berryRed,
                    title: 'My Goals',
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
                    title: 'Notifications',
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
                    icon: Icons.dark_mode_rounded,
                    iconColor: FitNepalColors.fatsAccent,
                    title: 'Theme',
                    trailingLabel: profile.themeMode == 'dark'
                        ? 'Dark'
                        : (profile.themeMode == 'system' ? 'System' : 'Light'),
                    onTap: () async {
                      final nextMode = profile.themeMode == 'light'
                          ? 'dark'
                          : (profile.themeMode == 'dark' ? 'system' : 'light');
                      await ref.read(appDatabaseProvider).updateProfile(
                            profile.copyWith(themeMode: nextMode),
                          );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.language_rounded,
                    iconColor: FitNepalColors.deepPlum,
                    title: 'Language',
                    trailingLabel:
                        profile.language == 'ne' ? 'नेपाली' : 'English',
                    onTap: () async {
                      final nextLang = profile.language == 'en' ? 'ne' : 'en';
                      await ref.read(appDatabaseProvider).updateProfile(
                            profile.copyWith(language: nextLang),
                          );
                    },
                  ),
                  const _MenuDivider(),
                  _SettingsMenuRow(
                    icon: Icons.lock_rounded,
                    iconColor: FitNepalColors.proteinAccent,
                    title: 'Privacy & Security',
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
                    title: 'About FitNepal',
                    onTap: () => _showAboutSheet(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Bottom "Log Out" Soft Pink Pill Button (matches Screen 5 bottom button)
            InkWell(
              onTap: () async {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Local Profile Session'),
                    content: const Text(
                      'FitNepal is 100% offline with no remote account. '
                      'Would you like to return to the Welcome screen (keeping all your local data safe) or open Data Controls?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('Cancel'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop('data'),
                        child: const Text('Data Controls'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop('welcome'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FitNepalColors.berryRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Welcome Screen'),
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
                      ? FitNepalColors.darkSurface
                      : const Color(0xFFFADCE4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: FitNepalColors.berryRed,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: FitNepalColors.berryRed,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? FitNepalColors.darkSurface
            : const Color(0xFFFBE9EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FitNepalColors.roseBorder.withOpacity(0.8),
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
                  color: FitNepalColors.berryRed,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
