import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/audio_service.dart';
import '../../services/backup_service.dart';
import '../../services/hive_storage_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _nameController = TextEditingController(text: settings.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final settings = settingsProvider.settings;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Backup ⚙️',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage sound, theme, alarms, and offline data backup',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 1. Profile Editor
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.person_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
                            onPressed: () {
                              settingsProvider.updateUserName(_nameController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Name updated successfully!')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sound & Alarm Settings
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sound & Alarm Tone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Tone Selector & Preview Button
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AlarmTone>(
                              value: settings.alarmTone,
                              decoration: InputDecoration(
                                labelText: 'Alarm Tone',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                prefixIcon: const Icon(Icons.music_note_rounded),
                              ),
                              items: AlarmTone.values.map((tone) {
                                return DropdownMenuItem(
                                  value: tone,
                                  child: Text(tone.displayName),
                                );
                              }).toList(),
                              onChanged: (tone) {
                                if (tone != null) {
                                  settingsProvider.updateAlarmTone(tone);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () {
                              AudioService.playTonePreview(settings.alarmTone);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Sound Alerts'),
                        subtitle: const Text('Play audio when alarms trigger'),
                        value: settings.soundEnabled,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => settingsProvider.toggleSound(val),
                      ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        subtitle: const Text('Vibrate device on alarms'),
                        value: settings.vibrationEnabled,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => settingsProvider.toggleVibration(val),
                      ),
                      SwitchListTile(
                        title: const Text('Notifications Permission'),
                        subtitle: const Text('Enable background reminders'),
                        value: settings.notificationsEnabled,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) async {
                          if (val) {
                            await NotificationService.requestPermissions();
                          }
                          settingsProvider.toggleNotifications(val);
                        },
                      ),
                      ListTile(
                        title: const Text('Display Over Other Apps'),
                        subtitle: const Text('Grant permission to show alarm overlays'),
                        trailing: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryColor),
                        onTap: () async {
                          await NotificationService.requestOverlayPermission();
                        },
                      ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Auto-Snooze Defaults
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-Snooze Defaults', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Snooze Interval:'),
                          DropdownButton<int>(
                            value: settings.autoSnoozeInterval,
                            items: [5, 10, 15, 30].map((mins) {
                              return DropdownMenuItem(value: mins, child: Text('$mins minutes'));
                            }).toList(),
                            onChanged: (mins) {
                              if (mins != null) {
                                settingsProvider.updateAutoSnooze(mins, settings.maxAutoSnoozes);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Max Auto-Snoozes:'),
                          DropdownButton<int>(
                            value: settings.maxAutoSnoozes,
                            items: [1, 2, 3, 5].map((count) {
                              return DropdownMenuItem(value: count, child: Text('$count times'));
                            }).toList(),
                            onChanged: (count) {
                              if (count != null) {
                                settingsProvider.updateAutoSnooze(settings.autoSnoozeInterval, count);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Appearance (Light / Dark / System)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Appearance Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: AppThemeMode.values.map((mode) {
                          final isSelected = settings.theme == mode;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Center(child: Text(mode.name.toUpperCase())),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  if (sel) settingsProvider.updateTheme(mode);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Data Management (100% Offline JSON Backup & Restore)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data & Offline Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text(
                        '100% local storage. Export JSON backup or restore from file.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _exportBackup(context, taskProvider, habitProvider, settingsProvider),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Export JSON'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _importBackup(context, taskProvider, habitProvider, settingsProvider),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Import JSON'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showResetConfirmation(context, taskProvider, habitProvider, settingsProvider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.priorityHigh,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Reset All App Data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportBackup(
    BuildContext context,
    TaskProvider taskProvider,
    HabitProvider habitProvider,
    SettingsProvider settingsProvider,
  ) async {
    try {
      final jsonStr = BackupService.exportToJson(
        tasks: taskProvider.tasks,
        habits: habitProvider.habits,
        settings: settingsProvider.settings,
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/dayflow_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Backup Exported!'),
            content: Text('Backup file created successfully at:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    TaskProvider taskProvider,
    HabitProvider habitProvider,
    SettingsProvider settingsProvider,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();

        final backupData = BackupService.parseFromJson(jsonStr);

        await taskProvider.replaceAllTasks(backupData.tasks);
        await habitProvider.replaceAllHabits(backupData.habits);
        await settingsProvider.updateSettings(backupData.settings);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App data restored successfully from backup!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showResetConfirmation(
    BuildContext context,
    TaskProvider taskProvider,
    HabitProvider habitProvider,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all tasks, habits, streak records, and custom settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityHigh),
            onPressed: () async {
              Navigator.pop(ctx);
              await HiveStorageService.clearAllData();
              taskProvider.loadTasks();
              habitProvider.loadHabits();
              settingsProvider.loadSettings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset.')),
                );
              }
            },
            child: const Text('Reset Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
