import 'package:flutter_test/flutter_test.dart';
import 'package:day_flow/models/recurrence.dart';
import 'package:day_flow/models/habit.dart';
import 'package:day_flow/models/task.dart';
import 'package:day_flow/utils/date_utils.dart';
import 'package:day_flow/utils/recurrence_engine.dart';

void main() {
  group('DAY FLOW Date Utils Relative Date Tests', () {
    test('Format relative date for today and tomorrow', () {
      final now = DateTime.now();
      final todayStr = AppDateUtils.formatDate(now);
      final tomorrowStr = AppDateUtils.formatDate(now.add(const Duration(days: 1)));
      final futureStr = AppDateUtils.formatDate(now.add(const Duration(days: 10)));

      expect(AppDateUtils.formatRelativeDate(todayStr), 'Today');
      expect(AppDateUtils.formatRelativeDate(tomorrowStr), 'Tomorrow');
      expect(AppDateUtils.formatRelativeDate(futureStr).contains(now.year.toString()), true);
    });
  });

  group('DAY FLOW Recurrence Engine Tests', () {
    test('Daily recurrence adds 1 day', () {
      final start = DateTime(2026, 8, 15);
      final recurrence = const Recurrence(type: RecurrenceType.daily);
      final next = RecurrenceEngine.calculateNextDueDate(start, recurrence);
      expect(next, DateTime(2026, 8, 16));
    });

    test('Weekly recurrence adds 7 days', () {
      final start = DateTime(2026, 8, 15);
      final recurrence = const Recurrence(type: RecurrenceType.weekly);
      final next = RecurrenceEngine.calculateNextDueDate(start, recurrence);
      expect(next, DateTime(2026, 8, 22));
    });
  });

  group('DAY FLOW Habit Streak & Daily Reminder Tests', () {
    test('Habit calculates streak correctly', () {
      final habit = Habit.create(id: '1', name: 'Exercise');
      expect(habit.currentStreak, 0);
      expect(habit.bestStreak, 0);

      final updated = habit.copyWith(completionHistory: ['2026-08-14', '2026-08-15']);
      expect(updated.currentStreak, 2);
      expect(updated.bestStreak, 2);
    });

    test('Habit daily reminder and JSON roundtrip', () {
      final habit = Habit.create(
        id: 'h-100',
        name: 'Take Medicines',
        category: 'Health',
        targetQuantity: '1 pill',
        reminderTime: '08:00',
        reminderEnabled: true,
      );

      final json = habit.toJson();
      final restored = Habit.fromJson(json);

      expect(restored.id, 'h-100');
      expect(restored.name, 'Take Medicines');
      expect(restored.category, 'Health');
      expect(restored.reminderTime, '08:00');
      expect(restored.reminderEnabled, true);
    });
  });

  group('DAY FLOW Task Model Tests', () {
    test('Task JSON serialization roundtrip', () {
      final task = Task(
        id: 'task-123',
        title: 'Complete Project',
        description: 'Test description',
        priority: Priority.high,
        dueDate: '2026-08-15',
        dueTime: '14:30',
        createdAt: '2026-08-15T00:00:00.000',
        updatedAt: '2026-08-15T00:00:00.000',
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, 'task-123');
      expect(restored.title, 'Complete Project');
      expect(restored.priority, Priority.high);
    });
  });
}
