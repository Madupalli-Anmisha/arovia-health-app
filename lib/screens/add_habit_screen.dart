import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/arovia_background.dart';
import '../services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Map<String, dynamic>? habit;
  final int? habitIndex;

  const AddHabitScreen({
    super.key,
    this.habit,
    this.habitIndex,
  });

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}


class _AddHabitScreenState extends State<AddHabitScreen> {
  final TextEditingController habitController = TextEditingController();
  String frequency = 'Daily';
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();

    if (widget.habit != null) {
      habitController.text = widget.habit!['title'];
      frequency = widget.habit!['frequency'];
    }
  }


  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    try {
      if (habitController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter habit name'), backgroundColor: Colors.red),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final String? currentUserId = prefs.getString('currentUserId');
      
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
        );
        return;
      }
      
      final profilesString = prefs.getString('profiles_$currentUserId');
      final activeId = prefs.getString('activeProfileId');

      if (profilesString == null || activeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found'), backgroundColor: Colors.red),
        );
        return;
      }

      final List profiles = jsonDecode(profilesString);

      final profileIndex =
          profiles.indexWhere((p) => p['id'] == activeId);

      if (profileIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active profile not found'), backgroundColor: Colors.red),
        );
        return;
      }

      final habitName = habitController.text;

      // 🔥 EDIT MODE
      if (widget.habit != null && widget.habitIndex != null) {
        profiles[profileIndex]['habits'][widget.habitIndex!]['title'] =
            habitName;

        profiles[profileIndex]['habits'][widget.habitIndex!]['frequency'] =
            frequency;

        profiles[profileIndex]['habits'][widget.habitIndex!]['reminderTime'] =
            _selectedTime?.format(context);
      } 
      // ➕ ADD MODE
      else {
        final newHabit = {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "title": habitName,
          "frequency": frequency,
          "completedDates": [],
          "streak": 0,
          "lastDone": null,
          "reminderTime": _selectedTime?.format(context),
        };

        profiles[profileIndex]['habits'].add(newHabit);
      }

      await prefs.setString('profiles_$currentUserId', jsonEncode(profiles));

      // Schedule notification if time is selected
      if (_selectedTime != null) {
        try {
          final now = DateTime.now();

          DateTime scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );

          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          await NotificationService.scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: "Arovia Reminder 🌿",
            body: "Time to complete: $habitName",
            scheduledTime: scheduledTime,
          );
        } catch (notifError) {
          print('Notification error: $notifError');
          // Continue anyway - notification is optional
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Habit ${widget.habit == null ? 'added' : 'updated'}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('Add Habit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: AroviaBackground(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Habit Name Input
              TextField(
                controller: habitController,
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  prefixIcon: const Icon(Icons.check_circle),
                  hintText: 'e.g., Morning Exercise, Read, Meditation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 20),

              // Frequency Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: frequency,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'Daily',
                        child: Text('📅 Daily')),
                    DropdownMenuItem(
                        value: 'Weekly',
                        child: Text('📆 Weekly')),
                  ],
                  onChanged: (value) {
                    setState(() => frequency = value!);
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Time Picker (Optional)
              Card(
                child: ListTile(
                  title: Text(
                    _selectedTime == null
                        ? "⏰ Set Reminder Time (Optional)"
                        : "⏰ Reminder: ${_selectedTime!.format(context)}",
                    style: TextStyle(
                      fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedTime != null ? Colors.green : Colors.grey,
                    ),
                  ),
                  trailing: Icon(
                    Icons.access_time,
                    color: _selectedTime != null ? Colors.green : Colors.grey,
                  ),
                  onTap: _pickTime,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(widget.habit == null ? Icons.add : Icons.update),
                  label: Text(
                    widget.habit == null
                        ? 'Add Habit'
                        : 'Update Habit',
                  ),
                  onPressed: _saveHabit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}