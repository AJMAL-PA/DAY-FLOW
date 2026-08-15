import 'recurrence.dart';
import 'reminder.dart';
import 'auto_snooze_config.dart';

enum Priority { high, medium, low }

enum TaskStatus { pending, completed, overdue, cancelled }

class Task {
  final String id;
  final String title;
  final String description;
  final Priority priority;
  final String dueDate; // yyyy-MM-dd
  final String dueTime; // HH:mm
  final TaskStatus status;
  final List<Reminder> reminders;
  final Recurrence recurrence;
  final AutoSnoozeConfig autoSnooze;
  final String? habitId;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    required this.dueDate,
    required this.dueTime,
    this.status = TaskStatus.pending,
    this.reminders = const [],
    this.recurrence = const Recurrence(),
    this.autoSnooze = const AutoSnoozeConfig(),
    this.habitId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    String? dueDate,
    String? dueTime,
    TaskStatus? status,
    List<Reminder>? reminders,
    Recurrence? recurrence,
    AutoSnoozeConfig? autoSnooze,
    String? habitId,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      recurrence: recurrence ?? this.recurrence,
      autoSnooze: autoSnooze ?? this.autoSnooze,
      habitId: habitId ?? this.habitId,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'status': status.name,
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'recurrence': recurrence.toJson(),
        'autoSnooze': autoSnooze.toJson(),
        'habitId': habitId,
        'completedAt': completedAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      dueDate: json['dueDate'] ?? '',
      dueTime: json['dueTime'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => Reminder.fromJson(r))
              .toList() ??
          [],
      recurrence: json['recurrence'] != null
          ? Recurrence.fromJson(json['recurrence'])
          : const Recurrence(),
      autoSnooze: json['autoSnooze'] != null
          ? AutoSnoozeConfig.fromJson(json['autoSnooze'])
          : const AutoSnoozeConfig(),
      habitId: json['habitId'],
      completedAt: json['completedAt'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
