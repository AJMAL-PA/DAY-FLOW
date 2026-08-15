import 'package:intl/intl.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final String? reminderTime; // e.g. '08:00'
  final bool reminderEnabled;
  final String category; // e.g. 'Health', 'Fitness', 'Study', 'Hydration', 'General'
  final String targetQuantity; // e.g. '1 pill', '8 glasses', '30 mins'
  final String? reminderLastFiredDate; // 'yyyy-MM-dd' to avoid double alarms
  final List<String> completionHistory; // List of 'yyyy-MM-dd'
  final int currentStreak;
  final int bestStreak;
  final String createdAt;

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.reminderTime,
    this.reminderEnabled = true,
    this.category = 'General',
    this.targetQuantity = '1 time',
    this.reminderLastFiredDate,
    this.completionHistory = const [],
    required this.currentStreak,
    required this.bestStreak,
    required this.createdAt,
  });

  factory Habit.create({
    required String id,
    required String name,
    String description = '',
    String? reminderTime,
    bool reminderEnabled = true,
    String category = 'General',
    String targetQuantity = '1 time',
  }) {
    final nowStr = DateTime.now().toIso8601String();
    return Habit(
      id: id,
      name: name,
      description: description,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      category: category,
      targetQuantity: targetQuantity,
      completionHistory: [],
      currentStreak: 0,
      bestStreak: 0,
      createdAt: nowStr,
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? reminderTime,
    bool? reminderEnabled,
    String? category,
    String? targetQuantity,
    String? reminderLastFiredDate,
    List<String>? completionHistory,
    int? currentStreak,
    int? bestStreak,
    String? createdAt,
  }) {
    final updatedHistory = completionHistory ?? this.completionHistory;
    final streaks = _calculateStreaks(updatedHistory);
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      category: category ?? this.category,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      reminderLastFiredDate: reminderLastFiredDate ?? this.reminderLastFiredDate,
      completionHistory: updatedHistory,
      currentStreak: streaks['current']!,
      bestStreak: streaks['best']!,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'reminderTime': reminderTime,
        'reminderEnabled': reminderEnabled,
        'category': category,
        'targetQuantity': targetQuantity,
        'reminderLastFiredDate': reminderLastFiredDate,
        'completionHistory': completionHistory,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'createdAt': createdAt,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final history = List<String>.from(json['completionHistory'] ?? []);
    final streaks = _calculateStreaks(history);
    return Habit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      reminderTime: json['reminderTime'],
      reminderEnabled: json['reminderEnabled'] ?? true,
      category: json['category'] ?? 'General',
      targetQuantity: json['targetQuantity'] ?? '1 time',
      reminderLastFiredDate: json['reminderLastFiredDate'],
      completionHistory: history,
      currentStreak: streaks['current']!,
      bestStreak: streaks['best']!,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  static Map<String, int> _calculateStreaks(List<String> history) {
    if (history.isEmpty) {
      return {'current': 0, 'best': 0};
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final Set<DateTime> dates = history
        .map((d) {
          try {
            return formatter.parse(d);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet();

    if (dates.isEmpty) {
      return {'current': 0, 'best': 0};
    }

    final List<DateTime> sortedDates = dates.toList()..sort();

    int maxStreak = 0;
    int currentStreakCount = 0;

    DateTime today = DateTime.now();
    DateTime todayNormalized = DateTime(today.year, today.month, today.day);
    DateTime yesterdayNormalized = todayNormalized.subtract(const Duration(days: 1));

    int tempStreak = 0;
    DateTime? prevDate;
    for (final d in sortedDates) {
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diff = d.difference(prevDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > maxStreak) {
        maxStreak = tempStreak;
      }
      prevDate = d;
    }

    if (dates.contains(todayNormalized) || dates.contains(yesterdayNormalized)) {
      DateTime checkDate = dates.contains(todayNormalized) ? todayNormalized : yesterdayNormalized;
      while (dates.contains(checkDate)) {
        currentStreakCount++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      currentStreakCount = 0;
    }

    return {
      'current': currentStreakCount,
      'best': maxStreak > currentStreakCount ? maxStreak : currentStreakCount,
    };
  }
}
