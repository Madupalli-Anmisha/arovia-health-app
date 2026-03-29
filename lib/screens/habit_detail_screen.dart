import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/arovia_background.dart';
import 'habit_history_screen.dart';
import 'habit_analytics_screen.dart';

/// ===============================
/// 🔥 WORKOUT EXERCISE MODEL
/// ===============================

class WorkoutExercise {
  String name;
  int reps;
  bool completed;

  WorkoutExercise({
    required this.name,
    required this.reps,
    this.completed = false,
  });
}

/// ===============================
/// 🔥 HABIT DETAIL SCREEN
/// ===============================

class HabitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> habit;
  final int habitIndex;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.habitIndex,
  });

  @override
  State<HabitDetailScreen> createState() =>
      _HabitDetailScreenState();
}

class _HabitDetailScreenState
    extends State<HabitDetailScreen> {

  late Map<String, dynamic> habitData;

  int userAge = 25;
  List<String> userGoals = [];
  List<String> userHealthConditions = [];

  List<WorkoutExercise> todaysPlan = [];

  @override
  void initState() {
    super.initState();
    habitData = widget.habit;
    _loadUserData();
  }

  /// ===============================
  /// 🔥 FITNESS LEVEL ENGINE
  /// ===============================

  void updateWorkoutProgress(Map<String, dynamic> profile) {
    DateTime today = DateTime.now();

    DateTime? lastDate = profile["lastWorkoutDate"] != null
        ? DateTime.parse(profile["lastWorkoutDate"])
        : null;

    profile["currentWorkoutStreak"] ??= 0;
    profile["totalWorkoutDays"] ??= 0;
    profile["fitnessLevel"] ??= 1;

    if (lastDate != null) {
      int difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        profile["currentWorkoutStreak"] += 1;
      } else if (difference > 1) {
        profile["currentWorkoutStreak"] = 1;
      } else {
        return;
      }
    } else {
      profile["currentWorkoutStreak"] = 1;
    }

    profile["totalWorkoutDays"] += 1;
    profile["lastWorkoutDate"] =
        today.toIso8601String();

    updateFitnessLevel(profile);
  }

  void updateFitnessLevel(Map<String, dynamic> profile) {
    int streak = profile["currentWorkoutStreak"];

    if (streak == 7 ||
        streak == 21 ||
        streak == 45 ||
        streak == 75) {
      profile["fitnessLevel"] += 1;
    }
  }

  /// ===============================
  /// 🔥 DIFFICULTY SCALER
  /// ===============================

  int calculateReps(
      int baseReps, Map<String, dynamic> profile) {

    int level = profile["fitnessLevel"] ?? 1;
    int scaled = baseReps + (level * 2);

    int age = profile["age"] ?? 25;

    if (age >= 50) {
      scaled = (scaled * 0.8).round();
    }

    List health =
        profile["healthConditions"] ?? [];

    if (health.contains("Heart Condition")) {
      scaled = (scaled * 0.6).round();
    }

    return scaled;
  }

  /// ===============================
  /// 🔥 EXERCISE PLAN GENERATOR
  /// ===============================

  List<WorkoutExercise> generateTodayExercisePlan(
      int age,
      List<String> goals,
      List<String> healthConditions,
      Map<String, dynamic> profile) {

    final random = Random(DateTime.now().day);

    final Map<String, List<String>> exercisePools = {

      "knee_safe": [
        "Seated leg raises",
        "Wall supported squats",
        "Calf raises",
        "Hamstring stretch",
        "Slow walking"
      ],

      "back_safe": [
        "Cat-cow stretch",
        "Pelvic tilts",
        "Glute bridge",
        "Bird dog",
        "Light walking"
      ],

      "shoulder_safe": [
        "Shoulder rolls",
        "Wall push light",
        "Arm circles",
        "Resistance band pull",
        "Neck mobility stretch"
      ],

      "heart_safe": [
        "Slow walking",
        "March in place",
        "Deep breathing",
        "Light stretching",
        "Chair yoga"
      ],

      "low_impact_cardio": [
        "Brisk walking",
        "Low impact step touch",
        "Stationary cycling",
        "March in place",
        "Light jogging"
      ],

      "core": [
        "Plank",
        "Dead bug",
        "Side plank",
        "Bicycle crunch",
        "Leg raises"
      ],

      "strength": [
        "Squats",
        "Pushups",
        "Lunges",
        "Mountain climbers",
        "Burpees"
      ],

      "mobility": [
        "Yoga stretching",
        "Full body stretch",
        "Hip mobility",
        "Hamstring stretch",
        "Spine rotation stretch"
      ]
    };

    List<String> selectedExercises = [];
    bool hasHealthCondition = false;

    if (healthConditions.contains("Heart Condition")) {
      selectedExercises.addAll(exercisePools["heart_safe"]!);
      hasHealthCondition = true;
    }

    if (healthConditions.contains("Knee Pain")) {
      selectedExercises.addAll(exercisePools["knee_safe"]!);
      hasHealthCondition = true;
    }

    if (healthConditions.contains("Lower Back Pain")) {
      selectedExercises.addAll(exercisePools["back_safe"]!);
      hasHealthCondition = true;
    }

    if (healthConditions.contains("Shoulder Pain")) {
      selectedExercises.addAll(exercisePools["shoulder_safe"]!);
      hasHealthCondition = true;
    }

    if (healthConditions.contains("Obesity")) {
      selectedExercises.addAll(
          exercisePools["low_impact_cardio"]!);
      hasHealthCondition = true;
    }

    if (!hasHealthCondition) {

      if (age >= 50) {
        selectedExercises.addAll(
            exercisePools["mobility"]!);
        selectedExercises.addAll(
            exercisePools["low_impact_cardio"]!);
      } else {

        if (goals.contains("Belly Fat Loss")) {
          selectedExercises.addAll(
              exercisePools["core"]!);
          selectedExercises.addAll(
              exercisePools["low_impact_cardio"]!);
        }

        else if (goals.contains("Fitness")) {
          selectedExercises.addAll(
              exercisePools["strength"]!);
          selectedExercises.addAll(
              exercisePools["core"]!);
        }

        else {
          selectedExercises.addAll(
              exercisePools["mobility"]!);
          selectedExercises.addAll(
              exercisePools["low_impact_cardio"]!);
        }
      }
    }

    selectedExercises =
        selectedExercises.toSet().toList();

    selectedExercises.shuffle(random);

    List<String> baseList =
        selectedExercises.take(4).toList();

    return baseList.map((exercise) {

      int reps = calculateReps(10, profile);

      return WorkoutExercise(
        name: exercise,
        reps: reps,
      );

    }).toList();
  }

  /// ===============================
  /// 🔥 YOUTUBE REDIRECT
  /// ===============================

  Future<void> openExerciseVideo(String exercise) async {

    final query = Uri.encodeComponent(
        "$exercise proper form exercise");

    final url = Uri.parse(
        "https://www.youtube.com/results?search_query=$query");

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception("Could not launch $url");
    }
  }

  /// ===============================
  /// 🔥 LOAD USER DATA
  /// ===============================

  Future<void> _loadUserData() async {

    final prefs =
        await SharedPreferences.getInstance();

    final profilesString =
        prefs.getString('profiles');

    final activeProfileId =
        prefs.getString('activeProfileId');

    if (profilesString == null ||
        activeProfileId == null) return;

    final List profiles =
        jsonDecode(profilesString);

    final profile = profiles.firstWhere(
      (p) => p['id'] == activeProfileId,
      orElse: () => {},
    );

    userAge = profile['age'] ?? 25;

    userGoals =
        List<String>.from(profile['goals'] ?? []);

    userHealthConditions =
        List<String>.from(
            profile['healthConditions'] ?? []);

    if (habitData['title']
        .toString()
        .toLowerCase()
        .contains("exercise")) {

      todaysPlan = generateTodayExercisePlan(
          userAge,
          userGoals,
          userHealthConditions,
          profile);

      setState(() {});
    }
  }

  /// ===============================
  /// 🔥 COMPLETE WORKOUT
  /// ===============================

  Future<void> _completeExerciseHabit() async {

    final prefs =
        await SharedPreferences.getInstance();

    final profilesString =
        prefs.getString('profiles');

    final activeProfileId =
        prefs.getString('activeProfileId');

    if (profilesString == null ||
        activeProfileId == null) return;

    final List profiles =
        jsonDecode(profilesString);

    final profileIndex =
        profiles.indexWhere(
            (p) => p['id'] == activeProfileId);

    if (profileIndex == -1) return;

    final profile = profiles[profileIndex];

    final habit =
        profile['habits'][widget.habitIndex];

    final today = DateTime.now();

    final todayString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (habit['completedDates']
        .contains(todayString)) {

      if (mounted) Navigator.pop(context);
      return;
    }

    final lastDone = habit['lastDone'];

    if (lastDone == null) {
      habit['streak'] = 1;
    }

    else {

      final lastDate =
          DateTime.parse(lastDone);

      final yesterday =
          today.subtract(
              const Duration(days: 1));

      final wasYesterday =
          lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day;

      habit['streak'] =
          wasYesterday ? habit['streak'] + 1 : 1;
    }

    habit['completedDates'].add(todayString);

    habit['lastDone'] =
        today.toIso8601String();

    updateWorkoutProgress(profile);

    await prefs.setString(
        'profiles', jsonEncode(profiles));

    if (mounted) Navigator.pop(context);
  }

  /// ===============================
  /// 🔥 UI
  /// ===============================

  @override
  Widget build(BuildContext context) {

    final completedDates =
        List<String>.from(
            habitData['completedDates'] ?? []);

    final streak = habitData['streak'];

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text("Habit Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: AroviaBackground(
        child: Padding(
          padding:
              const EdgeInsets.all(0),

          child: ListView(
            children: [

              Text(
                habitData['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  title: const Text(
                      "Current Streak"),
                  subtitle: Text(
                      "$streak days"),
                ),
              ),

              const SizedBox(height: 20),

              if (todaysPlan.isNotEmpty) ...[

                const Text(
                  "🗓 Today's Exercise Plan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                ...todaysPlan.map((exercise) {

                  return Card(
                    elevation: 2,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () =>
                          openExerciseVideo(
                              exercise.name),

                      leading: Checkbox(
                        value:
                            exercise.completed,

                        onChanged: (value) {

                          setState(() {
                            exercise.completed =
                                value ?? false;
                          });
                        },
                      ),

                      title: Text(
                          "${exercise.name} - ${exercise.reps} reps"),

                      trailing: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.green,
                      ),
                    ),
                  );

                }).toList(),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed:
                      todaysPlan.isNotEmpty &&
                              todaysPlan.every(
                                  (e) =>
                                      e.completed)
                          ? _completeExerciseHabit
                          : null,

                  child: const Text(
                      "Mark Workout Complete"),
                ),
              ],
              const SizedBox(height: 15),

              ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text("View Habit History"),
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HabitHistoryScreen(
                        habitName: widget.habit["name"] ?? "Habit",
                        history: generateHistory(widget.habit),
                      ),
                    ),
                  );

                },
              ),

              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text("View Analytics"),
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HabitAnalyticsScreen(
                        habitName: widget.habit["name"] ?? "Habit",
                        completedDates: widget.habit["completedDates"] ?? [],
                      ),
                    ),
                  );

                },
              ),
              const SizedBox(height: 30),

              const Text(
                "Completed Dates",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              if (completedDates.isEmpty)
                const Text(
                    "No completions yet")
              else
                ...completedDates.map((date) {

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                          Icons.calendar_today),
                      title: Text(date),
                    ),
                  );

                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
  List<bool> generateHistory(Map habit) {

    List<bool> result = [];

    final completedDates = habit["completedDates"] ?? [];

    for (int i = 6; i >= 0; i--) {

      final date = DateTime.now().subtract(Duration(days: i));
      final formatted = date.toIso8601String().substring(0,10);

      result.add(completedDates.contains(formatted));
    }

    return result;
  }
}