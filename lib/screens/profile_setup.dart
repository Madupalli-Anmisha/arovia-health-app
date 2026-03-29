import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/arovia_background.dart';
import '../widgets/goal_chip.dart';
class ProfileSetupScreen extends StatefulWidget {
  final bool isEdit;

  const ProfileSetupScreen({super.key, this.isEdit = false});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {

  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController ageController =
      TextEditingController();

  final List<String> goals = [
    'Fitness',
    'Belly Fat Loss',
    'Healthy Eating',
    'Daily Routine',
    'General Wellness',
  ];

  final List<String> avatars = [
    '👨', '👩', '🧒', '👧', '👵', '🧑'
  ];

  String selectedAvatar = '👤';
  List<String> selectedGoals = [];
  String? activeProfileId;

  /// 🌱 Suggested Habits
  final List<String> suggestedHabits = [
    "Walk 10,000 Steps",
    "Drink 4 Liters Water",
    "20 Minutes Exercise",
    "10 Minutes Meditation",
  ];

  Set<String> selectedSuggestedHabits = {};

  /// 🏥 Health Conditions (NEW)
  final List<String> healthOptions = [
    "No Issues",
    "Knee Pain",
    "Lower Back Pain",
    "Shoulder Pain",
    "Obesity",
    "Heart Condition",
    "Neck Pain"
  ];
  

  List<String> selectedHealthConditions = [];

  bool get isAllSelected =>
      selectedGoals.length == goals.length;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadProfileForEdit();
    }
  }

  Future<void> _loadProfileForEdit() async {
    final prefs =
        await SharedPreferences.getInstance();

    final profilesString =
        prefs.getString('profiles');
    activeProfileId =
        prefs.getString('activeProfileId');

    if (profilesString == null ||
        activeProfileId == null) return;

    final List profiles =
        jsonDecode(profilesString);

    final profile = profiles.firstWhere(
        (p) => p['id'] == activeProfileId);

    setState(() {
      nameController.text = profile['name'];
      ageController.text =
          profile['age'].toString();
      selectedAvatar =
          profile['avatar'] ?? '👤';
      selectedGoals =
          List<String>.from(profile['goals']);
      selectedHealthConditions =
          List<String>.from(
              profile['healthConditions'] ?? []);
    });
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content:
                Text('Please fill all details')),
      );
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();
    final profilesString =
        prefs.getString('profiles');

    List profiles = profilesString != null
        ? jsonDecode(profilesString)
        : [];

    if (widget.isEdit &&
        activeProfileId != null) {

      final index = profiles.indexWhere(
          (p) => p['id'] == activeProfileId);

      profiles[index] = {
        "id": activeProfileId,
        "name": nameController.text.trim(),
        "avatar": selectedAvatar,
        "age":
            int.parse(ageController.text),
        "goals": selectedGoals,
        "healthConditions":
            selectedHealthConditions,
        "habits":
            profiles[index]['habits'] ?? [],
        "fitnessLevel": 1,
        "currentWorkoutStreak": 0,
        "totalWorkoutDays": 0,
        "lastWorkoutDate": null,
        "createdAt":
            profiles[index]['createdAt'],
        
      };

    } else {

      final newProfile = {
        "id": DateTime.now()
            .millisecondsSinceEpoch
            .toString(),
        "name":
            nameController.text.trim(),
        "avatar": selectedAvatar,
        "age":
            int.parse(ageController.text),
        "goals": selectedGoals,
        "healthConditions":
            selectedHealthConditions,
        "habits":
            selectedSuggestedHabits
                .map((habitTitle) {
          return {
            "id": DateTime.now()
                    .millisecondsSinceEpoch
                    .toString() +
                habitTitle,
            "title": habitTitle,
            "frequency": "Daily",
            "completedDates": [],
            "streak": 0,
            "lastDone": null,
          };
        }).toList(),
        "createdAt":
            DateTime.now()
                .toIso8601String(),
      };

      profiles.add(newProfile);

      await prefs.setString(
          'activeProfileId',
          newProfile['id'].toString());
    }

    await prefs.setString(
        'profiles', jsonEncode(profiles));

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Profile' : 'Add Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: AroviaBackground(
        child: Padding(
          padding: const EdgeInsets.all(0),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  widget.isEdit
                      ? 'Update your details'
                      : 'Enter profile details',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// NAME
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                /// AGE
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                /// AVATAR
                const Text(
                  'Choose Avatar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 12,
                  children: avatars.map((avatar) {
                    final isSelected = selectedAvatar == avatar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = avatar;
                        });
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected
                            ? Colors.green
                            : Colors.grey.shade300,
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                /// GOALS
                const Text(
                  'Select Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: goals.map((goal) {
                    final selected = selectedGoals.contains(goal);

                    return GoalChip(
                      label: goal,
                      selected: selected,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            selectedGoals.remove(goal);
                          } else {
                            selectedGoals.add(goal);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                /// 🌱 RECOMMENDED HABITS
                const Text(
                  '🌱 Recommended Habits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                ...suggestedHabits.map((habit) {
                  return CheckboxListTile(
                    title: Text(habit),
                    value: selectedSuggestedHabits.contains(habit),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedSuggestedHabits.add(habit);
                        } else {
                          selectedSuggestedHabits.remove(habit);
                        }
                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 20),

                /// HEALTH CONDITIONS
                const Text(
                  'Health Conditions (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                ...healthOptions.map((condition) {
                  return CheckboxListTile(
                    title: Text(condition),
                    value: selectedHealthConditions.contains(condition),
                    onChanged: (checked) {
                      setState(() {

                        if (checked == true) {

                          if (condition == "No Issues") {
                            selectedHealthConditions.clear();
                            selectedHealthConditions.add("No Issues");
                          }

                          else {
                            selectedHealthConditions.remove("No Issues");
                            selectedHealthConditions.add(condition);
                          }

                        } else {
                          selectedHealthConditions.remove(condition);
                        }

                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text(
                      widget.isEdit
                          ? 'Save Changes'
                          : 'Save Profile',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}