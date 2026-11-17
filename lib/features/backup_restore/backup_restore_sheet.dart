import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';

class PrivacyAndBackupSheet extends ConsumerStatefulWidget {
  const PrivacyAndBackupSheet({super.key});

  @override
  ConsumerState<PrivacyAndBackupSheet> createState() =>
      _PrivacyAndBackupSheetState();
}

class _PrivacyAndBackupSheetState extends ConsumerState<PrivacyAndBackupSheet> {
  bool _isBusy = false;
  String? _statusBanner;

  Future<void> _exportJsonBackup() async {
    setState(() {
      _isBusy = true;
      _statusBanner = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      final payload = await db.exportBackupPayload();
      final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(prettyJson));
      final fileName =
          'fitnepal_backup_${DateTime.now().toIso8601String().split('T').first}.json';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save FitNepal Backup JSON',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath != null) {
        setState(() {
          _statusBanner = 'Backup exported successfully to selected file!';
        });
      } else {
        await Clipboard.setData(ClipboardData(text: prettyJson));
        setState(() {
          _statusBanner =
              'Document picker cancelled — backup JSON copied to clipboard as fallback.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusBanner = 'Export note: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importJsonBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select FitNepal Backup JSON',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      String rawJson = '';
      if (picked.bytes != null) {
        rawJson = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        rawJson = await File(picked.path!).readAsString();
      }

      if (!mounted) return;
      final db = ref.read(appDatabaseProvider);
      final validation = db.validateBackupJson(rawJson);

      if (!validation.isValid || validation.parsedPayload == null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Backup File'),
            content: Text(
              validation.errorMessage ??
                  'The selected file is not a valid FitNepal backup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Section 7 rule: "preview the result; ask whether to merge or replace.
      // Safety: create a temporary rollback copy before destructive restore."
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup Preview & Restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile: ${validation.profileName ?? 'User'}'),
              Text('Custom Foods: ${validation.customFoodsCount}'),
              Text('Food Logs: ${validation.foodLogsCount}'),
              Text('Water Logs: ${validation.waterLogsCount}'),
              Text('Goal Records: ${validation.goalsCount}'),
              const SizedBox(height: 12),
              const Text(
                'Would you like to MERGE this backup with your current data or REPLACE all existing data? (A temporary rollback copy is created automatically before replacing.)',
                style: TextStyle(fontSize: 12.5, color: FitNepalColors.mutedPlum),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop('merge'),
              child: const Text('Merge'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('replace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FitNepalColors.berryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Replace All'),
            ),
          ],
        ),
      );

      if (action == null) return;
      await db.restoreBackupPayload(
        validation.parsedPayload!,
        replaceExisting: action == 'replace',
      );
      if (mounted) {
        setState(() {
          _statusBanner =
              'Backup restored (${action == 'replace' ? 'Replaced' : 'Merged'}) successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusBanner = 'Restore failed safely: $e');
      }
    }
  }

  Future<void> _confirmDestructiveAction({
    required String title,
    required String description,
    required Future<void> Function() onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(description),
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
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirmed();
      if (mounted) {
        setState(() => _statusBanner = 'Completed: $title');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.read(appDatabaseProvider);
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
              'Privacy, Backup & Local Data Controls',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            // Section 6 Privacy statement requirement:
            // "Privacy page must state: no account required, data stored locally, no cloud sync, user controls export and deletion."
            // Section 1: "explain that uninstalling or clearing app storage can erase local data; provide export and restore."
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? FitNepalColors.darkCanvas
                    : FitNepalColors.canvasBlush,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FitNepalColors.roseBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: FitNepalColors.berryRed,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '100% On-Device Privacy Guarantee',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• No account or login is required.\n'
                    '• All profile, food, water, and goal records are stored strictly in an app-private SQLite database on your phone.\n'
                    '• Zero cloud sync, Firebase, analytics SDKs, or external servers.\n'
                    '• Uninstalling the app or clearing Android app storage will erase local data — export a JSON backup anytime to keep a safe copy.\n'
                    '• Android scoped storage is used intentionally so FitNepal never requests broad all-files access.',
                    style: TextStyle(
                      color: FitNepalColors.mutedPlum,
                      fontSize: 12.2,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_statusBanner != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FitNepalColors.softPinkFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusBanner!,
                  style: const TextStyle(
                    color: FitNepalColors.berryRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _exportJsonBackup,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Export Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FitNepalColors.berryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _importJsonBackup,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Import Backup'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section 7 Delete controls:
            // "separate clear-today, clear-history, reset-goals and delete-all-data actions. Require explicit confirmation for destructive actions."
            const Text(
              'Granular Local Data Controls',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _DeleteOptionTile(
              title: "Clear Today's Logs",
              subtitle:
                  'Removes only food and water entries logged on the selected date.',
              icon: Icons.today_rounded,
              onTap: () => _confirmDestructiveAction(
                title: "Clear Today's Logs?",
                description:
                    'This will permanently remove today\'s food and water logs.',
                onConfirmed: () =>
                    db.clearTodayLogs(ref.read(selectedDateProvider)),
              ),
            ),
            _DeleteOptionTile(
              title: 'Clear All Log History',
              subtitle:
                  'Deletes all historical food and water logs while keeping custom foods and goals.',
              icon: Icons.history_toggle_off_rounded,
              onTap: () => _confirmDestructiveAction(
                title: 'Clear All Log History?',
                description:
                    'All historical meal and hydration logs will be deleted from your device.',
                onConfirmed: () => db.clearAllHistory(),
              ),
            ),
            _DeleteOptionTile(
              title: 'Reset Goals to Default',
              subtitle:
                  'Restores 2,000 kcal, 120g Protein, 220g Carbs, 65g Fat, and 2,500 ml Water.',
              icon: Icons.restart_alt_rounded,
              onTap: () => _confirmDestructiveAction(
                title: 'Reset Goals to Default?',
                description:
                    'Your custom calorie, macro, and water targets will be reset to standard defaults.',
                onConfirmed: () => db.resetGoalsToDefault(),
              ),
            ),
            _DeleteOptionTile(
              title: 'Delete All Local Data',
              subtitle:
                  'Factory-resets profile, custom foods, goals, and all logs on this device.',
              icon: Icons.delete_forever_rounded,
              isDanger: true,
              onTap: () => _confirmDestructiveAction(
                title: 'Delete All Local Data?',
                description:
                    'This permanently erases all logs, custom foods, goals, and profile customizations on this device.',
                onConfirmed: () => db.deleteAllLocalData(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  const _DeleteOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDanger
              ? FitNepalColors.berryRed.withOpacity(0.14)
              : FitNepalColors.softPinkFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDanger ? FitNepalColors.berryRed : FitNepalColors.deepPlum,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: isDanger ? FitNepalColors.berryRed : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: FitNepalColors.mutedPlum),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }
}
