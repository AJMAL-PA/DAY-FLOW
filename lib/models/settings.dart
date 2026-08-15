import 'task.dart';

enum AlarmTone { gentle, marimba, digital, harp, bell, zen, birds }

extension AlarmToneExtension on AlarmTone {
  String get displayName {
    switch (this) {
      case AlarmTone.gentle:
        return 'Gentle Chime 🔔';
      case AlarmTone.marimba:
        return 'Warm Marimba 🪵';
      case AlarmTone.digital:
        return 'Digital Clock ⏰';
      case AlarmTone.harp:
        return 'Harp & Piano 🎵';
      case AlarmTone.bell:
        return 'Classic Alarm Bell 🛎️';
      case AlarmTone.zen:
        return 'Zen Bowl 🧘';
      case AlarmTone.birds:
        return 'Morning Birds 🐦';
    }
  }
}

enum AppThemeMode { light, dark, system }

class AppSettings {
  final String userName;
  final bool hasOnboarded;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final AlarmTone alarmTone;
  final int alarmDurationSeconds;
  final bool vibrationEnabled;
  final bool autoSnoozeEnabled;
  final int autoSnoozeInterval;
  final int maxAutoSnoozes;
  final Priority defaultPriority;
  final AppThemeMode theme;

  const AppSettings({
    this.userName = 'User',
    this.hasOnboarded = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.alarmTone = AlarmTone.gentle,
    this.alarmDurationSeconds = 30,
    this.vibrationEnabled = true,
    this.autoSnoozeEnabled = true,
    this.autoSnoozeInterval = 10,
    this.maxAutoSnoozes = 3,
    this.defaultPriority = Priority.medium,
    this.theme = AppThemeMode.system,
  });

  AppSettings copyWith({
    String? userName,
    bool? hasOnboarded,
    bool? notificationsEnabled,
    bool? soundEnabled,
    AlarmTone? alarmTone,
    int? alarmDurationSeconds,
    bool? vibrationEnabled,
    bool? autoSnoozeEnabled,
    int? autoSnoozeInterval,
    int? maxAutoSnoozes,
    Priority? defaultPriority,
    AppThemeMode? theme,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      alarmTone: alarmTone ?? this.alarmTone,
      alarmDurationSeconds: alarmDurationSeconds ?? this.alarmDurationSeconds,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoSnoozeEnabled: autoSnoozeEnabled ?? this.autoSnoozeEnabled,
      autoSnoozeInterval: autoSnoozeInterval ?? this.autoSnoozeInterval,
      maxAutoSnoozes: maxAutoSnoozes ?? this.maxAutoSnoozes,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'hasOnboarded': hasOnboarded,
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'alarmTone': alarmTone.name,
        'alarmDurationSeconds': alarmDurationSeconds,
        'vibrationEnabled': vibrationEnabled,
        'autoSnoozeEnabled': autoSnoozeEnabled,
        'autoSnoozeInterval': autoSnoozeInterval,
        'maxAutoSnoozes': maxAutoSnoozes,
        'defaultPriority': defaultPriority.name,
        'theme': theme.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      userName: json['userName'] ?? 'User',
      hasOnboarded: json['hasOnboarded'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      alarmTone: AlarmTone.values.firstWhere(
        (e) => e.name == json['alarmTone'],
        orElse: () => AlarmTone.gentle,
      ),
      alarmDurationSeconds: json['alarmDurationSeconds'] ?? 30,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      autoSnoozeEnabled: json['autoSnoozeEnabled'] ?? true,
      autoSnoozeInterval: json['autoSnoozeInterval'] ?? 10,
      maxAutoSnoozes: json['maxAutoSnoozes'] ?? 3,
      defaultPriority: Priority.values.firstWhere(
        (e) => e.name == json['defaultPriority'],
        orElse: () => Priority.medium,
      ),
      theme: AppThemeMode.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => AppThemeMode.system,
      ),
    );
  }
}
