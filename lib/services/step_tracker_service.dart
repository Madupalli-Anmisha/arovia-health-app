import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StepTrackerService {
  static const String _stepsKey = 'daily_steps';
  static const String _dateKey = 'steps_date';
  static const String _stepHistoryKey = 'step_history';
  static const String _sensorStepsKey = 'sensor_steps'; // Track sensor baseline
  
  static late Stream<StepCount> _stepStream;
  static int _todaySteps = 0;
  static String _currentDate = '';

  // Get active profile ID
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  // Get profile-specific key for steps
  static String _getProfileKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _stepsKey;
    }
    return '${_stepsKey}_$profileId';
  }

  // Get profile-specific key for date
  static String _getDateKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _dateKey;
    }
    return '${_dateKey}_$profileId';
  }

  // Get profile-specific key for sensor steps baseline
  static String _getSensorStepsKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _sensorStepsKey;
    }
    return '${_sensorStepsKey}_$profileId';
  }

  // Get profile-specific key for history
  static String _getHistoryKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _stepHistoryKey;
    }
    return '${_stepHistoryKey}_$profileId';
  }

  // Get today's date string
  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Initialize step tracking
  static Future<void> initStepTracking() async {
    try {
      print('📍 Initializing Step Tracker...');
      final profileId = await getActiveProfileId();
      
      // Check if it's a new day
      await _checkAndResetForNewDay(profileId: profileId);
      
      // Request permission and start tracking
      _stepStream = Pedometer.stepCountStream;
      
      _stepStream.listen(
        (StepCount event) async {
          print('📊 Pedometer Data: ${event.steps} steps detected');
          await _handleSensorSteps(event.steps, profileId: profileId);
        },
        onError: (error) {
          print('❌ Pedometer Error: $error');
        },
      );
      
      print('✅ Step Tracker Initialized - Listening to pedometer...');
    } catch (e) {
      print('❌ Error initializing step tracking: $e');
    }
  }

  // Handle sensor step data
  static Future<void> _handleSensorSteps(int sensorSteps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    // Get baseline from previous app start
    final lastSensorSteps = prefs.getInt(_getSensorStepsKey(profileId)) ?? 0;
    
    // Calculate delta (new steps since last reading)
    final delta = sensorSteps - lastSensorSteps;
    
    // Only process if positive delta (avoid backwards counts)
    if (delta > 0) {
      // Get current step count for today
      final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
      final updated = current + delta;
      
      // Save updated steps
      await prefs.setInt(_getProfileKey(profileId), updated);
      _todaySteps = updated;
      
      print('✅ Steps Updated: +$delta (Total today: $updated)');
    }
    
    // Always save the current sensor reading as baseline for next delta
    await prefs.setInt(_getSensorStepsKey(profileId), sensorSteps);
  }

  // Check and reset for new day
  static Future<void> _checkAndResetForNewDay({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastDate = prefs.getString(_getDateKey(profileId));
    
    print('📅 Last Date: $lastDate, Today: $today');
    
    if (lastDate != today) {
      // New day - save yesterday's steps to history and reset
      if (lastDate != null && lastDate.isNotEmpty) {
        final yesterdaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
        if (yesterdaySteps > 0) {
          await saveStepHistory(yesterdaySteps, profileId: profileId, date: lastDate);
        }
      }
      
      // Reset for new day
      await prefs.setInt(_getProfileKey(profileId), 0);
      await prefs.setInt(_getSensorStepsKey(profileId), 0);
      await prefs.setString(_getDateKey(profileId), today);
      
      _todaySteps = 0;
      print('🔄 New Day Reset: Steps = 0');
    } else {
      // Same day - load existing steps
      _todaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    }
  }

  // Manual add steps (for testing or manual input)
  static Future<void> addManualSteps(int steps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    final newTotal = current + steps;
    
    await prefs.setInt(_getProfileKey(profileId), newTotal);
    _todaySteps = newTotal;
    
    print('➕ Manual Steps Added: +$steps (Total: $newTotal)');
  }

  // Set steps directly (for manual input)
  static Future<void> setManualSteps(int steps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_getProfileKey(profileId), steps);
    _todaySteps = steps;
    
    print('✏️ Steps Set Manually: $steps');
  }

  // Get today's steps
  static Future<int> getTodaySteps({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    // Check if it's a new day
    await _checkAndResetForNewDay(profileId: profileId);
    
    // Load today's steps
    _todaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    return _todaySteps;
  }

  // Calculate calories burnt from steps (approx 0.05 cal per step)
  static Future<int> getCaloriesBurntFromSteps({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final steps = await getTodaySteps(profileId: profileId);
    return (steps * 0.05).toInt();
  }

  // Save step history for weekly reports
  static Future<void> saveStepHistory(int steps, {String? profileId, String? date}) async {
    profileId ??= await getActiveProfileId();
    date ??= _getTodayDateString();
    final prefs = await SharedPreferences.getInstance();
    
    final historyString = prefs.getString(_getHistoryKey(profileId)) ?? '{}';
    final history = Map<String, int>.from(jsonDecode(historyString));
    
    history[date] = steps;
    await prefs.setString(_getHistoryKey(profileId), jsonEncode(history));
    print('📊 Saved to history - $date: $steps steps');
  }

  // Get step history (last 7 days)
  static Future<Map<String, int>> getStepHistory({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_getHistoryKey(profileId)) ?? '{}';
    return Map<String, int>.from(jsonDecode(historyString));
  }

  // Get average steps (last 7 days)
  static Future<int> getAverageSteps({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final history = await getStepHistory(profileId: profileId);
    if (history.isEmpty) return 0;
    
    int total = 0;
    for (var steps in history.values) {
      total += steps;
    }
    return (total / history.length).toInt();
  }
}
