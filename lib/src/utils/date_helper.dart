import 'package:intl/intl.dart';

/// Utility functions for date and time operations
class DateTimeHelper {
  /// Format timestamp to display date
  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format timestamp to display date and time
  static String formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd MMM yyyy hh:mm a').format(date);
  }

  /// Format timestamp for export (YYYY-MM-DD)
  static String formatDateForExport(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Get start of day timestamp
  static int getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
  }

  /// Get end of day timestamp
  static int getEndOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
  }

  /// Get current timestamp
  static int now() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Get timestamp for a specific date
  static int fromDate(DateTime date) {
    return date.millisecondsSinceEpoch;
  }

  /// Convert timestamp to DateTime
  static DateTime toDateTime(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Get start of current month
  static int getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  }

  /// Get end of current month
  static int getEndOfMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return getEndOfDay(lastDay);
  }

  /// Get timestamp for days ago
  static int daysAgo(int days) {
    return DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
  }

  /// Check if timestamp is today
  static bool isToday(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}
