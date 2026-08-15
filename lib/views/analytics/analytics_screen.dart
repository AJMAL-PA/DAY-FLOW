import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final habitProvider = Provider.of<HabitProvider>(context);

    final tasks = taskProvider.tasks;
    final habits = habitProvider.habits;

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).length;
    final overdueTasks = tasks.where((t) => t.status == TaskStatus.overdue).length;

    final completionRate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;

    final highPriority = tasks.where((t) => t.priority == Priority.high).length;
    final mediumPriority = tasks.where((t) => t.priority == Priority.medium).length;
    final lowPriority = tasks.where((t) => t.priority == Priority.low).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Productivity & Analytics 📊',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Insights on your task completion rate and habit performance',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Overview Grid Cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatTile(
                    context,
                    title: 'Total Tasks',
                    value: '$totalTasks',
                    icon: Icons.assignment_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  _buildStatTile(
                    context,
                    title: 'Completion Rate',
                    value: '${completionRate.toStringAsFixed(1)}%',
                    icon: Icons.pie_chart_rounded,
                    color: AppTheme.secondaryColor,
                  ),
                  _buildStatTile(
                    context,
                    title: 'Pending Tasks',
                    value: '$pendingTasks',
                    icon: Icons.hourglass_top_rounded,
                    color: AppTheme.accentColor,
                  ),
                  _buildStatTile(
                    context,
                    title: 'Overdue Tasks',
                    value: '$overdueTasks',
                    icon: Icons.error_outline_rounded,
                    color: AppTheme.priorityHigh,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Completion Rate Visualizer Chart (fl_chart)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Status Distribution',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: totalTasks == 0
                            ? const Center(child: Text('No Task Data to Chart', style: TextStyle(color: Colors.grey)))
                            : PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      color: AppTheme.secondaryColor,
                                      value: completedTasks.toDouble(),
                                      title: '$completedTasks',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.accentColor,
                                      value: pendingTasks.toDouble(),
                                      title: '$pendingTasks',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.priorityHigh,
                                      value: overdueTasks.toDouble(),
                                      title: '$overdueTasks',
                                      radius: 40,
                                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Legend Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendDot('Completed', AppTheme.secondaryColor),
                          _buildLegendDot('Pending', AppTheme.accentColor),
                          _buildLegendDot('Overdue', AppTheme.priorityHigh),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Priority Breakdown
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tasks by Priority',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildPriorityBar(context, 'High Priority', highPriority, totalTasks, AppTheme.priorityHigh),
                      const SizedBox(height: 12),
                      _buildPriorityBar(context, 'Medium Priority', mediumPriority, totalTasks, AppTheme.priorityMedium),
                      const SizedBox(height: 12),
                      _buildPriorityBar(context, 'Low Priority', lowPriority, totalTasks, AppTheme.priorityLow),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Habit Streaks Leaderboard
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Habit Streaks Leaderboard 🏆',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      habits.isEmpty
                          ? const Text('No habits created yet.', style: TextStyle(color: Colors.grey))
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: habits.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 12),
                              itemBuilder: (ctx, i) {
                                final h = habits[i];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      h.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        Text('🔥 ${h.currentStreak} d'),
                                        const SizedBox(width: 12),
                                        Text('🏆 Best: ${h.bestStreak} d', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                );
                              },
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

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPriorityBar(BuildContext context, String label, int count, int total, Color color) {
    final percent = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$count tasks (${(percent * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          color: color,
          backgroundColor: color.withOpacity(0.15),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}
