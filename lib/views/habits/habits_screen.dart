import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'habit_form_dialog.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    int totalStreaks = habits.fold(0, (sum, h) => sum + h.currentStreak);
    int topRecordStreak = habits.fold(0, (max, h) => h.bestStreak > max ? h.bestStreak : max);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Stats Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habit Tracker ⚡',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Build consistent habits & set daily ringing reminders',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppTheme.secondaryColor, size: 28),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const HabitFormDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Active Habits',
                            value: '${habits.length}',
                            icon: Icons.repeat_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Total Active Streaks',
                            value: '🔥 $totalStreaks',
                            icon: Icons.local_fire_department_rounded,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Best Record',
                            value: '🏆 $topRecordStreak d',
                            icon: Icons.emoji_events_rounded,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Habits List with 30-Day Completion Matrix
            habits.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 72,
                            color: AppTheme.secondaryColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Habits Tracked Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+" to create a habit with daily ringing alarms (e.g. Take Medicines)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _HabitCardItem(habit: habits[index]);
                        },
                        childCount: habits.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _HabitCardItem extends StatelessWidget {
  final Habit habit;

  const _HabitCardItem({required this.habit});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate last 14 days for grid view
    final now = DateTime.now();
    final List<DateTime> last14Days = List.generate(
      14,
      (i) => now.subtract(Duration(days: 13 - i)),
    );
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    String formattedTime = '';
    if (habit.reminderTime != null) {
      formattedTime = AppDateUtils.formatDisplayTime(habit.reminderTime!);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Streak Badges Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${habit.category} • Goal: ${habit.targetQuantity}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                            ),
                          ),
                          if (habit.reminderEnabled && habit.reminderTime != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.alarm_on_rounded, size: 12, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Daily $formattedTime',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Current Streak Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.currentStreak} d streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => HabitFormDialog(habitToEdit: habit),
                      );
                    } else if (val == 'delete') {
                      habitProvider.deleteHabit(habit.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Habit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Habit', style: TextStyle(color: AppTheme.priorityHigh))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '14-Day Completion Grid (Tap day to toggle):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            // Interactive Day Grid Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: last14Days.map((dt) {
                  final dateStr = formatter.format(dt);
                  final isDone = habit.completionHistory.contains(dateStr);
                  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
                  final dayLabel = DateFormat('E').format(dt)[0];

                  return GestureDetector(
                    onTap: () {
                      habitProvider.toggleHabitDate(habit.id, dateStr);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Column(
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppTheme.primaryColor : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppTheme.secondaryColor
                                  : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                              shape: BoxShape.circle,
                              border: isToday
                                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                                  : null,
                              ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                  : Text(
                                      '${dt.day}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
