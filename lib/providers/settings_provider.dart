import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../models/task.dart';
import '../services/hive_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  ThemeMode get themeMode {
    switch (_settings.theme) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  SettingsProvider() {
    loadSettings();
  }

  void loadSettings() {
    _settings = HiveStorageService.loadSettings();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await HiveStorageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> completeOnboarding(String name) async {
    final cleanName = name.trim().isEmpty ? 'User' : name.trim();
    await updateSettings(_settings.copyWith(
      userName: cleanName,
      hasOnboarded: true,
    ));
  }

  Future<void> updateUserName(String name) async {
    await updateSettings(_settings.copyWith(userName: name));
  }

  Future<void> updateTheme(AppThemeMode theme) async {
    await updateSettings(_settings.copyWith(theme: theme));
  }

  Future<void> updateAlarmTone(AlarmTone tone) async {
    await updateSettings(_settings.copyWith(alarmTone: tone));
  }

  Future<void> toggleSound(bool enabled) async {
    await updateSettings(_settings.copyWith(soundEnabled: enabled));
  }

  Future<void> toggleVibration(bool enabled) async {
    await updateSettings(_settings.copyWith(vibrationEnabled: enabled));
  }

  Future<void> toggleNotifications(bool enabled) async {
    await updateSettings(_settings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateAutoSnooze(int interval, int maxSnoozes) async {
    await updateSettings(_settings.copyWith(
      autoSnoozeInterval: interval,
      maxAutoSnoozes: maxSnoozes,
    ));
  }

  Future<void> updateDefaultPriority(Priority priority) async {
    await updateSettings(_settings.copyWith(defaultPriority: priority));
  }
}
