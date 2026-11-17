import 'package:intl/intl.dart';

class LocalDateHelpers {
  LocalDateHelpers._();

  /// Returns local midnight (00:00:00.000) for [date].
  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Returns exclusive end of local calendar day (next day 00:00:00.000).
  /// Uses calendar arithmetic (`day + 1`) rather than `Duration(days: 1)`
  /// so DST or timezone transitions never drift off midnight.
  static DateTime endOfDayExclusive(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day + 1);
  }

  /// Epoch millisecond bounds `[startMs, endMs)` for the local calendar day.
  static ({int startMs, int endMs}) dayBoundsEpochMs(DateTime date) {
    final start = startOfDay(date);
    final end = endOfDayExclusive(date);
    return (
      startMs: start.millisecondsSinceEpoch,
      endMs: end.millisecondsSinceEpoch,
    );
  }

  /// Stable `YYYY-MM-DD` key in local time.
  static String dateKey(DateTime date) {
    final d = startOfDay(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static bool isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static bool isToday(DateTime date) => isSameLocalDay(date, DateTime.now());

  /// Returns Monday..Sunday (7 local dates) for the week containing [anchor].
  static List<DateTime> weekDaysMondayToSunday(DateTime anchor) {
    final d = startOfDay(anchor);
    final mondayOffset = d.weekday - DateTime.monday;
    final monday = DateTime(d.year, d.month, d.day - mondayOffset);
    return List<DateTime>.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  /// Returns the last [count] local calendar days ending at [anchor].
  static List<DateTime> trailingDays(DateTime anchor, int count) {
    final end = startOfDay(anchor);
    return List<DateTime>.generate(
      count,
      (i) => DateTime(end.year, end.month, end.day - (count - 1 - i)),
    );
  }

  static String formatFriendlyDate(DateTime date) {
    if (isToday(date)) return 'Today';
    final yesterday =
        startOfDay(DateTime.now()).subtract(const Duration(days: 1));
    if (isSameLocalDay(date, yesterday)) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(date.toLocal());
  }

  static String formatShortWeekday(DateTime date) {
    return DateFormat('EEE').format(date.toLocal());
  }

  static String formatNumber(num value) {
    return NumberFormat.decimalPattern().format(value);
  }
}
