import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/reminder.dart';
import '../models/habit.dart';
import '../services/audio_service.dart';
import 'task_provider.dart';
import 'habit_provider.dart';
import 'settings_provider.dart';

class AlarmProvider extends ChangeNotifier {
  Task? _activeTask;
  Reminder? _activeReminder;
  Habit? _activeHabit;
  bool _isRinging = false;
  int _remainingSeconds = 30;
  int _autoSnoozeCount = 0;
  Timer? _checkTimer;
  Timer? _countdownTimer;

  Task? get activeTask => _activeTask;
  Reminder? get activeReminder => _activeReminder;
  Habit? get activeHabit => _activeHabit;
  bool get isRinging => _isRinging;
  int get remainingSeconds => _remainingSeconds;

  void startMonitoring(TaskProvider taskProvider, SettingsProvider settingsProvider, HabitProvider habitProvider) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPendingAlarms(taskProvider, settingsProvider, habitProvider);
    });
  }

  void _checkPendingAlarms(TaskProvider taskProvider, SettingsProvider settingsProvider, HabitProvider habitProvider) {
    if (_isRinging) return;

    final now = DateTime.now();
    final settings = settingsProvider.settings;

    if (!settings.notificationsEnabled) return;

    // 1. Check Task Alarms
    for (var task in taskProvider.tasks) {
      if (task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) continue;

      for (var reminder in task.reminders) {
        if (reminder.status == ReminderStatus.completed || reminder.status == ReminderStatus.expired) continue;

        try {
          final fireAt = DateTime.parse(reminder.fireAt);
          final diffSeconds = now.difference(fireAt).inSeconds;

          if (diffSeconds >= 0 && diffSeconds < 30 && reminder.status != ReminderStatus.triggered) {
            triggerAlarm(task, reminder, settingsProvider, habitProvider, taskProvider);
            return;
          }
        } catch (_) {}
      }
    }

    // 2. Check Habit Daily Ringing Alarms
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final nowTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (var habit in habitProvider.habits) {
      if (habit.reminderEnabled && habit.reminderTime != null) {
        if (habit.reminderTime == nowTimeStr && habit.reminderLastFiredDate != todayStr) {
          triggerHabitAlarm(habit, settingsProvider, habitProvider);
          return;
        }
      }
    }
  }

  void triggerAlarm(
    Task task,
    Reminder reminder,
    SettingsProvider settingsProvider,
    HabitProvider habitProvider,
    TaskProvider taskProvider,
  ) {
    _activeTask = task;
    _activeReminder = reminder;
    _activeHabit = null;
    _isRinging = true;
    _remainingSeconds = 30;
    _autoSnoozeCount = reminder.snoozeCount;

    // Mark reminder as triggered in TaskProvider so 5-second check loop doesn't re-trigger it
    taskProvider.markReminderStatus(task.id, reminder.id, ReminderStatus.triggered);

    AudioService.playAlarmTone(
      settingsProvider.settings.alarmTone,
      soundEnabled: settingsProvider.settings.soundEnabled,
      maxDurationSeconds: 30,
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _handleAutoSnooze(taskProvider, settingsProvider);
      }
    });

    notifyListeners();
  }

  void triggerHabitAlarm(
    Habit habit,
    SettingsProvider settingsProvider,
    HabitProvider habitProvider,
  ) {
    _activeTask = null;
    _activeReminder = null;
    _activeHabit = habit;
    _isRinging = true;
    _remainingSeconds = 30;

    // Update last fired date so it rings once per day
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    habitProvider.updateHabit(habit.copyWith(reminderLastFiredDate: todayStr));

    AudioService.playAlarmTone(
      settingsProvider.settings.alarmTone,
      soundEnabled: settingsProvider.settings.soundEnabled,
      maxDurationSeconds: 30,
    );


    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        stopAlarm();
      }
    });

    notifyListeners();
  }

  Future<void> markCompleted(TaskProvider taskProvider, HabitProvider habitProvider) async {
    if (_activeTask != null) {
      if (_activeReminder != null) {
        await taskProvider.markReminderStatus(_activeTask!.id, _activeReminder!.id, ReminderStatus.completed);
      }
      await taskProvider.toggleTaskStatus(_activeTask!.id, habitProvider: habitProvider);
    } else if (_activeHabit != null) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await habitProvider.markHabitCompletedForDate(_activeHabit!.id, todayStr);
    }
    await stopAlarm();
  }

  Future<void> snooze(int minutes, TaskProvider taskProvider) async {
    if (_activeTask != null) {
      if (_activeReminder != null) {
        await taskProvider.markReminderStatus(_activeTask!.id, _activeReminder!.id, ReminderStatus.snoozed);
      }
      await taskProvider.snoozeTask(_activeTask!.id, minutes);
    }
    await stopAlarm();
  }

  Future<void> dismiss({TaskProvider? taskProvider}) async {
    if (_activeTask != null && _activeReminder != null && taskProvider != null) {
      await taskProvider.markReminderStatus(_activeTask!.id, _activeReminder!.id, ReminderStatus.expired);
    }
    await stopAlarm();
  }

  Future<void> _handleAutoSnooze(TaskProvider taskProvider, SettingsProvider settingsProvider) async {
    final settings = settingsProvider.settings;
    if (_activeTask != null) {
      if (settings.autoSnoozeEnabled && _autoSnoozeCount < settings.maxAutoSnoozes) {
        if (_activeReminder != null) {
          await taskProvider.markReminderStatus(_activeTask!.id, _activeReminder!.id, ReminderStatus.snoozed);
        }
        await taskProvider.snoozeTask(_activeTask!.id, settings.autoSnoozeInterval);
      } else if (_activeReminder != null) {
        await taskProvider.markReminderStatus(_activeTask!.id, _activeReminder!.id, ReminderStatus.expired);
      }
    }
    await stopAlarm();
  }


  Future<void> stopAlarm() async {
    await AudioService.stopAlarm();
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isRinging = false;
    _activeTask = null;
    _activeReminder = null;
    _activeHabit = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
