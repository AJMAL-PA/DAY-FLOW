enum ReminderStatus { scheduled, triggered, snoozed, completed, cancelled, expired }

class Reminder {
  final String id;
  final int offsetMinutes; // e.g. 0 = at event time, -5 = 5m before, +5 = 5m after
  final String fireAt; // ISO timestamp
  final ReminderStatus status;
  final int snoozeCount;

  Reminder({
    required this.id,
    required this.offsetMinutes,
    required this.fireAt,
    this.status = ReminderStatus.scheduled,
    this.snoozeCount = 0,
  });

  Reminder copyWith({
    String? id,
    int? offsetMinutes,
    String? fireAt,
    ReminderStatus? status,
    int? snoozeCount,
  }) {
    return Reminder(
      id: id ?? this.id,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      fireAt: fireAt ?? this.fireAt,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'offsetMinutes': offsetMinutes,
        'fireAt': fireAt,
        'status': status.name,
        'snoozeCount': snoozeCount,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] ?? '',
      offsetMinutes: json['offsetMinutes'] ?? 0,
      fireAt: json['fireAt'] ?? DateTime.now().toIso8601String(),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      snoozeCount: json['snoozeCount'] ?? 0,
    );
  }

  String get offsetLabel {
    if (offsetMinutes == 0) return 'At time of event';
    final absVal = offsetMinutes.abs();
    final isAfter = offsetMinutes > 0;
    final suffix = isAfter ? 'after' : 'before';

    if (absVal < 60) return '$absVal min $suffix';
    if (absVal < 1440) return '${absVal ~/ 60} hr $suffix';
    return '${absVal ~/ 1440} day(s) $suffix';
  }
}
