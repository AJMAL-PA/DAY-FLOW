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

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userName = settingsProvider.settings.userName;

    final filteredTasks = taskProvider.filteredTasks;
    final activeTasks = filteredTasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = filteredTasks.where((t) => t.status == TaskStatus.completed).toList();

    final isCategoryCompletedOnly = taskProvider.selectedCategory == TaskFilterCategory.completed;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Custom App Header & Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello $userName 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your daily workflow & smart reminders',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_task_rounded, color: AppTheme.primaryColor),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const TaskFormDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Collapsible Quick Task Creator Button
                    const _QuickTaskBar(),
                    const SizedBox(height: 16),

                    // Search Bar & Priority Filter Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) => taskProvider.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightCard,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority Selector Menu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkSurface
                                : AppTheme.lightCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Priority?>(
                              value: taskProvider.selectedPriority,
                              hint: const Row(
                                children: [
                                  Icon(Icons.filter_list_rounded, size: 18),
                                  SizedBox(width: 4),
                                  Text('Priority', style: TextStyle(fontSize: 13)),
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
                    const SizedBox(height: 16),
                    // Quick Filter Category Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TaskFilterCategory.values.map((cat) {
                          final isSelected = taskProvider.selectedCategory == cat;
                          final label = cat.name[0].toUpperCase() + cat.name.substring(1);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) taskProvider.setFilterCategory(cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tasks Content Body
            filteredTasks.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 72,
                            color: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Tasks Found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "+" to add your first smart reminder or task',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. UPPER SECTION: Non-Completed / Active Tasks
                        if (!isCategoryCompletedOnly && activeTasks.isNotEmpty) ...[
                          if (completedTasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                'Pending & Active Tasks (${activeTasks.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ...activeTasks.map((task) => TaskCard(task: task)),
                        ],

                        // 2. LOWER SECTION: Separated Completed Tasks Section
                        if (completedTasks.isNotEmpty) ...[
                          if (!isCategoryCompletedOnly && activeTasks.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 24, thickness: 1),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.secondaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed (${completedTasks.length})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

class _QuickTaskBar extends StatefulWidget {
  const _QuickTaskBar();

  @override
  State<_QuickTaskBar> createState() => _QuickTaskBarState();
}

class _QuickTaskBarState extends State<_QuickTaskBar> {
  bool _isExpanded = false;
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

    if (!_isExpanded) {
      return InkWell(
        onTap: () => setState(() => _isExpanded = true),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
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
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: AppTheme.accentColor),
                  SizedBox(width: 6),
                  Text(
                    'Quick Task',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isExpanded = false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title Input Field
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Task title...',
              filled: true,
              fillColor: isDark ? AppTheme.darkBackground : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Date, Time & Add Button Row
          Row(
            children: [
              // Date Dropdown Chip (Today, Tomorrow, Calendar 📅)
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
              // Time Chip
              ActionChip(
                avatar: const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primaryColor),
                label: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _pickTime,
              ),
              const Spacer(),
              // Quick Add Button
              ElevatedButton.icon(
                onPressed: _submitQuickTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
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

    _titleController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _isExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick Task Added! ⚡')),
    );
  }
}
