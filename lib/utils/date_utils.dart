import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _displayTimeFormat = DateFormat('hh:mm a');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  
  static String formatDisplayDate(String dateStr) {
    try {
      final DateTime dt = _dateFormat.parse(dateStr);
      return _displayDateFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatRelativeDate(String dateStr) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dt = _dateFormat.parse(dateStr);
      final target = DateTime(dt.year, dt.month, dt.day);

      final diffDays = target.difference(today).inDays;

      if (diffDays == 0) return 'Today';
      if (diffDays == 1) return 'Tomorrow';
      return _displayDateFormat.format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDisplayTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final dt = DateTime(2026, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return _displayTimeFormat.format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  static DateTime combineDateAndTime(String dateStr, String timeStr) {
    final dParts = dateStr.split('-');
    final tParts = timeStr.split(':');
    return DateTime(
      int.parse(dParts[0]),
      int.parse(dParts[1]),
      int.parse(dParts[2]),
      int.parse(tParts[0]),
      int.parse(tParts[1]),
    );
  }

  static bool isSameDay(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }

  static bool isToday(String dateStr) {
    final now = DateTime.now();
    return dateStr == formatDate(now);
  }

  static bool isOverdue(String dateStr, String timeStr, bool isCompleted) {
    if (isCompleted) return false;
    try {
      final dueDateTime = combineDateAndTime(dateStr, timeStr);
      return dueDateTime.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
