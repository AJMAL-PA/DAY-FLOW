import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/alarm_provider.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import 'tasks/tasks_screen.dart';
import 'tasks/task_form_dialog.dart';
import 'habits/habits_screen.dart';
import 'habits/habit_form_dialog.dart';
import 'calendar/calendar_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';
import 'alarm/alarm_dialog.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TasksScreen(),
    CalendarScreen(),
    HabitsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);

      // Request runtime Android Notification and Exact Alarm permissions
      NotificationService.requestPermissions();

      alarmProvider.startMonitoring(taskProvider, settingsProvider, habitProvider);

      if (!settingsProvider.settings.hasOnboarded) {
        _showOnboardingDialog(context, settingsProvider);
      }
    });
  }

  void _showOnboardingDialog(BuildContext context, SettingsProvider settingsProvider) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.waving_hand_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('Welcome to DAY FLOW!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What should we call you? Your name will be displayed on your personal dashboard.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g. Alex',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: You can change your name anytime later in Settings.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final enteredName = nameController.text.trim();
              settingsProvider.completeOnboarding(enteredName);
              Navigator.pop(ctx);
            },
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final pendingCount = taskProvider.tasks.where((t) => t.status == TaskStatus.pending).length;

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Badge(
                  label: pendingCount > 0 ? Text('$pendingCount') : null,
                  isLabelVisible: pendingCount > 0,
                  child: const Icon(Icons.task_alt_rounded),
                ),
                selectedIcon: const Icon(Icons.task_alt_rounded, color: AppTheme.primaryColor),
                label: 'Tasks',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_rounded),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                label: 'Calendar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bolt_rounded),
                selectedIcon: Icon(Icons.bolt_rounded, color: AppTheme.secondaryColor),
                label: 'Habits',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor),
                label: 'Analytics',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_rounded),
                selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primaryColor),
                label: 'Settings',
              ),
            ],
          ),
          floatingActionButton: _buildFab(context),
        ),

        // Alarm Ringing Dialog Overlay
        const AlarmDialogOverlay(),
      ],
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (_currentIndex == 0 || _currentIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const TaskFormDialog(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (_currentIndex == 2) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryColor,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const HabitFormDialog(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }
}
