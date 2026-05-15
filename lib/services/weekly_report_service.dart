import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class WeeklyReportService {
  static const String _weeklyReportKey = 'weekly_report_data';
  static const String _personalRecordsKey = 'personal_records';

  // Get active profile ID
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  // Get profile-specific key for weekly report
  static String _getWeeklyKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _weeklyReportKey;
    }
    return '${_weeklyReportKey}_$profileId';
  }

  // Get profile-specific key for personal records
  static String _getRecordsKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _personalRecordsKey;
    }
    return '${_personalRecordsKey}_$profileId';
  }

  // Save daily data for weekly report
  static Future<void> saveDailyData({
    required int steps,
    required int calories,
    required int fiber,
    required int junkCount,
    required int healthyCount,
    String? profileId,
  }) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final weeklyData = prefs.getString(_getWeeklyKey(profileId)) ?? '{}';
    final Map<String, dynamic> data = jsonDecode(weeklyData);

    data[dateKey] = {
      'steps': steps,
      'calories': calories,
      'fiber': fiber,
      'junkCount': junkCount,
      'healthyCount': healthyCount,
      'date': dateKey,
    };

    await prefs.setString(_getWeeklyKey(profileId), jsonEncode(data));
    
    // Update personal records
    await _updatePersonalRecords(steps, calories, fiber, junkCount, healthyCount, profileId: profileId);
  }

  // Get last 7 days data
  static Future<List<Map<String, dynamic>>> getWeeklyData({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final weeklyData = prefs.getString(_getWeeklyKey(profileId)) ?? '{}';
    final Map<String, dynamic> data = jsonDecode(weeklyData);

    List<Map<String, dynamic>> lastSevenDays = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      if (data.containsKey(dateKey)) {
        lastSevenDays.add(data[dateKey]);
      } else {
        lastSevenDays.add({
          'steps': 0,
          'calories': 0,
          'fiber': 0,
          'junkCount': 0,
          'healthyCount': 0,
          'date': dateKey,
        });
      }
    }

    return lastSevenDays;
  }

  // Generate weekly summary
  static Future<String> generateWeeklySummary({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final weeklyData = await getWeeklyData(profileId: profileId);
    
    int totalSteps = 0;
    int totalCalories = 0;
    int totalFiber = 0;
    int totalJunkDays = 0;
    int totalHealthyDays = 0;
    int bestStepDay = 0;
    String bestStepDate = '';
    int bestFiberDay = 0;
    String bestFiberDate = '';

    for (var day in weeklyData) {
      totalSteps += (day['steps'] ?? 0) as int;
      totalCalories += (day['calories'] ?? 0) as int;
      totalFiber += (day['fiber'] ?? 0) as int;
      
      if (day['junkCount'] > 0) totalJunkDays++;
      if (day['healthyCount'] > 0) totalHealthyDays++;

      if ((day['steps'] ?? 0) > bestStepDay) {
        bestStepDay = day['steps'] ?? 0;
        bestStepDate = day['date'] ?? '';
      }

      if ((day['fiber'] ?? 0) > bestFiberDay) {
        bestFiberDay = day['fiber'] ?? 0;
        bestFiberDate = day['date'] ?? '';
      }
    }

    int avgSteps = (totalSteps / 7).toInt();
    int avgCalories = (totalCalories / 7).toInt();
    int avgFiber = (totalFiber / 7).toInt();

    String summary = '';
    summary += '📊 WEEKLY REPORT\n';
    summary += '━━━━━━━━━━━━━━━━━━━━\n\n';

    // Weekly averages
    summary += '📈 AVERAGES (7 days):\n';
    summary += '🚶 Steps: $avgSteps/day\n';
    summary += '🍽️ Calories: $avgCalories/day\n';
    summary += '🥬 Fiber: $avgFiber g/day\n\n';

    // Best performances
    summary += '🏆 BEST PERFORMANCES:\n';
    summary += '👟 Most Steps: $bestStepDay on $bestStepDate\n';
    summary += '🥗 Most Fiber: $bestFiberDay g on $bestFiberDate\n\n';

    // Diet balance
    summary += '⚖️ DIET BALANCE:\n';
    summary += '✅ Healthy days: $totalHealthyDays/7\n';
    summary += '⚠️ Days with junk: $totalJunkDays/7\n';
    summary += 'Ratio: ${(totalHealthyDays / 7 * 100).toStringAsFixed(0)}% healthy\n\n';

    // Achievements
    summary += '🎯 ACHIEVEMENTS:\n';
    if (avgSteps > 10000) {
      summary += '✅ Average steps > 10,000! (Active)\n';
    }
    if (avgFiber >= 25) {
      summary += '✅ Fiber target met! (Excellent)\n';
    }
    if (totalHealthyDays >= 5) {
      summary += '✅ Most days healthy! (Great job)\n';
    }
    if (totalJunkDays == 0) {
      summary += '✅ Zero junk days! (Perfect week!)\n';
    }

    // Recommendations
    summary += '\n💡 RECOMMENDATIONS:\n';
    if (avgFiber < 25) {
      summary += '• Increase fiber: Add Green Gram, Lentils\n';
    }
    if (avgSteps < 7000) {
      summary += '• More steps: Aim for 10,000/day\n';
    }
    if (totalJunkDays > 3) {
      summary += '• Reduce junk: Balance with exercise\n';
    }

    return summary;
  }

  // Update personal records
  static Future<void> _updatePersonalRecords(
    int steps,
    int calories,
    int fiber,
    int junkCount,
    int healthyCount, {
    String? profileId,
  }) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final recordsStr = prefs.getString(_getRecordsKey(profileId)) ?? '{}';
    final Map<String, dynamic> records = jsonDecode(recordsStr);

    // Update best steps
    if (steps > (records['bestSteps'] ?? 0)) {
      records['bestSteps'] = steps;
      records['bestStepsDate'] = DateTime.now().toString();
    }

    // Update most fiber
    if (fiber > (records['mostFiber'] ?? 0)) {
      records['mostFiber'] = fiber;
      records['mostFiberDate'] = DateTime.now().toString();
    }

    // Update streak (consecutive healthy days)
    if (healthyCount > junkCount) {
      records['currentStreak'] = (records['currentStreak'] ?? 0) + 1;
      records['bestStreak'] = records['currentStreak'];
    } else {
      records['currentStreak'] = 0;
    }

    // Total achievements
    records['totalDaysTracked'] = (records['totalDaysTracked'] ?? 0) + 1;
    records['totalStepsWalked'] = (records['totalStepsWalked'] ?? 0) + steps;

    await prefs.setString(_getRecordsKey(profileId), jsonEncode(records));
  }

  // Get personal records
  static Future<Map<String, dynamic>> getPersonalRecords({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final recordsStr = prefs.getString(_getRecordsKey(profileId)) ?? '{}';
    return Map<String, dynamic>.from(jsonDecode(recordsStr));
  }

  // Get detailed personal records display
  static Future<String> getPersonalRecordsDisplay({String? profileId}) async {
    profileId ??= await getActiveProfileId();

    final records = await getPersonalRecords(profileId: profileId);

    String display = '';
    display += '🏆 PERSONAL RECORDS\n';
    display += '━━━━━━━━━━━━━━━━━━━━\n\n';

    // Best steps
    display += '👟 BEST STEPS:\n';
    display += '${records['bestSteps'] ?? 0} steps\n';
    if (records['bestStepsDate'] != null) {
      final date = DateTime.parse(records['bestStepsDate']).toLocal();
      display += 'On: ${date.day}-${date.month}-${date.year}\n\n';
    }

    // Most fiber
    display += '🥬 MOST FIBER:\n';
    display += '${records['mostFiber'] ?? 0}g fiber\n';
    if (records['mostFiberDate'] != null) {
      final date = DateTime.parse(records['mostFiberDate']).toLocal();
      display += 'On: ${date.day}-${date.month}-${date.year}\n\n';
    }

    // Streaks
    display += '🔥 STREAKS:\n';
    display += 'Current healthy streak: ${records['currentStreak'] ?? 0} days\n';
    display += 'Best streak: ${records['bestStreak'] ?? 0} days\n\n';

    // Total achievements
    display += '📊 TOTAL ACHIEVEMENTS:\n';
    display += 'Days tracked: ${records['totalDaysTracked'] ?? 0}\n';
    display += 'Total steps: ${records['totalStepsWalked'] ?? 0}\n';
    display += 'Avg steps/day: ${((records['totalStepsWalked'] ?? 0) / max(records['totalDaysTracked'] ?? 1, 1)).toStringAsFixed(0)}\n';

    return display;
  }
}

// Helper function
int max(int a, int b) => a > b ? a : b;
