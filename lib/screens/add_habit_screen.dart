import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/arovia_background.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.habit != null) {
      habitController.text = widget.habit!['title'];
      frequency = widget.habit!['frequency'];
    }
  }


  Future<void> _saveHabit() async {
    if (habitController.text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final profilesString = prefs.getString('profiles');
    final activeId = prefs.getString('activeProfileId');

    if (profilesString == null || activeId == null) return;

    final List profiles = jsonDecode(profilesString);

    final profileIndex =
        profiles.indexWhere((p) => p['id'] == activeId);

    if (profileIndex == -1) return;

    // 🔥 EDIT MODE
    if (widget.habit != null && widget.habitIndex != null) {
      profiles[profileIndex]['habits'][widget.habitIndex!] ['title'] =
          habitController.text;

      profiles[profileIndex]['habits'][widget.habitIndex!] ['frequency'] =
          frequency;
    } 
    // ➕ ADD MODE
    else {
      final newHabit = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "title": habitController.text,
        "frequency": frequency,
        "completedDates": [],
        "streak": 0,
        "lastDone": null,
      };

      profiles[profileIndex]['habits'].add(newHabit);
    }

    await prefs.setString('profiles', jsonEncode(profiles));

    Navigator.pop(context);
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
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [

              TextField(
                controller: habitController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButton<String>(
                value: frequency,
                items: const [
                  DropdownMenuItem(
                      value: 'Daily',
                      child: Text('Daily')),
                  DropdownMenuItem(
                      value: 'Weekly',
                      child: Text('Weekly')),
                ],
                onChanged: (value) {
                  setState(() => frequency = value!);
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHabit,
                  child: Text(
                    widget.habit == null
                        ? 'Add Habit'
                        : 'Update Habit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}