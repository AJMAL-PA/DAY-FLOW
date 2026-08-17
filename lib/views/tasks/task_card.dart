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
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCompleted ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isCompleted
          ? (isDark ? AppTheme.darkSurface.withOpacity(0.5) : AppTheme.lightCard.withOpacity(0.7))
          : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _showEditDialog(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 32,
                height: 32,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: AppTheme.secondaryColor,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                            : priorityColor,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Badges Row: Date/Time, Overdue Tag, Recurrence Tag
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isOverdue ? AppTheme.priorityHigh : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppDateUtils.formatRelativeDate(task.dueDate)} at ${AppDateUtils.formatDisplayTime(task.dueTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? AppTheme.priorityHigh : (isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ),
                        if (task.recurrence.type != RecurrenceType.none) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            task.recurrence.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Context Popup Menu Button
              SizedBox(
                width: 30,
                height: 30,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onSelected: (value) {
                    _handleMenuSelection(context, value);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Task', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reschedule',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Reschedule Tomorrow', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'snooze',
                      child: Row(
                        children: [
                          Icon(Icons.snooze_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Snooze 15 Min', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 16, color: AppTheme.priorityHigh),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.priorityHigh)),
                        ],
                      ),
                    ),
                  ],
                ),
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
