import 'dart:convert';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/settings.dart';

class BackupData {
  final List<Task> tasks;
  final List<Habit> habits;
  final AppSettings settings;
  final String exportedAt;
  final String version;

  BackupData({
    required this.tasks,
    required this.habits,
    required this.settings,
    required this.exportedAt,
    this.version = '1.0.0',
  });
}

class BackupService {
  static String exportToJson({
    required List<Task> tasks,
    required List<Habit> habits,
    required AppSettings settings,
  }) {
    final Map<String, dynamic> backupMap = {
      'appName': 'DAY FLOW',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'habits': habits.map((h) => h.toJson()).toList(),
      'settings': settings.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  static BackupData parseFromJson(String jsonString) {
    final Map<String, dynamic> map = jsonDecode(jsonString);

    if (map['appName'] != 'DAY FLOW' && map['tasks'] == null) {
      throw Exception('Invalid backup format: Missing DAY FLOW structure.');
    }

    final tasksList = (map['tasks'] as List<dynamic>?)
            ?.map((t) => Task.fromJson(t))
            .toList() ??
        [];

    final habitsList = (map['habits'] as List<dynamic>?)
            ?.map((h) => Habit.fromJson(h))
            .toList() ??
        [];

    final settingsObj = map['settings'] != null
        ? AppSettings.fromJson(map['settings'])
        : const AppSettings();

    return BackupData(
      tasks: tasksList,
      habits: habitsList,
      settings: settingsObj,
      exportedAt: map['exportedAt'] ?? DateTime.now().toIso8601String(),
      version: map['version'] ?? '1.0.0',
    );
  }
}
