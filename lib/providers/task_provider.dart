import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/recurrence.dart';
import '../models/reminder.dart';
import '../utils/date_utils.dart';
import '../utils/recurrence_engine.dart';
import '../services/hive_storage_service.dart';
import '../services/notification_service.dart';
import 'habit_provider.dart';

enum TaskFilterCategory { all, today, upcoming, overdue, completed }

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  TaskFilterCategory _selectedCategory = TaskFilterCategory.all;
  Priority? _selectedPriority;
  String _searchQuery = '';

  List<Task> get tasks => List.unmodifiable(_tasks);
  TaskFilterCategory get selectedCategory => _selectedCategory;
  Priority? get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;

  TaskProvider() {
    loadTasks();
  }

  void loadTasks() {
    _tasks = HiveStorageService.loadTasks();
    _checkOverdueTasks();
    notifyListeners();
  }

  void setFilterCategory(TaskFilterCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setPriorityFilter(Priority? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Task> get filteredTasks {
    final nowStr = AppDateUtils.formatDate(DateTime.now());

    return _tasks.where((task) {
      // Search Filter
      if (_searchQuery.isNotEmpty) {
        final titleMatch = task.title.toLowerCase().contains(_searchQuery);
        final descMatch = task.description.toLowerCase().contains(_searchQuery);
        if (!titleMatch && !descMatch) return false;
      }

      // Priority Filter
      if (_selectedPriority != null && task.priority != _selectedPriority) {
        return false;
      }

      // Category Filter
      switch (_selectedCategory) {
        case TaskFilterCategory.today:
          return task.dueDate == nowStr ||
              (task.status == TaskStatus.completed && task.completedAt != null && task.completedAt!.startsWith(nowStr));
        case TaskFilterCategory.upcoming:
          return task.dueDate.compareTo(nowStr) > 0;
        case TaskFilterCategory.overdue:
          return task.status == TaskStatus.overdue ||
              AppDateUtils.isOverdue(task.dueDate, task.dueTime, false) ||
              (task.status == TaskStatus.completed && task.dueDate.compareTo(nowStr) < 0);
        case TaskFilterCategory.completed:
          return task.status == TaskStatus.completed;
        case TaskFilterCategory.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => '${a.dueDate} ${a.dueTime}'.compareTo('${b.dueDate} ${b.dueTime}'));
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await HiveStorageService.saveTask(task);
    _scheduleNotificationsForTask(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      await HiveStorageService.saveTask(task);
      _scheduleNotificationsForTask(task);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId, orElse: () => Task(id: '', title: '', dueDate: '', dueTime: '', createdAt: '', updatedAt: ''));
    for (var r in task.reminders) {
      await NotificationService.cancelReminder(task.id, r.id);
    }
    _tasks.removeWhere((t) => t.id == taskId);
    await HiveStorageService.deleteTask(taskId);
    notifyListeners();
  }

  Future<void> toggleTaskStatus(String taskId, {HabitProvider? habitProvider}) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    final isNowCompleted = task.status != TaskStatus.completed;
    final nowIso = DateTime.now().toIso8601String();

    final updatedTask = task.copyWith(
      status: isNowCompleted ? TaskStatus.completed : TaskStatus.pending,
      completedAt: isNowCompleted ? nowIso : null,
      updatedAt: nowIso,
    );

    _tasks[index] = updatedTask;
    await HiveStorageService.saveTask(updatedTask);

    // Link Habit update
    if (isNowCompleted && task.habitId != null && habitProvider != null) {
      await habitProvider.markHabitCompletedForDate(task.habitId!, task.dueDate);
    }

    // Spawn Next Occurrence if recurring & marked completed
    if (isNowCompleted && task.recurrence.type != RecurrenceType.none) {
      await _spawnNextOccurrence(task);
    }

    notifyListeners();
  }

  Future<void> _spawnNextOccurrence(Task currentTask) async {
    final currentDt = AppDateUtils.combineDateAndTime(currentTask.dueDate, currentTask.dueTime);
    final nextDt = RecurrenceEngine.calculateNextDueDate(currentDt, currentTask.recurrence);
    final nextDateStr = AppDateUtils.formatDate(nextDt);
    final nextTimeStr = AppDateUtils.formatTime(nextDt);

    final String nextTaskId = const Uuid().v4();
    final nowIso = DateTime.now().toIso8601String();

    final List<Reminder> freshReminders = currentTask.reminders.map((r) {
      final fireDt = nextDt.add(Duration(minutes: r.offsetMinutes));
      return r.copyWith(
        id: const Uuid().v4(),
        fireAt: fireDt.toIso8601String(),
        status: ReminderStatus.scheduled,
        snoozeCount: 0,
      );
    }).toList();

    final nextTask = Task(
      id: nextTaskId,
      title: currentTask.title,
      description: currentTask.description,
      priority: currentTask.priority,
      dueDate: nextDateStr,
      dueTime: nextTimeStr,
      status: TaskStatus.pending,
      reminders: freshReminders,
      recurrence: currentTask.recurrence,
      autoSnooze: currentTask.autoSnooze,
      habitId: currentTask.habitId,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    _tasks.add(nextTask);
    await HiveStorageService.saveTask(nextTask);
    _scheduleNotificationsForTask(nextTask);
  }

  Future<void> snoozeTask(String taskId, int minutes) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final currentDue = AppDateUtils.combineDateAndTime(task.dueDate, task.dueTime);
      final snoozedDue = currentDue.add(Duration(minutes: minutes));
      final updated = task.copyWith(
        dueDate: AppDateUtils.formatDate(snoozedDue),
        dueTime: AppDateUtils.formatTime(snoozedDue),
        status: TaskStatus.pending,
        updatedAt: DateTime.now().toIso8601String(),
      );
      _tasks[index] = updated;
      await HiveStorageService.saveTask(updated);
      _scheduleNotificationsForTask(updated);
      notifyListeners();
    }
  }

  void _checkOverdueTasks() {
    for (int i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.status == TaskStatus.pending &&
          AppDateUtils.isOverdue(task.dueDate, task.dueTime, false)) {
        _tasks[i] = task.copyWith(status: TaskStatus.overdue);
        HiveStorageService.saveTask(_tasks[i]);
      }
    }
  }

  void _scheduleNotificationsForTask(Task task) {
    for (var reminder in task.reminders) {
      NotificationService.scheduleTaskReminder(task, reminder);
    }
  }

  Future<void> markReminderStatus(String taskId, String reminderId, ReminderStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedReminders = task.reminders.map((r) {
        if (r.id == reminderId) {
          return r.copyWith(status: status);
        }
        return r;
      }).toList();
      final updatedTask = task.copyWith(reminders: updatedReminders);
      _tasks[index] = updatedTask;
      await HiveStorageService.saveTask(updatedTask);
      notifyListeners();
    }
  }

  Future<void> replaceAllTasks(List<Task> newTasks) async {

    _tasks = List.from(newTasks);
    await HiveStorageService.saveAllTasks(_tasks);
    notifyListeners();
  }
}
