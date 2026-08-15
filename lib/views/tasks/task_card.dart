import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/recurrence.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'task_form_dialog.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.status == TaskStatus.overdue ||
        (AppDateUtils.isOverdue(task.dueDate, task.dueTime, isCompleted) && !isCompleted);

    final priorityColor = task.priority == Priority.high
        ? AppTheme.priorityHigh
        : task.priority == Priority.medium
            ? AppTheme.priorityMedium
            : AppTheme.priorityLow;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted
          ? (isDark ? AppTheme.darkSurface.withOpacity(0.6) : AppTheme.lightCard)
          : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showEditDialog(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (bool? value) {
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
                    taskProvider.toggleTaskStatus(task.id, habitProvider: habitProvider);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Main Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Priority Dot
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Title
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted
                                  ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                  : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Badges Row: Date/Time, Overdue Tag, Recurrence Tag
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Due Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? AppTheme.priorityHigh.withOpacity(0.15)
                                : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: isOverdue ? AppTheme.priorityHigh : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${AppDateUtils.formatRelativeDate(task.dueDate)} at ${AppDateUtils.formatDisplayTime(task.dueTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue ? AppTheme.priorityHigh : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Recurrence Tag
                        if (task.recurrence.type != RecurrenceType.none)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.repeat_rounded,
                                  size: 13,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.recurrence.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Context Popup Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  _handleMenuSelection(context, value);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Task'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reschedule',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Reschedule Tomorrow'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'snooze',
                    child: Row(
                      children: [
                        Icon(Icons.snooze_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Snooze 15 Min'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: AppTheme.priorityHigh),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.priorityHigh)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskFormDialog(taskToEdit: task),
    );
  }

  void _handleMenuSelection(BuildContext context, String action) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'reschedule':
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final updated = task.copyWith(
          dueDate: AppDateUtils.formatDate(tomorrow),
          status: TaskStatus.pending,
        );
        taskProvider.updateTask(updated);
        break;
      case 'snooze':
        taskProvider.snoozeTask(task.id, 15);
        break;
      case 'delete':
        taskProvider.deleteTask(task.id);
        break;
    }
  }
}
