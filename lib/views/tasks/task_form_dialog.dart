import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../../models/recurrence.dart';
import '../../models/reminder.dart';
import '../../models/auto_snooze_config.dart';
import '../../providers/task_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';

enum DatePreset { today, tomorrow, in2Days, nextWeek, custom }

class TaskFormDialog extends StatefulWidget {
  final Task? taskToEdit;
  final String? initialDate;

  const TaskFormDialog({super.key, this.taskToEdit, this.initialDate});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late Priority _selectedPriority;
  late DateTime _selectedDate;
  late DatePreset _selectedDatePreset;
  late TimeOfDay _selectedTime;
  late RecurrenceType _recurrenceType;
  late List<int> _customDays;
  late List<int> _reminderOffsets;
  late bool _autoSnoozeEnabled;
  late int _autoSnoozeInterval;
  late int _maxAutoSnoozes;
  String? _linkedHabitId;

  static const List<int> _presetOffsets = [-10, -5, 5, 10];

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _selectedPriority = task?.priority ?? settings.defaultPriority;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (task != null) {
      _selectedDate = DateTime.parse(task.dueDate);
      final tParts = task.dueTime.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
      _recurrenceType = task.recurrence.type;
      _customDays = List.from(task.recurrence.customDays);
      _reminderOffsets = task.reminders.map((r) => r.offsetMinutes).where((o) => o != 0).toList();
      _autoSnoozeEnabled = task.autoSnooze.enabled;
      _autoSnoozeInterval = task.autoSnooze.intervalMinutes;
      _maxAutoSnoozes = task.autoSnooze.maxSnoozes;
      _linkedHabitId = task.habitId;

      _selectedDatePreset = _determinePreset(_selectedDate, today);
    } else {
      _selectedDate = widget.initialDate != null
          ? DateTime.parse(widget.initialDate!)
          : today;
      _selectedDatePreset = _determinePreset(_selectedDate, today);
      _selectedTime = TimeOfDay.now();
      _recurrenceType = RecurrenceType.none;
      _customDays = [];
      _reminderOffsets = []; // 0 (at time of event) is always saved automatically
      _autoSnoozeEnabled = settings.autoSnoozeEnabled;
      _autoSnoozeInterval = settings.autoSnoozeInterval;
      _maxAutoSnoozes = settings.maxAutoSnoozes;
      _linkedHabitId = null;
    }
  }

  DatePreset _determinePreset(DateTime target, DateTime today) {
    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) return DatePreset.today;
    if (diffDays == 1) return DatePreset.tomorrow;
    if (diffDays == 2) return DatePreset.in2Days;
    if (diffDays == 7) return DatePreset.nextWeek;
    return DatePreset.custom;
  }

  void _adjustTime(int minutesDelta) {
    int totalMinutes = _selectedTime.hour * 60 + _selectedTime.minute + minutesDelta;
    if (totalMinutes < 0) {
      totalMinutes = (totalMinutes % 1440 + 1440) % 1440;
    } else {
      totalMinutes = totalMinutes % 1440;
    }
    final newHour = totalMinutes ~/ 60;
    final newMinute = totalMinutes % 60;
    setState(() {
      _selectedTime = TimeOfDay(hour: newHour, minute: newMinute);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Combine standard presets and custom added offsets
    final allDisplayOffsets = <int>{..._presetOffsets, ..._reminderOffsets.where((o) => o != 0)}.toList()
      ..sort();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.taskToEdit != null ? 'Edit Task' : 'Create New Task',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Complete Project Proposal',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.task_alt_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter task title';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Priority Selector
              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: Priority.values.map((p) {
                  final isSelected = _selectedPriority == p;
                  final pColor = p == Priority.high
                      ? AppTheme.priorityHigh
                      : p == Priority.medium
                          ? AppTheme.priorityMedium
                          : AppTheme.priorityLow;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            p.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : pColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: pColor,
                        backgroundColor: pColor.withOpacity(0.12),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPriority = p);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Minimal & Modern Due Date Selector Chips
              const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Today'),
                      selected: _selectedDatePreset == DatePreset.today,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedDatePreset == DatePreset.today ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _applyDatePreset(DatePreset.today),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Tomorrow'),
                      selected: _selectedDatePreset == DatePreset.tomorrow,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedDatePreset == DatePreset.tomorrow ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _applyDatePreset(DatePreset.tomorrow),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('In 2 Days'),
                      selected: _selectedDatePreset == DatePreset.in2Days,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedDatePreset == DatePreset.in2Days ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _applyDatePreset(DatePreset.in2Days),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Next Week'),
                      selected: _selectedDatePreset == DatePreset.nextWeek,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedDatePreset == DatePreset.nextWeek ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _applyDatePreset(DatePreset.nextWeek),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text('Calendar 📅'),
                      selected: _selectedDatePreset == DatePreset.custom,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: _selectedDatePreset == DatePreset.custom ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => _pickDate(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_note_rounded, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        _getDateDisplayLabel(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Simplified & Sleek Due Time Selector
              const Text('Due Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Digital Time Dial Button
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick Stepper Chips
                  OutlinedButton(
                    onPressed: () => _adjustTime(-15),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('-15m', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => _adjustTime(15),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('+15m', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.access_time_rounded, size: 20),
                    tooltip: 'Set to Now',
                    onPressed: () => setState(() => _selectedTime = TimeOfDay.now()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recurrence Builder
              const Text('Recurrence Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrenceType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.repeat_rounded),
                ),
                items: RecurrenceType.values.map((type) {
                  final label = Recurrence(type: type).label;
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _recurrenceType = val);
                },
              ),
              if (_recurrenceType == RecurrenceType.custom) ...[
                const SizedBox(height: 12),
                const Text('Select Custom Days:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (index) {
                    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                    final isSelected = _customDays.contains(index);
                    return FilterChip(
                      label: Text(dayNames[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _customDays.add(index);
                          } else {
                            _customDays.remove(index);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),

              // Reminders & Alarm Offsets Section
              const Text('Additional Reminders & Alarm Offsets', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Note: Alarm at exact task time is always enabled by default.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...allDisplayOffsets.map((offset) {
                    final isSelected = _reminderOffsets.contains(offset);
                    final label = Reminder(id: '', offsetMinutes: offset, fireAt: '').offsetLabel;

                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _reminderOffsets.add(offset);
                          } else {
                            _reminderOffsets.remove(offset);
                          }
                        });
                      },
                    );
                  }),
                  // Custom Offset Dialog Button
                  ActionChip(
                    avatar: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryColor),
                    label: const Text('Custom ⚙️', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showCustomOffsetDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Habit Link Dropdown
              if (habits.isNotEmpty) ...[
                const Text('Link to Habit Streak (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _linkedHabitId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.bolt_rounded, color: AppTheme.accentColor),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Habit Linked')),
                    ...habits.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _linkedHabitId = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.taskToEdit != null ? 'Save Changes' : 'Create Task',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomOffsetDialog() {
    final TextEditingController minutesController = TextEditingController(text: '15');
    bool isBefore = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Custom Reminder Offset', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  hintText: 'e.g. 10 or 30',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.timer_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Before due time'),
                    selected: isBefore,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: isBefore ? Colors.white : null),
                    onSelected: (val) {
                      if (val) setDialogState(() => isBefore = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('After due time'),
                    selected: !isBefore,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(color: !isBefore ? Colors.white : null),
                    onSelected: (val) {
                      if (val) setDialogState(() => isBefore = false);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final mins = int.tryParse(minutesController.text.trim()) ?? 15;
                final calculatedOffset = isBefore ? -mins : mins;
                if (calculatedOffset != 0 && !_reminderOffsets.contains(calculatedOffset)) {
                  setState(() {
                    _reminderOffsets.add(calculatedOffset);
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyDatePreset(DatePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _selectedDatePreset = preset;
      switch (preset) {
        case DatePreset.today:
          _selectedDate = today;
          break;
        case DatePreset.tomorrow:
          _selectedDate = today.add(const Duration(days: 1));
          break;
        case DatePreset.in2Days:
          _selectedDate = today.add(const Duration(days: 2));
          break;
        case DatePreset.nextWeek:
          _selectedDate = today.add(const Duration(days: 7));
          break;
        case DatePreset.custom:
          _pickDate();
          break;
      }
    });
  }

  String _getDateDisplayLabel() {
    final dateStr = AppDateUtils.formatDisplayDate(AppDateUtils.formatDate(_selectedDate));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = _selectedDate.difference(today).inDays;

    if (diffDays == 0) return 'Today ($dateStr)';
    if (diffDays == 1) return 'Tomorrow ($dateStr)';
    if (diffDays == 2) return 'In 2 Days ($dateStr)';
    if (diffDays == 7) return 'Next Week ($dateStr)';
    return dateStr;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      setState(() {
        _selectedDate = picked;
        _selectedDatePreset = _determinePreset(picked, today);
      });
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

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = AppDateUtils.formatDate(_selectedDate);
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final dueDateTime = AppDateUtils.combineDateAndTime(dateStr, timeStr);
    final nowIso = DateTime.now().toIso8601String();

    // Always automatically include 0 (At time of event) by default
    final Set<int> allOffsets = {0, ..._reminderOffsets};

    final List<Reminder> reminders = allOffsets.map((offset) {
      final fireDt = dueDateTime.add(Duration(minutes: offset));
      return Reminder(
        id: const Uuid().v4(),
        offsetMinutes: offset,
        fireAt: fireDt.toIso8601String(),
        status: ReminderStatus.scheduled,
      );
    }).toList();

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (widget.taskToEdit != null) {
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _selectedPriority,
        dueDate: dateStr,
        dueTime: timeStr,
        reminders: reminders,
        recurrence: Recurrence(type: _recurrenceType, customDays: _customDays),
        autoSnooze: AutoSnoozeConfig(
          enabled: _autoSnoozeEnabled,
          intervalMinutes: _autoSnoozeInterval,
          maxSnoozes: _maxAutoSnoozes,
        ),
        habitId: _linkedHabitId,
        updatedAt: nowIso,
      );
      taskProvider.updateTask(updatedTask);
    } else {
      final newTask = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _selectedPriority,
        dueDate: dateStr,
        dueTime: timeStr,
        status: TaskStatus.pending,
        reminders: reminders,
        recurrence: Recurrence(type: _recurrenceType, customDays: _customDays),
        autoSnooze: AutoSnoozeConfig(
          enabled: _autoSnoozeEnabled,
          intervalMinutes: _autoSnoozeInterval,
          maxSnoozes: _maxAutoSnoozes,
        ),
        habitId: _linkedHabitId,
        createdAt: nowIso,
        updatedAt: nowIso,
      );
      taskProvider.addTask(newTask);
    }

    Navigator.pop(context);
  }
}
