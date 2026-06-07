import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_setup.dart';
import 'profile_selector_screen.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'food_tracking_screen.dart';
import 'habit_analytics_screen.dart';
import 'period_tracker_screen.dart';
import '../widgets/arovia_background.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/habit_card.dart';
import '../widgets/weekly_progress.dart';
import '../services/language_service.dart';
import '../services/step_tracker_service.dart';
import '../services/enhanced_step_tracker_service.dart';
import '../services/food_service.dart';
import '../services/weekly_report_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _profileFuture;
  late TabController _tabController;
  String currentLanguage = 'en';
  String userGender = 'other'; // Track user gender for period tracker visibility

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadActiveProfile();
    _tabController = TabController(length: 3, vsync: this);
    _loadLanguage();
    _loadUserGender();
    // Save daily data in background (non-blocking)
    Future.delayed(const Duration(milliseconds: 500), _saveDailyData);
  }

  // Load user gender to conditionally show period tracker
  Future<void> _loadUserGender() async {
    final profile = await _loadActiveProfile();
    final gender = profile['gender']?.toString().toLowerCase() ?? 'other';
    setState(() {
      userGender = gender;
    });
  }

  // Save daily tracking data to analytics
  Future<void> _saveDailyData() async {
    try {
      final steps = await StepTrackerService.getTodaySteps();
      final calories = await FoodService.getTodayCalories();
      final entries = await FoodService.getTodayEntries();
      
      int fiber = entries.fold(0, (sum, entry) => sum + entry.fiber);
      int junkCount = entries.where((e) => e.foodType == 'junk').length;
      int healthyCount = entries.where((e) => e.foodType == 'healthy').length;
      
      // Save step history
      await StepTrackerService.saveStepHistory(steps);
      
      // Save daily data to weekly report
      await WeeklyReportService.saveDailyData(
        steps: steps,
        calories: calories,
        fiber: fiber,
        junkCount: junkCount,
        healthyCount: healthyCount,
      );
    } catch (e) {
      print('Error saving daily data: $e');
    }
  }
  Future<void> _loadLanguage() async {
    final lang = await LanguageService.getLanguage();
    setState(() {
      currentLanguage = lang;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.translate('language', currentLanguage)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: currentLanguage,
                onChanged: (value) async {
                  await LanguageService.setLanguage('en');
                  setState(() {
                    currentLanguage = 'en';
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('తెలుగు (Telugu)'),
              leading: Radio<String>(
                value: 'te',
                groupValue: currentLanguage,
                onChanged: (value) async {
                  await LanguageService.setLanguage('te');
                  setState(() {
                    currentLanguage = 'te';
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
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
      await prefs.setString('profiles_$currentUserId', jsonEncode(profiles));
    }
  }

  Future<Map<String, dynamic>> _loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final activeProfileId = prefs.getString('activeProfileId');
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return {};
    
    final profilesString = prefs.getString('profiles_$currentUserId');

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
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
    final profilesString = prefs.getString('profiles_$currentUserId');
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

    await prefs.setString('profiles_$currentUserId', jsonEncode(profiles));

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
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
    final profilesString = prefs.getString('profiles_$currentUserId');
    final activeProfileId = prefs.getString('activeProfileId');

    if (profilesString == null || activeProfileId == null)
      return;

    final List profiles = jsonDecode(profilesString);

    final profileIndex =
        profiles.indexWhere((p) => p['id'] == activeProfileId);

    if (profileIndex == -1) return;

    profiles[profileIndex]['habits'].removeAt(habitIndex);

    await prefs.setString('profiles_$currentUserId', jsonEncode(profiles));

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
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
    final profilesString = prefs.getString('profiles_$currentUserId');
    final activeId = prefs.getString('activeProfileId');

    if (profilesString == null || activeId == null) return;

    List profiles = jsonDecode(profilesString);
    profiles.removeWhere((p) => p['id'] == activeId);

    await prefs.setString('profiles_$currentUserId', jsonEncode(profiles));
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
        backgroundColor: const Color(0xFFF4FBF6),
        elevation: 1,
        centerTitle: true,

        title: const Text(
          "Arovia 🌿",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D7A4A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D7A4A),
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: 'Habits'),
            Tab(icon: Icon(Icons.restaurant), text: 'Food'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),

        actions: [

          /// Period Tracker - Only for women
          if (userGender.toLowerCase().contains('female') || userGender.toLowerCase().contains('woman'))
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: "Period Tracker",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PeriodTrackerScreen(),
                  ),
                );
              },
            ),

          /// �🌐 Language
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: "Language",
            onPressed: _showLanguageDialog,
          ),

          /// ✏️ Edit Profile
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
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
              });              _loadUserGender();            },
          ),

          /// 🗑 Delete Profile
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Delete Profile",
            onPressed: _deleteActiveProfile,
          ),

          /// 🚪 Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
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
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Habits
            _buildHabitsTab(),
            // Tab 2: Food Tracking
            FoodTrackingScreen(language: currentLanguage),
            // Tab 3: Analytics
            const HabitAnalyticsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No active profile'));
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
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_walk, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '👟 Automatic Step Tracking',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Steps are tracked automatically from your device sensors. Manual entry has been removed for a cleaner experience.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// Habit Title
                const Text(
                  "Today's Habits",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

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
                        final isDoneToday = h['completedDates'].contains(today);

                        return Dismissible(
                          key: ValueKey(h['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
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
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Confirm"),
                                  content: Text("Mark '${h['title']}' as completed today?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Yes"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                markHabitAsDone(index);
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
                        MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                      );
                      setState(() {
                        _profileFuture = _loadActiveProfile();
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

