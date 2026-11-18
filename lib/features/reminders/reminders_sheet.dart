import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';
import '../../database/models.dart';

class ReminderToneOption {
  final String id;
  final String nameEn;
  final String nameNe;
  final String descriptionEn;
  final List<int> vibrationPatternMs;
  final IconData icon;

  const ReminderToneOption({
    required this.id,
    required this.nameEn,
    required this.nameNe,
    required this.descriptionEn,
    required this.vibrationPatternMs,
    required this.icon,
  });
}

class LocalNotificationHelper {
  LocalNotificationHelper._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const List<ReminderToneOption> inbuiltTones = [
    ReminderToneOption(
      id: 'singing_bowl',
      nameEn: 'Himalayan Singing Bowl',
      nameNe: 'हिमालयन सिङ्गिङ बाउल',
      descriptionEn: 'Deep resonant meditation chime with gentle pulse',
      vibrationPatternMs: [0, 180, 120, 320],
      icon: Icons.spa_rounded,
    ),
    ReminderToneOption(
      id: 'temple_bell',
      nameEn: 'Pashupati Temple Bell',
      nameNe: 'मन्दिरको घण्टी',
      descriptionEn: 'Crisp double metallic bell ring',
      vibrationPatternMs: [0, 90, 80, 90, 80, 220],
      icon: Icons.notifications_active_rounded,
    ),
    ReminderToneOption(
      id: 'mountain_drop',
      nameEn: 'Mountain Water Drop',
      nameNe: 'हिमाली पानीको थोपा',
      descriptionEn: 'Light refreshing hydration cascade',
      vibrationPatternMs: [0, 60, 60, 120],
      icon: Icons.water_drop_rounded,
    ),
    ReminderToneOption(
      id: 'bansuri_flute',
      nameEn: 'Nepali Bansuri Chime',
      nameNe: 'बाँसुरीको धुन',
      descriptionEn: 'Soft melodic triple cadence',
      vibrationPatternMs: [0, 140, 90, 140, 90, 180],
      icon: Icons.music_note_rounded,
    ),
    ReminderToneOption(
      id: 'morning_dawn',
      nameEn: 'Everest Sunrise Alert',
      nameNe: 'सगरमाथा बिहानी अलर्ट',
      descriptionEn: 'Bright energetic morning alert pattern',
      vibrationPatternMs: [0, 200, 100, 200, 100, 350],
      icon: Icons.wb_sunny_rounded,
    ),
    ReminderToneOption(
      id: 'gentle_zen',
      nameEn: 'Silent Zen Haptic',
      nameNe: 'शान्त भाइब्रेसन मात्र',
      descriptionEn: 'Subtle single tactile tap',
      vibrationPatternMs: [0, 70],
      icon: Icons.vibration_rounded,
    ),
  ];

