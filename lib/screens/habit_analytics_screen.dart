import 'package:flutter/material.dart';
import '../widgets/arovia_background.dart';

class HabitAnalyticsScreen extends StatelessWidget {

  final String habitName;
  final List completedDates;

  const HabitAnalyticsScreen({
    super.key,
    required this.habitName,
    required this.completedDates,
  });

  int calculateBestStreak() {

    if (completedDates.isEmpty) return 0;

    List<DateTime> dates =
        completedDates.map((e) => DateTime.parse(e)).toList();

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
    int totalCompletions = completedDates.length;

    int consistency =
        ((totalCompletions / 30) * 100).clamp(0, 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text("$habitName Analytics"),
        backgroundColor: const Color(0xFF4CAF90),
      ),

      body: AroviaBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              _analyticsCard(
                "🔥 Best Streak",
                "$bestStreak days",
              ),

              const SizedBox(height: 16),

              _analyticsCard(
                "📅 Total Completions",
                "$totalCompletions days",
              ),

              const SizedBox(height: 16),

              _analyticsCard(
                "📈 Consistency",
                "$consistency %",
              ),

            ],
          ),
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