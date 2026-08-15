import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';

class HabitFormDialog extends StatefulWidget {
  final Habit? habitToEdit;

  const HabitFormDialog({super.key, this.habitToEdit});

  @override
  State<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetQuantityController;

  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late String _selectedCategory;

  static const List<Map<String, String>> _categories = [
    {'name': 'Health', 'label': '💊 Health & Medicine'},
    {'name': 'Fitness', 'label': '🏃 Fitness & Exercise'},
    {'name': 'Study', 'label': '📚 Study & Reading'},
    {'name': 'Hydration', 'label': '💧 Water & Hydration'},
    {'name': 'Mindfulness', 'label': '🧘 Mindfulness'},
    {'name': 'General', 'label': '🎯 General'},
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habitToEdit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _targetQuantityController = TextEditingController(text: h?.targetQuantity ?? '1 time');

    _selectedCategory = h?.category ?? 'Health';
    _reminderEnabled = h?.reminderEnabled ?? true;

    if (h?.reminderTime != null) {
      final parts = h!.reminderTime!.split(':');
      _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      _reminderTime = const TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.habitToEdit != null ? 'Edit Habit' : 'Track New Habit',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Habit Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Habit Name *',
                  hintText: 'e.g. Take Medicines, Drink Water, Read Book',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.bolt_rounded, color: AppTheme.accentColor),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter habit name';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Selector Chips
              const Text('Habit Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        selectedColor: AppTheme.secondaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat['name']!);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Goal / Target Quantity
              TextFormField(
                controller: _targetQuantityController,
                decoration: InputDecoration(
                  labelText: 'Goal Quantity / Target',
                  hintText: 'e.g. 1 pill, 8 glasses, 30 mins',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description / Notes (Optional)',
                  hintText: 'e.g. Take 1 pill after breakfast daily',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Daily Alarm Reminder Settings Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.alarm_on_rounded, color: AppTheme.secondaryColor, size: 20),
                          SizedBox(width: 8),
                          Text('Daily Alarm Ringing Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      subtitle: const Text('App will ring daily at exact time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _reminderEnabled,
                      activeColor: AppTheme.secondaryColor,
                      onChanged: (val) => setState(() => _reminderEnabled = val),
                    ),
                    if (_reminderEnabled) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daily Alarm Time:', style: TextStyle(fontWeight: FontWeight.w600)),
                          OutlinedButton.icon(
                            onPressed: _pickTime,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.access_time_rounded, color: AppTheme.secondaryColor, size: 18),
                            label: Text(
                              _reminderTime.format(context),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    widget.habitToEdit != null ? 'Update Habit' : 'Create Habit Tracker',
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    final timeStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    if (widget.habitToEdit != null) {
      final updated = widget.habitToEdit!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        targetQuantity: _targetQuantityController.text.trim(),
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled ? timeStr : null,
      );
      habitProvider.updateHabit(updated);
    } else {
      final newHabit = Habit.create(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        targetQuantity: _targetQuantityController.text.trim(),
        reminderEnabled: _reminderEnabled,
        reminderTime: _reminderEnabled ? timeStr : null,
      );
      habitProvider.createFullHabit(newHabit);
    }

    Navigator.pop(context);
  }
}
