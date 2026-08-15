import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';

class AlarmDialogOverlay extends StatefulWidget {
  const AlarmDialogOverlay({super.key});

  @override
  State<AlarmDialogOverlay> createState() => _AlarmDialogOverlayState();
}

class _AlarmDialogOverlayState extends State<AlarmDialogOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmProvider>(
      builder: (context, alarmProvider, child) {
        if (!alarmProvider.isRinging || (alarmProvider.activeTask == null && alarmProvider.activeHabit == null)) {
          return const SizedBox.shrink();
        }

        final isHabitAlarm = alarmProvider.activeHabit != null;
        final task = alarmProvider.activeTask;
        final habit = alarmProvider.activeHabit;

        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);

        return Material(
          color: Colors.black.withOpacity(0.85),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Ringing Bell / Icon
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isHabitAlarm
                                  ? AppTheme.secondaryColor.withOpacity(0.15)
                                  : AppTheme.primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHabitAlarm ? Icons.bolt_rounded : Icons.alarm_on_rounded,
                              size: 64,
                              color: isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isHabitAlarm ? '⚡ DAILY HABIT ALARM' : 'ALARM RINGING',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isHabitAlarm ? habit!.name : task!.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (isHabitAlarm)
                          Text(
                            'Category: ${habit!.category} • Goal: ${habit.targetQuantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
                          )
                        else if (task!.description.isNotEmpty)
                          Text(
                            task.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (!isHabitAlarm && task != null) ...[
                          // Priority Badge & Due Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: task.priority == Priority.high
                                      ? AppTheme.priorityHigh.withOpacity(0.2)
                                      : task.priority == Priority.medium
                                          ? AppTheme.priorityMedium.withOpacity(0.2)
                                          : AppTheme.priorityLow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  task.priority.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: task.priority == Priority.high
                                        ? AppTheme.priorityHigh
                                        : task.priority == Priority.medium
                                            ? AppTheme.priorityMedium
                                            : AppTheme.priorityLow,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Due: ${AppDateUtils.formatDisplayTime(task.dueTime)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Auto-snooze in ${alarmProvider.remainingSeconds}s',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        // Actions: Mark Complete, Snooze, Dismiss
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                alarmProvider.markCompleted(taskProvider, habitProvider);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text(
                                isHabitAlarm ? 'Complete Habit & Keep Streak 🔥' : 'Mark Completed',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (!isHabitAlarm) ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _showSnoozePicker(context, alarmProvider, taskProvider);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      icon: const Icon(Icons.snooze_rounded),
                                      label: const Text('Snooze'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      alarmProvider.dismiss();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.priorityHigh,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Dismiss'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnoozePicker(
    BuildContext context,
    AlarmProvider alarmProvider,
    TaskProvider taskProvider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Snooze Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [5, 10, 15, 30, 60].map((mins) {
                return ActionChip(
                  label: Text('$mins min'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    alarmProvider.snooze(mins, taskProvider);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
