import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_setup.dart';
import 'profile_selector_screen.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'habit_history_screen.dart';
import '../widgets/arovia_background.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/habit_card.dart';
import '../widgets/weekly_progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadActiveProfile();
  }

  String getTodayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  List<bool> getLast7Days(List completedDates) {
    List<bool> result = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final formatted = date.toIso8601String().substring(0, 10);
      result.add(completedDates.contains(formatted));
    }
    return result;
  }

  Future<void> _validateAndSaveStreaks(
      List profiles, int profileIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final habits = profiles[profileIndex]['habits'];
    final now = DateTime.now();

    bool updated = false;

    for (var h in habits) {
      final lastDone = h['lastDone'];
      if (lastDone == null) continue;

      final lastDate = DateTime.parse(lastDone);
      final diff = now.difference(lastDate).inDays;

      if (diff > 1 && h['streak'] != 0) {
        h['streak'] = 0;
        updated = true;
      }
    }

    if (updated) {
      await prefs.setString('profiles', jsonEncode(profiles));
    }
  }

  Future<Map<String, dynamic>> _loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final activeProfileId = prefs.getString('activeProfileId');
    final profilesString = prefs.getString('profiles');

    if (activeProfileId == null || profilesString == null) return {};

    final List profiles = jsonDecode(profilesString);

    final profileIndex =
        profiles.indexWhere((p) => p['id'] == activeProfileId);

    if (profileIndex == -1) return {};

    await _validateAndSaveStreaks(profiles, profileIndex);

    return profiles[profileIndex];
  }

  Future<void> markHabitAsDone(int habitIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesString = prefs.getString('profiles');
    final activeProfileId = prefs.getString('activeProfileId');

    if (profilesString == null || activeProfileId == null) return;

    final List profiles = jsonDecode(profilesString);
    final today = getTodayDate();

    final profileIndex =
        profiles.indexWhere((p) => p['id'] == activeProfileId);

    if (profileIndex == -1) return;

    final habit = profiles[profileIndex]['habits'][habitIndex];

    if (habit['completedDates'].contains(today)) return;

    final lastDone = habit['lastDone'];

    if (lastDone == null) {
      habit['streak'] = 1;
    } else {
      final lastDate = DateTime.parse(lastDone);
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));

      final wasYesterday =
          lastDate.year == yesterday.year &&
              lastDate.month == yesterday.month &&
              lastDate.day == yesterday.day;

      habit['streak'] = wasYesterday
          ? habit['streak'] + 1
          : 1;
    }

    habit['completedDates'].add(today);
    habit['lastDone'] = DateTime.now().toIso8601String();

    await prefs.setString('profiles', jsonEncode(profiles));

    setState(() {
      _profileFuture = _loadActiveProfile();
    });
  }

  Future<void> deleteHabit(int habitIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Habit"),
        content: const Text(
            "Are you sure you want to delete this habit?"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final profilesString = prefs.getString('profiles');
    final activeProfileId = prefs.getString('activeProfileId');

    if (profilesString == null || activeProfileId == null)
      return;

    final List profiles = jsonDecode(profilesString);

    final profileIndex =
        profiles.indexWhere((p) => p['id'] == activeProfileId);

    if (profileIndex == -1) return;

    profiles[profileIndex]['habits'].removeAt(habitIndex);

    await prefs.setString('profiles', jsonEncode(profiles));

    setState(() {
      _profileFuture = _loadActiveProfile();
    });
  }

  Future<void> _deleteActiveProfile() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
            'This will permanently delete the active profile.\nAre you sure?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final prefs = await SharedPreferences.getInstance();
    final profilesString = prefs.getString('profiles');
    final activeId = prefs.getString('activeProfileId');

    if (profilesString == null || activeId == null) return;

    List profiles = jsonDecode(profilesString);
    profiles.removeWhere((p) => p['id'] == activeId);

    await prefs.setString('profiles', jsonEncode(profiles));
    await prefs.remove('activeProfileId');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const ProfileSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text('Arovia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [

          /// ✏️ Edit Profile
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileSetupScreen(isEdit: true),
                ),
              );

              setState(() {
                _profileFuture = _loadActiveProfile();
              });
            },
          ),

          /// 🗑 Delete Profile
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteActiveProfile,
          ),

          /// 🚪 Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs =
                  await SharedPreferences.getInstance();
              await prefs.remove('activeProfileId');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileSelectionScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: AroviaBackground(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            if (!snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(
                  child: Text('No active profile'));
            }

            final profile = snapshot.data!;
            final habits = profile['habits'] ?? [];
            final today = getTodayDate();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  /// Greeting
                  Text(
                    "Hello ${profile['name']} 🌿",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Dashboard Stats
                  DashboardStats(
                    streak: habits.fold(0, (max, h) => h['streak'] > max ? h['streak'] : max),
                    level: 2,
                    totalDays: habits.length,
                  ),

                  const SizedBox(height: 16),

                  WeeklyProgress(
                    weekData: generateWeeklyProgress(profile["habits"]),
                  ),

                  /// Habit Title
                  const Text(
                    "Today's Habits",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  
                  const SizedBox(height: 12),

                  /// Habit List
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                        if (habits.isEmpty)
                          const Text('No habits added yet')
                        else
                          ...habits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final h = entry.value;
                      final isDoneToday =
                          h['completedDates']
                              .contains(today);

                      return Dismissible(
                        key: ValueKey(h['id']),
                        direction:
                            DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment:
                              Alignment.centerRight,
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 20),
                          child: const Icon(
                              Icons.delete,
                              color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await deleteHabit(index);
                          return false;
                        },
                        child: HabitCard(
                          habitName: h['title'],
                          streak: h['streak'],
                          completed: isDoneToday,
                          onTap: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HabitDetailScreen(
                                  habit: h,
                                  habitIndex: index,
                                ),
                              ),
                            );
                          },
                          onCheck: () async {
                            final confirm =
                                await showDialog<bool>(
                              context: context,
                              builder: (_) =>
                                  AlertDialog(
                                title:
                                    const Text("Confirm"),
                                content: Text(
                                    "Mark '${h['title']}' as completed today?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            context,
                                            false),
                                    child:
                                        const Text(
                                            "Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            context,
                                            true),
                                    child:
                                        const Text(
                                            "Yes"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              markHabitAsDone(
                                  index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🎉 Habit completed! Great job!"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }),
                      ],
                    ),

                  /// Add Habit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Habit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF90),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AddHabitScreen()),
                        );
                        setState(() {
                          _profileFuture =
                              _loadActiveProfile();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }
  List<bool> generateWeeklyProgress(List habits) {

    List<bool> weekData = [];

    for (int i = 6; i >= 0; i--) {

      final date = DateTime.now().subtract(Duration(days: i));
      final formatted = date.toIso8601String().substring(0,10);

      bool completed = false;

      for (var habit in habits) {

        final dates = habit["completedDates"] ?? [];

        if (dates.contains(formatted)) {
          completed = true;
          break;
        }
      }

      weekData.add(completed);
    }

    return weekData;
  }
}