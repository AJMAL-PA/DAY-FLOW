import '../models/recurrence.dart';

class RecurrenceEngine {
  static DateTime calculateNextDueDate(DateTime currentDueDate, Recurrence recurrence) {
    switch (recurrence.type) {
      case RecurrenceType.daily:
        return currentDueDate.add(const Duration(days: 1));

      case RecurrenceType.weekdays:
        DateTime next = currentDueDate.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case RecurrenceType.weekly:
        return currentDueDate.add(const Duration(days: 7));

      case RecurrenceType.monthly:
        int year = currentDueDate.year;
        int month = currentDueDate.month + 1;
        if (month > 12) {
          month = 1;
          year++;
        }
        int day = currentDueDate.day;
        int daysInNextMonth = DateTime(year, month + 1, 0).day;
        if (day > daysInNextMonth) {
          day = daysInNextMonth;
        }
        return DateTime(year, month, day, currentDueDate.hour, currentDueDate.minute);

      case RecurrenceType.custom:
        if (recurrence.customDays.isEmpty) {
          return currentDueDate.add(const Duration(days: 1));
        }
        DateTime candidate = currentDueDate.add(const Duration(days: 1));
        for (int i = 0; i < 7; i++) {
          // Convert DateTime.weekday (1=Mon..7=Sun) to 0=Sun..6=Sat format
          int dayOfWeek = candidate.weekday == 7 ? 0 : candidate.weekday;
          if (recurrence.customDays.contains(dayOfWeek)) {
            return candidate;
          }
          candidate = candidate.add(const Duration(days: 1));
        }
        return currentDueDate.add(const Duration(days: 1));

      case RecurrenceType.none:
        return currentDueDate;
    }
  }
}
