import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StepTrackerService {
  static const String _stepsKey = 'daily_steps';
  static const String _dateKey = 'steps_date';
  static const String _stepHistoryKey = 'step_history';
  static const String _sensorStepsKey = 'sensor_steps';
  static const String _isInitializedKey = 'steps_initialized';
  
  static Stream<StepCount>? _stepStream;
  static int _todaySteps = 0;
  static int _lastSensorValue = 0;
  static bool _isInitialized = false;

  // Get active profile ID
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  static String _getProfileKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) return _stepsKey;
    return '${_stepsKey}_$profileId';
  }

  static String _getDateKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) return _dateKey;
    return '${_dateKey}_$profileId';
  }

  static String _getSensorStepsKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) return _sensorStepsKey;
    return '${_sensorStepsKey}_$profileId';
  }

  static String _getHistoryKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) return _stepHistoryKey;
    return '${_stepHistoryKey}_$profileId';
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Initialize step tracking safely with fallback
  static Future<void> initStepTracking({String? profileId}) async {
    if (_isInitialized) return;
    
    try {
      profileId ??= await getActiveProfileId();
      print('📍 Initializing Step Tracker...');
      
      await _checkAndResetForNewDay(profileId: profileId);
      
      // Try to request permission first
      _tryInitializePedometer(profileId: profileId);
      
      _isInitialized = true;
      print('✅ Step Tracker Ready');
    } catch (e) {
      print('⚠️ Step Tracker initialization error: $e (falling back to manual mode)');
      _isInitialized = true;
    }
  }

  /// Try to initialize pedometer with proper error handling
  static void _tryInitializePedometer({String? profileId}) {
    try {
      _stepStream = Pedometer.stepCountStream;
      
      _stepStream?.listen(
        (StepCount event) async {
          await _handleSensorSteps(event.steps, profileId: profileId);
        },
        onError: (error) async {
          print('❌ Pedometer Error: $error');
          // Retry after 5 seconds
          await Future.delayed(Duration(seconds: 5));
          _tryInitializePedometer(profileId: profileId);
        },
        cancelOnError: false,
      );
      
      print('✅ Pedometer stream activated');
    } catch (e) {
      print('⚠️ Pedometer unavailable: $e (manual steps only)');
    }
  }

  /// Handle incoming sensor step data
  static Future<void> _handleSensorSteps(int sensorSteps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    // On first reading, just store the sensor value as baseline
    if (_lastSensorValue == 0) {
      // Get the previously stored baseline from persistent storage
      final storedBaseline = prefs.getInt(_getSensorStepsKey(profileId)) ?? 0;
      
      if (storedBaseline == 0) {
        // First time ever - just set baseline
        _lastSensorValue = sensorSteps;
        await prefs.setInt(_getSensorStepsKey(profileId), sensorSteps);
        print('📍 Step Sensor Baseline Set: $sensorSteps');
        return;
      } else {
        // Restore previous baseline
        _lastSensorValue = storedBaseline;
      }
    }
    
    final delta = sensorSteps - _lastSensorValue;
    
    // Validate delta (must be positive and reasonable, allow up to 20,000 steps in one reading)
    if (delta > 0 && delta < 20000) {
      final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
      final updated = current + delta;
      
      await prefs.setInt(_getProfileKey(profileId), updated);
      await prefs.setInt(_getSensorStepsKey(profileId), sensorSteps);
      _todaySteps = updated;
      print('✅ Steps: +$delta (Total: $updated)');
    } else if (delta < 0) {
      // Sensor reset detected - happens when phone restarts or sensor resets
      print('🔄 Sensor reset detected (delta: $delta, new baseline: $sensorSteps)');
      // Add the absolute value since sensor was reset
      final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
      final updated = current + sensorSteps.abs();
      
      await prefs.setInt(_getProfileKey(profileId), updated);
      _todaySteps = updated;
      print('✅ After reset - Total: $updated');
    } else if (delta == 0) {
      print('ℹ️ No new steps');
    }
    
    _lastSensorValue = sensorSteps;
  }

  /// Check and reset steps for new day
  static Future<void> _checkAndResetForNewDay({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastDate = prefs.getString(_getDateKey(profileId));
    
    if (lastDate != today) {
      // Save yesterday's data and reset
      if (lastDate != null && lastDate.isNotEmpty) {
        final yesterdaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
        if (yesterdaySteps > 0) {
          await saveStepHistory(yesterdaySteps, profileId: profileId, date: lastDate);
        }
      }
      
      await prefs.setInt(_getProfileKey(profileId), 0);
      await prefs.setInt(_getSensorStepsKey(profileId), 0);
      await prefs.setString(_getDateKey(profileId), today);
      _todaySteps = 0;
      _lastSensorValue = 0;
      print('🔄 New day - steps reset');
    } else {
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
