enum RecurrenceType { none, daily, weekdays, weekly, monthly, custom }

class Recurrence {
  final RecurrenceType type;
  final List<int> customDays; // 0=Sun, 1=Mon, ..., 6=Sat

  const Recurrence({
    this.type = RecurrenceType.none,
    this.customDays = const [],
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'customDays': customDays,
      };

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      type: RecurrenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      customDays: List<int>.from(json['customDays'] ?? []),
    );
  }

  String get label {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekdays:
        return 'Mon-Fri';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.custom:
        final daysStr = customDays.map((d) => _dayName(d)).join(', ');
        return 'Custom ($daysStr)';
      case RecurrenceType.none:
        return 'None';
    }
  }

  static String _dayName(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return 'Sun';
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      default:
        return '';
    }
  }
}
