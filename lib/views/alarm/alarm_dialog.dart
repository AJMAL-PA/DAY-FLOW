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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);

        final title = isHabitAlarm ? habit!.name : task!.title;
        final description = isHabitAlarm
            ? 'Goal: ${habit!.targetQuantity} (${habit.category})'
            : (task!.description.isNotEmpty ? task.description : 'Due at ${AppDateUtils.formatDisplayTime(task.dueTime)}');

        final priorityColor = !isHabitAlarm && task != null
            ? (task.priority == Priority.high
                ? AppTheme.priorityHigh
                : task.priority == Priority.medium
                    ? AppTheme.priorityMedium
                    : AppTheme.priorityLow)
            : AppTheme.secondaryColor;

        return Material(
          color: Colors.black.withOpacity(0.45),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.black.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header Icon & Category Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isHabitAlarm ? Icons.bolt_rounded : Icons.alarm_on_rounded,
                                    size: 32,
                                    color: isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHabitAlarm ? 'DAILY HABIT ALARM ⚡' : 'TASK REMINDER ⏰',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: isHabitAlarm ? AppTheme.secondaryColor : AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ringing now • Auto-snooze in ${alarmProvider.remainingSeconds}s',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Main Title & Details
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isHabitAlarm ? (isDark ? Colors.white : Colors.black87) : priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Action Buttons Row: Complete, Snooze, Dismiss (Full Prominent Buttons)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Complete Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    alarmProvider.markCompleted(taskProvider, habitProvider);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                                  label: Text(
                                    isHabitAlarm ? 'Complete Habit 🔥' : 'Mark Completed',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Snooze and Dismiss Buttons Side-by-Side
                                Row(
                                  children: [
                                    if (!isHabitAlarm) ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _showSnoozePicker(context, alarmProvider, taskProvider);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          icon: const Icon(Icons.snooze_rounded, size: 18),
                                          label: const Text(
                                            'Snooze',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          alarmProvider.dismiss(taskProvider: taskProvider);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.priorityHigh,
                                          side: const BorderSide(color: AppTheme.priorityHigh, width: 1.5),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        label: const Text(
                                          'Dismiss',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
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
              'Select Snooze Duration 💤',
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
                  label: Text('$mins min', style: const TextStyle(fontWeight: FontWeight.bold)),
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
