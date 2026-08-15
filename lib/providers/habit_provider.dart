import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/hive_storage_service.dart';
import '../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];

  List<Habit> get habits => List.unmodifiable(_habits);

  HabitProvider() {
    loadHabits();
  }

  void loadHabits() {
    _habits = HiveStorageService.loadHabits();
    _rescheduleAllHabitNotifications();
    notifyListeners();
  }

  Future<void> _rescheduleAllHabitNotifications() async {
    for (var habit in _habits) {
      if (habit.reminderTime != null && habit.reminderEnabled) {
        await NotificationService.scheduleHabitReminder(habit);
      }
    }
  }

  Future<void> createFullHabit(Habit habit) async {
    _habits.add(habit);
    await HiveStorageService.saveHabit(habit);
    if (habit.reminderTime != null && habit.reminderEnabled) {
      await NotificationService.scheduleHabitReminder(habit);
    }
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    String description = '',
    String? reminderTime,
    bool reminderEnabled = true,
    String category = 'General',
    String targetQuantity = '1 time',
  }) async {
    final newHabit = Habit.create(
      id: const Uuid().v4(),
      name: name,
      description: description,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      category: category,
      targetQuantity: targetQuantity,
    );
    await createFullHabit(newHabit);
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      await HiveStorageService.saveHabit(habit);

      if (habit.reminderTime != null && habit.reminderEnabled) {
        await NotificationService.scheduleHabitReminder(habit);
      } else {
        await NotificationService.cancelHabitReminder(habit.id);
      }

      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    await HiveStorageService.deleteHabit(habitId);
    await NotificationService.cancelHabitReminder(habitId);
    notifyListeners();
  }

  Future<void> toggleHabitDate(String habitId, String dateStr) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      final List<String> newHistory = List.from(habit.completionHistory);
      if (newHistory.contains(dateStr)) {
        newHistory.remove(dateStr);
      } else {
        newHistory.add(dateStr);
      }
      final updatedHabit = habit.copyWith(completionHistory: newHistory);
      _habits[index] = updatedHabit;
      await HiveStorageService.saveHabit(updatedHabit);
      notifyListeners();
    }
  }

  Future<void> markHabitCompletedForDate(String habitId, String dateStr) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      if (!habit.completionHistory.contains(dateStr)) {
        final newHistory = List<String>.from(habit.completionHistory)..add(dateStr);
        final updatedHabit = habit.copyWith(completionHistory: newHistory);
        _habits[index] = updatedHabit;
        await HiveStorageService.saveHabit(updatedHabit);
        notifyListeners();
      }
    }
  }

  Future<void> replaceAllHabits(List<Habit> newHabits) async {
    _habits = List.from(newHabits);
    await HiveStorageService.saveAllHabits(_habits);
    _rescheduleAllHabitNotifications();
    notifyListeners();
  }
}
