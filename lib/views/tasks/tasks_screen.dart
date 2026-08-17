import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../../models/reminder.dart';
import '../../providers/task_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'task_card.dart';
import 'task_form_dialog.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/reminder.dart';
import '../../providers/task_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'task_card.dart';
import 'task_form_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCompleted = false;
  bool _showSearchFilter = false;

  @override
  void initState() {
    super.initState();
    // Default category to Today on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (taskProvider.selectedCategory == TaskFilterCategory.all) {
        taskProvider.setFilterCategory(TaskFilterCategory.today);
      }
    });
  }

  void _openQuickTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _QuickTaskSheet(),
    );
  }

  void _openFullTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TaskFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userName = settingsProvider.settings.userName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = taskProvider.filteredTasks;
    final activeTasks = filteredTasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = filteredTasks.where((t) => t.status == TaskStatus.completed).toList();

    // Check overdue count across all tasks
    final overdueCount = taskProvider.tasks.where((t) =>
      t.status == TaskStatus.overdue ||
      (AppDateUtils.isOverdue(t.dueDate, t.dueTime, t.status == TaskStatus.completed) && t.status != TaskStatus.completed)
    ).length;

    final todayDateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final isCategoryCompletedOnly = taskProvider.selectedCategory == TaskFilterCategory.completed;
    final shouldDisplayCompletedList = isCategoryCompletedOnly || _showCompleted;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header & Streamlined Controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streamlined Header Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello $userName 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayDateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 1. Search/Filter Toggle Button
                        IconButton(
                          icon: Icon(
                            _showSearchFilter ? Icons.search_off_rounded : Icons.search_rounded,
                            color: _showSearchFilter ? AppTheme.accentColor : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onPressed: () {
                            setState(() => _showSearchFilter = !_showSearchFilter);
                          },
                        ),
                        // 2. Separate Full Task Button ➕
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor, size: 28),
                          tooltip: 'Add Detailed Task',
                          onPressed: () => _openFullTaskDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Collapsible Search & Priority Filter Bar (Shown ONLY when Search button is clicked)
                    if (_showSearchFilter) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => taskProvider.setSearchQuery(val),
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                filled: true,
                                fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Priority Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Priority?>(
                                value: taskProvider.selectedPriority,
                                hint: const Row(
                                  children: [
                                    Icon(Icons.filter_list_rounded, size: 16),
                                    SizedBox(width: 4),
                                    Text('Priority', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All')),
                                  ...Priority.values.map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p.name.toUpperCase(),
                                        style: TextStyle(
                                          color: p == Priority.high
                                              ? AppTheme.priorityHigh
                                              : p == Priority.medium
                                                  ? AppTheme.priorityMedium
                                                  : AppTheme.priorityLow,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (p) => taskProvider.setPriorityFilter(p),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 3 Clean Segmented Main Tabs (Today, Upcoming, Overdue)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildSegmentedTab(
                            context: context,
                            label: 'Today',
                            category: TaskFilterCategory.today,
                            isSelected: taskProvider.selectedCategory == TaskFilterCategory.today,
                            onTap: () => taskProvider.setFilterCategory(TaskFilterCategory.today),
                          ),
                          _buildSegmentedTab(
                            context: context,
                            label: 'Upcoming',
                            category: TaskFilterCategory.upcoming,
                            isSelected: taskProvider.selectedCategory == TaskFilterCategory.upcoming,
                            onTap: () => taskProvider.setFilterCategory(TaskFilterCategory.upcoming),
                          ),
                          _buildSegmentedTab(
                            context: context,
                            label: 'Overdue',
                            badgeCount: overdueCount,
                            category: TaskFilterCategory.overdue,
                            isSelected: taskProvider.selectedCategory == TaskFilterCategory.overdue,
                            onTap: () => taskProvider.setFilterCategory(TaskFilterCategory.overdue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Task Bar (Just below the Days / Tabs Section)
                    InkWell(
                      onTap: () => _openQuickTaskSheet(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accentColor.withOpacity(0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 20, color: AppTheme.accentColor),
                            SizedBox(width: 8),
                            Text(
                              'Quick Task',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                            ),
                            Spacer(),
                            Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentColor, size: 20),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            // Tasks Content List
            filteredTasks.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 64,
                            color: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            taskProvider.selectedCategory == TaskFilterCategory.today
                                ? 'No Pending Tasks for  🎉'
                                : taskProvider.selectedCategory == TaskFilterCategory.overdue
                                    ? 'No Overdue Tasks! 👍'
                                    : 'No Tasks Found',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "⚡" for Quick Task or "+" for Detailed Task',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. ACTIVE TASKS
                        if (!isCategoryCompletedOnly && activeTasks.isNotEmpty) ...[
                          ...activeTasks.map((task) => TaskCard(task: task)),
                        ],

                        if (!isCategoryCompletedOnly && activeTasks.isEmpty && completedTasks.isNotEmpty && !_showCompleted)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                '🎉 All tasks in this section are completed!',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),

                        // 2. TOGGLABLE COMPLETED TASKS SECTION
                        if (completedTasks.isNotEmpty && !isCategoryCompletedOnly) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => setState(() => _showCompleted = !_showCompleted),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.secondaryColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Completed Tasks (${completedTasks.length})',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _showCompleted ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.secondaryColor,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Render Completed Tasks list ONLY when explicitly toggled or when filtering Completed
                        if (shouldDisplayCompletedList) ...[
                          ...completedTasks.map((task) => TaskCard(task: task)),
                        ],
                      ]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTab({
    required BuildContext context,
    required String label,
    required TaskFilterCategory category,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppTheme.priorityHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// Dedicated Quick Task Modal Sheet
class _QuickTaskSheet extends StatefulWidget {
  const _QuickTaskSheet();

  @override
  State<_QuickTaskSheet> createState() => _QuickTaskSheetState();
}

class _QuickTaskSheetState extends State<_QuickTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateDisplay = AppDateUtils.formatRelativeDate(AppDateUtils.formatDate(_selectedDate));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 22, color: AppTheme.accentColor),
                    SizedBox(width: 8),
                    Text(
                      'Quick Task ⚡',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title Field
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter task title...',
                filled: true,
                fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Date & Time Chips
            Row(
              children: [
                Builder(
                  builder: (chipContext) => ActionChip(
                    avatar: const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primaryColor),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(dateDisplay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16),
                      ],
                    ),
                    onPressed: () => _pickDate(chipContext),
                  ),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primaryColor),
                  label: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: _pickTime,
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Create Task Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitQuickTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Add Quick Task', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext chipContext) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final RenderBox button = chipContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: const [
        PopupMenuItem<String>(
          value: 'today',
          child: Row(
            children: [
              Icon(Icons.today_rounded, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'tomorrow',
          child: Row(
            children: [
              Icon(Icons.event_repeat_rounded, size: 18, color: AppTheme.secondaryColor),
              SizedBox(width: 8),
              Text('Tomorrow'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'calendar',
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.accentColor),
              SizedBox(width: 8),
              Text('Calendar 📅'),
            ],
          ),
        ),
      ],
    );

    if (selected == 'today') {
      setState(() => _selectedDate = today);
    } else if (selected == 'tomorrow') {
      setState(() => _selectedDate = tomorrow);
    } else if (selected == 'calendar') {
      _openCalendarPicker();
    }
  }

  Future<void> _openCalendarPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitQuickTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final dateStr = AppDateUtils.formatDate(_selectedDate);
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final dueDateTime = AppDateUtils.combineDateAndTime(dateStr, timeStr);
    final nowIso = DateTime.now().toIso8601String();

    final reminder = Reminder(
      id: const Uuid().v4(),
      offsetMinutes: 0,
      fireAt: dueDateTime.toIso8601String(),
      status: ReminderStatus.scheduled,
    );

    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      dueDate: dateStr,
      dueTime: timeStr,
      status: TaskStatus.pending,
      reminders: [reminder],
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.addTask(newTask);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick Task Added! ⚡')),
    );
  }
}

