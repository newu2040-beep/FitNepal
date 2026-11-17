import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';

class LocalNotificationHelper {
  LocalNotificationHelper._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidInit =
          AndroidInitializationSettings('@android:drawable/ic_dialog_info');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Safe fallback in unit tests or unsupported environments
    }
  }

  static Future<void> showTestReminderNotification({
    required String title,
    required String body,
  }) async {
    try {
      await ensureInitialized();
      const androidDetails = AndroidNotificationDetails(
        'fitnepal_reminders',
        'FitNepal Meal & Water Reminders',
        channelDescription:
            'Local on-device meal and hydration reminders for FitNepal',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      await _plugin.show(
        101,
        title,
        body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }
}

class RemindersBottomSheet extends ConsumerStatefulWidget {
  const RemindersBottomSheet({super.key});

  @override
  ConsumerState<RemindersBottomSheet> createState() =>
      _RemindersBottomSheetState();
}

class _RemindersBottomSheetState extends ConsumerState<RemindersBottomSheet> {
  bool _permanentlyDenied = false;
  String? _permissionNote;

  Future<bool> _ensureNotificationPermissionContextual() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;

      if (!mounted) return false;
      // Section 6 Permission UX rule:
      // "Show a short explanation immediately before the system permission prompt, tied to the feature the user tapped."
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Local Reminders?'),
          content: const Text(
            'FitNepal schedules meal and water reminders locally on your phone. '
            'Android 13+ requires notification permission to display these alerts. '
            'No data is ever sent to any server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FitNepalColors.berryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Allow Notifications'),
            ),
          ],
        ),
      );

      if (proceed != true) return false;

      final requested = await Permission.notification.request();
      if (!mounted) return false;

      if (requested.isGranted) {
        setState(() {
          _permanentlyDenied = false;
          _permissionNote = 'Local notifications enabled!';
        });
        return true;
      } else if (requested.isPermanentlyDenied) {
        setState(() {
          _permanentlyDenied = true;
          _permissionNote =
              'Notifications are turned off in system settings. You can still use all tracking features or open Settings to enable alerts.';
        });
        return false;
      } else {
        setState(() {
          _permanentlyDenied = false;
          _permissionNote =
              'Notification permission was declined. FitNepal remains 100% usable without reminders.';
        });
        return false;
      }
    } catch (_) {
      return true;
    }
  }

  Future<void> _toggleReminder(ReminderConfig item, bool newValue) async {
    if (newValue) {
      await _ensureNotificationPermissionContextual();
    }
    await ref
        .read(appDatabaseProvider)
        .saveReminder(item.copyWith(enabled: newValue));
    if (newValue) {
      await LocalNotificationHelper.showTestReminderNotification(
        title: item.reminderType == 'water'
            ? 'Hydration Reminder Active 💧'
            : 'Meal Logging Reminder Active 🍛',
        body:
            'Scheduled every ${item.intervalMinutes} mins (${item.formattedWindow})',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);
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
              'Local Meal & Water Reminders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scheduled 100% offline on your device. No push servers.',
              style: TextStyle(color: FitNepalColors.mutedPlum, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (_permissionNote != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FitNepalColors.softPinkFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionNote!,
                      style: const TextStyle(
                        color: FitNepalColors.deepPlum,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_permanentlyDenied) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => openAppSettings(),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Open Android Settings'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            remindersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (items) {
                return Column(
                  children: items.map((item) {
                    final isWater = item.reminderType == 'water';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FitNepalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isWater
                                      ? Icons.water_drop_rounded
                                      : Icons.restaurant_rounded,
                                  color: isWater
                                      ? FitNepalColors.waterBlue
                                      : FitNepalColors.berryRed,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isWater
                                            ? 'Hydration Reminder'
                                            : 'Meal Logging Reminder',
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Window: ${item.formattedWindow} • Every ${item.intervalMinutes ~/ 60}h',
                                        style: const TextStyle(
                                          color: FitNepalColors.mutedPlum,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: item.enabled,
                                  activeColor: FitNepalColors.berryRed,
                                  onChanged: (val) =>
                                      _toggleReminder(item, val),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final mins in const [60, 120, 180, 300])
                                  ChoiceChip(
                                    label: Text('Every ${mins ~/ 60}h'),
                                    selected: item.intervalMinutes == mins,
                                    onSelected: (_) {
                                      ref
                                          .read(appDatabaseProvider)
                                          .saveReminder(
                                            item.copyWith(
                                              intervalMinutes: mins,
                                            ),
                                          );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
