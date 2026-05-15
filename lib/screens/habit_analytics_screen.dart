import 'package:flutter/material.dart';
import '../widgets/arovia_background.dart';
import '../services/step_tracker_service.dart';
import '../services/food_service.dart';
import '../services/weekly_report_service.dart';

class HabitAnalyticsScreen extends StatefulWidget {

  final String? habitName;
  final List? completedDates;

  const HabitAnalyticsScreen({
    super.key,
    this.habitName,
    this.completedDates,
  });

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {
  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _analyticsFuture = _loadAnalytics();
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    try {
      final todaySteps = await StepTrackerService.getTodaySteps();
      final avgSteps = await StepTrackerService.getAverageSteps();
      final caloriesBurnt = await StepTrackerService.getCaloriesBurntFromSteps();
      
      final todayCalories = await FoodService.getTodayCalories();
      final dailyGoal = await FoodService.getDailyGoal();
      final todayEntries = await FoodService.getTodayEntries();
      
      final weeklyData = await WeeklyReportService.getWeeklyData();
      final personalRecords = await WeeklyReportService.getPersonalRecords();
      
      int totalFiber = todayEntries.fold(0, (sum, entry) => sum + entry.fiber);
      int junkCount = todayEntries.where((e) => e.foodType == 'junk').length;
      int healthyCount = todayEntries.where((e) => e.foodType == 'healthy').length;
      
      int weeklySteps = weeklyData.fold<int>(0, (sum, day) => sum + ((day['steps'] ?? 0) as int));
      int weeklyCalories = weeklyData.fold<int>(0, (sum, day) => sum + ((day['calories'] ?? 0) as int));
      int weeklyFiber = weeklyData.fold<int>(0, (sum, day) => sum + ((day['fiber'] ?? 0) as int));
      
      return {
        'todaySteps': todaySteps,
        'avgSteps': avgSteps,
        'caloriesBurnt': caloriesBurnt,
        'todayCalories': todayCalories,
        'dailyGoal': dailyGoal,
        'totalFiber': totalFiber,
        'junkCount': junkCount,
        'healthyCount': healthyCount,
        'weeklySteps': weeklySteps,
        'weeklyCalories': weeklyCalories,
        'weeklyFiber': weeklyFiber,
        'personalRecords': personalRecords,
      };
    } catch (e) {
      print('Error loading analytics: $e');
      return {
        'todaySteps': 0,
        'avgSteps': 0,
        'caloriesBurnt': 0,
        'todayCalories': 0,
        'dailyGoal': 2000,
        'totalFiber': 0,
        'junkCount': 0,
        'healthyCount': 0,
        'weeklySteps': 0,
        'weeklyCalories': 0,
        'weeklyFiber': 0,
        'personalRecords': {},
      };
    }
  }

  int calculateBestStreak() {

    if (widget.completedDates == null || widget.completedDates!.isEmpty) return 0;

    List<DateTime> dates =
        widget.completedDates!.map((e) => DateTime.parse(e)).toList();

    dates.sort();

    int best = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {

      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
      } else {
        current = 1;
      }

      if (current > best) best = current;
    }

    return best;
  }

  @override
  Widget build(BuildContext context) {

    int bestStreak = calculateBestStreak();
    int totalCompletions = widget.completedDates?.length ?? 0;

    int consistency =
        ((totalCompletions / 30) * 100).clamp(0, 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.habitName ?? 'Analytics'} Analytics"),
        backgroundColor: const Color(0xFF4CAF90),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _analyticsFuture = _loadAnalytics();
              });
            },
          ),
        ],
      ),

      body: AroviaBackground(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No analytics data'));
            }

            final analytics = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🚶 STEP TRACKER SECTION
                    const Text(
                      "👟 Step Tracker",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _analyticsCard(
                            "Today's Steps",
                            "${analytics['todaySteps']} steps",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _analyticsCard(
                            "Average Steps",
                            "${analytics['avgSteps']} steps",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    
                    // Manual step input (since sensor not available)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '📝 Enter your steps manually:',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter steps (e.g., 5000)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Store in temp for submission
                                  },
                                  controller: TextEditingController(
                                    text: '${analytics['todaySteps']}',
                                  ),
                                  onSubmitted: (value) async {
                                    final steps = int.tryParse(value) ?? 0;
                                    if (steps > 0) {
                                      await StepTrackerService.setManualSteps(steps);
                                      setState(() {
                                        _analyticsFuture = _loadAnalytics();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Set'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) {
                                      final controller = TextEditingController(text: '${analytics['todaySteps']}');
                                      return AlertDialog(
                                        title: const Text('📝 Enter Today\'s Steps'),
                                        content: TextField(
                                          controller: controller,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: 'e.g., 5000',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final steps = int.tryParse(controller.text) ?? 0;
                                              if (steps >= 0) {
                                                await StepTrackerService.setManualSteps(steps);
                                                if (mounted) {
                                                  setState(() {
                                                    _analyticsFuture = _loadAnalytics();
                                                  });
                                                  Navigator.pop(ctx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('✅ Steps set to $steps'),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '💡 Tap field and enter total steps for today, then tap "Set"',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// 🍽️ FOOD TRACKER SECTION
                    const Text(
                      "🍽️ Food Tracker",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _analyticsCard(
                            "Today's Calories",
                            "${analytics['todayCalories']}/${analytics['dailyGoal']} cal",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _analyticsCard(
                            "Fiber",
                            "${analytics['totalFiber']}g / 25g",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _analyticsCard(
                            "Healthy Items",
                            "${analytics['healthyCount']} items",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _analyticsCard(
                            "Junk Items",
                            "${analytics['junkCount']} items",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// 📊 WEEKLY SUMMARY SECTION
                    const Text(
                      "📊 Weekly Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _analyticsCard(
                            "Weekly Steps",
                            "${analytics['weeklySteps']} steps",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _analyticsCard(
                            "Weekly Calories",
                            "${analytics['weeklyCalories']} cal",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _analyticsCard(
                      "Weekly Fiber",
                      "${analytics['weeklyFiber']}g",
                    ),
                    const SizedBox(height: 24),

                    /// 🔥 HABIT ANALYTICS (if available)
                    if (widget.habitName != null) ...[
                      const Text(
                        "🔥 Habit Analytics",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _analyticsCard(
                        "🔥 Best Streak",
                        "$bestStreak days",
                      ),
                      const SizedBox(height: 12),
                      _analyticsCard(
                        "📅 Total Completions",
                        "$totalCompletions days",
                      ),
                      const SizedBox(height: 12),
                      _analyticsCard(
                        "📈 Consistency",
                        "$consistency %",
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _analyticsCard(String title, String value) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0,4),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}