  static ReminderToneOption resolveTone(String? id) {
    return inbuiltTones.firstWhere(
      (t) => t.id == id,
      orElse: () => inbuiltTones.first,
    );
  }

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {}
  }

  /// Plays an instant tactile + system sound preview for the selected inbuilt tone.
  static Future<void> previewTone(String toneId) async {
    try {
      final tone = resolveTone(toneId);
      await SystemSound.play(SystemSoundType.alert);
      await SystemSound.play(SystemSoundType.click);
      for (var i = 1; i < tone.vibrationPatternMs.length; i += 2) {
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(
          Duration(milliseconds: tone.vibrationPatternMs[i].clamp(40, 250)),
        );
      }
    } catch (_) {}
  }

  /// Pushes a real-time Android status bar notification immediately with the chosen inbuilt tone.
  static Future<void> pushRealtimeNotification({
    required String title,
    required String body,
    String toneId = 'singing_bowl',
    int notificationId = 501,
  }) async {
    try {
      await ensureInitialized();
      final tone = resolveTone(toneId);
      final isSilent = tone.id == 'gentle_zen';

      final androidDetails = AndroidNotificationDetails(
        'fitnepal_v5_${tone.id}',
        'FitNepal • ${tone.nameEn}',
        channelDescription: tone.descriptionEn,
        importance: Importance.max,
        priority: Priority.high,
        playSound: !isSilent,
        enableVibration: true,
        ticker: title,
      );
      await _plugin.show(
        notificationId,
        title,
        '$body • 🔔 ${tone.nameEn}',
        NotificationDetails(android: androidDetails),
      );
      await previewTone(toneId);
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
  String _selectedToneId = 'singing_bowl';
  bool _realtimePushOnLog = true;

  @override
  void initState() {
    super.initState();
    _loadSavedToneSettings();
  }

  Future<void> _loadSavedToneSettings() async {
    final db = ref.read(appDatabaseProvider);
    final savedTone = await db.getAppSetting('reminder_tone_id');
    final savedRealtime = await db.getAppSetting('realtime_push_on_log');
    if (mounted) {
      setState(() {
        if (savedTone != null && savedTone.isNotEmpty) {
          _selectedToneId = savedTone;
        }
        if (savedRealtime != null) {
          _realtimePushOnLog = savedRealtime != 'false';
        }
      });
    }
  }

  Future<bool> _ensureNotificationPermissionContextual() async {
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;

      if (!mounted) return false;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Real-Time Notifications?'),
          content: const Text(
            'FitNepal v5.0 Elite triggers real-time meal, water, and goal alerts locally on your device with your chosen inbuilt reminder tone. '
            'No external servers are ever used.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
          _permissionNote = 'Real-time notifications enabled!';
        });
        return true;
      } else if (requested.isPermanentlyDenied) {
        setState(() {
          _permanentlyDenied = true;
          _permissionNote =
              'Notifications are disabled in Android Settings. Tap Open Settings below to enable them.';
        });
        return false;
      } else {
        setState(() {
          _permanentlyDenied = false;
          _permissionNote =
              'Notification permission declined. FitNepal continues to work normally.';
        });
        return false;
      }
    } catch (_) {
      return true;
    }
  }

  Future<void> _selectTone(String toneId) async {
    setState(() => _selectedToneId = toneId);
    await ref
        .read(appDatabaseProvider)
        .setAppSetting('reminder_tone_id', toneId);
    await LocalNotificationHelper.previewTone(toneId);
  }

  Future<void> _toggleReminder(ReminderConfig item, bool newValue) async {
    if (newValue) {
      await _ensureNotificationPermissionContextual();
    }
    await ref
        .read(appDatabaseProvider)
        .saveReminder(item.copyWith(enabled: newValue));
    if (newValue) {
      await LocalNotificationHelper.pushRealtimeNotification(
        title: item.reminderType == 'water'
            ? 'Hydration Reminder Active 💧'
            : 'Meal Logging Reminder Active 🍛',
        body:
            'Every ${item.intervalMinutes ~/ 60}h (${item.formattedWindow})',
        toneId: _selectedToneId,
      );
    }
  }

  Future<void> _sendInstantTestPush() async {
    await _ensureNotificationPermissionContextual();
    final tone = LocalNotificationHelper.resolveTone(_selectedToneId);
    await LocalNotificationHelper.pushRealtimeNotification(
      title: 'FitNepal v5.0 Elite • Live Push 🇳🇵',
      body: 'Real-time alert tested with "${tone.nameEn}" tone!',
      toneId: _selectedToneId,
      notificationId: DateTime.now().millisecondsSinceEpoch % 10000,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sent real-time push notification with ${tone.nameEn} tone!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(liveProfileProvider);
    final lang = profile.language;
    final remindersAsync = ref.watch(remindersProvider);
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FitNepalStrings.tr(
                          lang,
                          'Real-Time Notifications & Tones',
                          'सूचना तथा इनबिल्ट रिमाइन्डर टोन',
                        ),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        FitNepalStrings.tr(
                          lang,
                          'Instant on-device push alerts & 6 inbuilt Nepali tones',
                          '६ वटा इनबिल्ट नेपाली टोन र तुरुन्तै पुस नोटिफिकेसन',
                        ),
                        style: const TextStyle(
                          color: FitNepalColors.mutedPlum,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sendInstantTestPush,
                  icon: const Icon(Icons.notifications_active_rounded, size: 16),
                  label: Text(
                    FitNepalStrings.tr(lang, 'Test Push', 'टेस्ट पुस'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_permissionNote != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionNote!,
                      style: const TextStyle(
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

            // Real-time push on meal/water logging toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: primaryColor,
              title: Text(
                FitNepalStrings.tr(
                  lang,
                  'Real-Time Push Alert on Food & Water Log',
                  'खाना र पानी थप्दा तुरुन्तै पुस नोटिफिकेसन',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                FitNepalStrings.tr(
                  lang,
                  'Posts an immediate status bar update whenever you log meals or hydration',
                  'खाना वा पानी रेकर्ड गर्दा स्टाटस बारमा तुरुन्तै जानकारी देखाउँछ',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: FitNepalColors.mutedPlum,
                ),
              ),
              value: _realtimePushOnLog,
              onChanged: (val) async {
                setState(() => _realtimePushOnLog = val);
                await ref
                    .read(appDatabaseProvider)
                    .setAppSetting('realtime_push_on_log', val.toString());
              },
            ),
            const Divider(height: 18),

            // 6 Inbuilt Reminder Tones Selector
            Text(
              FitNepalStrings.tr(
                lang,
                'Inbuilt Reminder Tones (Tap to Preview & Select)',
                'इनबिल्ट रिमाइन्डर टोन छान्नुहोस्',
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LocalNotificationHelper.inbuiltTones.map((tone) {
                final isSelected = _selectedToneId == tone.id;
                return InkWell(
                  onTap: () => _selectTone(tone.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : FitNepalColors.roseBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tone.icon,
                          size: 16,
                          color: isSelected
                              ? primaryColor
                              : FitNepalColors.mutedPlum,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang == 'ne' ? tone.nameNe : tone.nameEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected ? primaryColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Scheduled Meal & Water Reminder Rules
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
                                      : primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isWater
                                            ? FitNepalStrings.tr(
                                                lang,
                                                'Hydration Reminder',
                                                'पानी पिउने रिमाइन्डर',
                                              )
                                            : FitNepalStrings.tr(
                                                lang,
                                                'Meal Logging Reminder',
                                                'खाना टिप्ने रिमाइन्डर',
                                              ),
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
                                  activeColor: primaryColor,
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
