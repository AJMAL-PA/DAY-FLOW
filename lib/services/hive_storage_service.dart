import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/settings.dart';

class HiveStorageService {
  static const String _tasksBoxName = 'dayflow_tasks';
  static const String _habitsBoxName = 'dayflow_habits';
  static const String _settingsBoxName = 'dayflow_settings';

  static late Box<String> _tasksBox;
  static late Box<String> _habitsBox;
  static late Box<String> _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _tasksBox = await Hive.openBox<String>(_tasksBoxName);
    _habitsBox = await Hive.openBox<String>(_habitsBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // --- TASKS ---
  static List<Task> loadTasks() {
    final List<Task> tasks = [];
    for (var key in _tasksBox.keys) {
      final jsonStr = _tasksBox.get(key);
      if (jsonStr != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          tasks.add(Task.fromJson(map));
        } catch (_) {}
      }
    }
    return tasks;
  }

  static Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, jsonEncode(task.toJson()));
  }

  static Future<void> deleteTask(String taskId) async {
    await _tasksBox.delete(taskId);
  }

  static Future<void> saveAllTasks(List<Task> tasks) async {
    await _tasksBox.clear();
    for (var task in tasks) {
      await _tasksBox.put(task.id, jsonEncode(task.toJson()));
    }
  }

  // --- HABITS ---
  static List<Habit> loadHabits() {
    final List<Habit> habits = [];
    for (var key in _habitsBox.keys) {
      final jsonStr = _habitsBox.get(key);
      if (jsonStr != null) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          habits.add(Habit.fromJson(map));
        } catch (_) {}
      }
    }
    return habits;
  }

  static Future<void> saveHabit(Habit habit) async {
    await _habitsBox.put(habit.id, jsonEncode(habit.toJson()));
  }

  static Future<void> deleteHabit(String habitId) async {
    await _habitsBox.delete(habitId);
  }

  static Future<void> saveAllHabits(List<Habit> habits) async {
    await _habitsBox.clear();
    for (var habit in habits) {
      await _habitsBox.put(habit.id, jsonEncode(habit.toJson()));
    }
  }

  // --- SETTINGS ---
  static AppSettings loadSettings() {
    final jsonStr = _settingsBox.get('current_settings');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return AppSettings.fromJson(map);
      } catch (_) {}
    }
    return const AppSettings();
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('current_settings', jsonEncode(settings.toJson()));
  }

  // --- RESET DATA ---
  static Future<void> clearAllData() async {
    await _tasksBox.clear();
    await _habitsBox.clear();
    await _settingsBox.clear();
  }
}
