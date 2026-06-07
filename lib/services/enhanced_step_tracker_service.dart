import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;

/// Enhanced Step Tracker with manual fallback and diagnostics
class EnhancedStepTrackerService {
  static const String _stepsKey = 'daily_steps';
  static const String _dateKey = 'steps_date';
  static const String _stepHistoryKey = 'step_history';
  static const String _sensorStepsKey = 'sensor_steps';
  static const String _manualStepsKey = 'manual_steps_added';
  static const String _trackerModeKey = 'step_tracker_mode'; // 'sensor' or 'manual'
  static const String _lastUpdateKey = 'last_step_update';
  
  static Stream<StepCount>? _stepStream;
  static int _todaySteps = 0;
  static int _lastSensorValue = 0;
  static bool _isInitialized = false;
  static String _trackerMode = 'sensor'; // Default to sensor mode

  // Get active profile ID
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  static String _getProfileKey(String? profileId, {String prefix = _stepsKey}) {
    if (profileId == null || profileId.isEmpty) return prefix;
    return '${prefix}_$profileId';
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Initialize step tracking with diagnostics
  static Future<void> initStepTracking({String? profileId, bool forceManualMode = false}) async {
    if (_isInitialized) {
      developer.log('✅ Step Tracker already initialized in $_trackerMode mode', name: 'StepTracker');
      return;
    }
    
    try {
      profileId ??= await getActiveProfileId();
      developer.log('📍 Initializing Enhanced Step Tracker...', name: 'StepTracker');
      
      await _checkAndResetForNewDay(profileId: profileId);
      
      if (forceManualMode) {
        _trackerMode = 'manual';
        developer.log('🔧 Manual mode forced', name: 'StepTracker');
      } else {
        // Try to initialize pedometer
        await _initializePedometer(profileId: profileId);
      }
      
      _isInitialized = true;
      developer.log('✅ Enhanced Step Tracker Ready (Mode: $_trackerMode)', name: 'StepTracker');
    } catch (e) {
      developer.log('⚠️ Step Tracker initialization error: $e', name: 'StepTracker', level: 1000);
      _trackerMode = 'manual';
      _isInitialized = true;
    }
  }

  /// Try to initialize pedometer with detailed error handling
  static Future<void> _initializePedometer({String? profileId}) async {
    try {
      developer.log('🔍 Testing Pedometer availability...', name: 'StepTracker');
      
      // Request permissions
      _stepStream = Pedometer.stepCountStream;
      
      // Test the stream with a timeout
      final testStream = _stepStream!.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Pedometer stream timeout - sensor may not be available'),
      );
      
      await testStream;
      _trackerMode = 'sensor';
      developer.log('✅ Pedometer initialized successfully', name: 'StepTracker');
      
      // Now listen properly
      _stepStream?.listen(
        (StepCount event) async {
          await _handleSensorSteps(event.steps, profileId: profileId);
        },
        onError: (error) async {
          developer.log('❌ Pedometer stream error: $error', name: 'StepTracker', level: 900);
          _trackerMode = 'manual';
        },
        cancelOnError: false,
      );
    } on PlatformException catch (e) {
      developer.log('⚠️ Platform Exception: ${e.message}', name: 'StepTracker', level: 900);
      _trackerMode = 'manual';
      throw Exception('Pedometer requires permissions or unavailable on this device');
    } catch (e) {
      developer.log('⚠️ Pedometer initialization failed: $e\nFalling back to manual mode', name: 'StepTracker', level: 900);
      _trackerMode = 'manual';
    }
  }

  /// Handle incoming sensor step data
  static Future<void> _handleSensorSteps(int sensorSteps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    // On first reading, just store the sensor value as baseline
    if (_lastSensorValue == 0) {
      final storedBaseline = prefs.getInt(_getProfileKey(profileId, prefix: _sensorStepsKey)) ?? 0;
      
      if (storedBaseline == 0) {
        _lastSensorValue = sensorSteps;
        await prefs.setInt(_getProfileKey(profileId, prefix: _sensorStepsKey), sensorSteps);
        developer.log('📍 Step Sensor Baseline: $sensorSteps', name: 'StepTracker');
        return;
      } else {
        _lastSensorValue = storedBaseline;
      }
    }
    
    final delta = sensorSteps - _lastSensorValue;
    
    if (delta > 0 && delta < 50000) { // Allow up to 50k steps in one reading
      final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
      final updated = current + delta;
      
      await prefs.setInt(_getProfileKey(profileId), updated);
      await prefs.setInt(_getProfileKey(profileId, prefix: _sensorStepsKey), sensorSteps);
      await prefs.setString(_getProfileKey(profileId, prefix: _lastUpdateKey), DateTime.now().toIso8601String());
      _todaySteps = updated;
      developer.log('✅ Sensor: +$delta steps (Total: $updated)', name: 'StepTracker');
    } else if (delta < 0) {
      // Sensor reset
      developer.log('🔄 Sensor reset detected (delta: $delta)', name: 'StepTracker');
      final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
      final updated = current + sensorSteps.abs();
      
      await prefs.setInt(_getProfileKey(profileId), updated);
      await prefs.setString(_getProfileKey(profileId, prefix: _lastUpdateKey), DateTime.now().toIso8601String());
      _todaySteps = updated;
    }
    
    _lastSensorValue = sensorSteps;
  }

  /// Check and reset steps for new day
  static Future<void> _checkAndResetForNewDay({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    final lastDate = prefs.getString(_getProfileKey(profileId, prefix: _dateKey));
    
    if (lastDate != today) {
      // Save yesterday's data
      if (lastDate != null && lastDate.isNotEmpty) {
        final yesterdaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
        if (yesterdaySteps > 0) {
          await saveStepHistory(yesterdaySteps, profileId: profileId, date: lastDate);
        }
      }
      
      await prefs.setInt(_getProfileKey(profileId), 0);
      await prefs.setInt(_getProfileKey(profileId, prefix: _sensorStepsKey), 0);
      await prefs.setString(_getProfileKey(profileId, prefix: _dateKey), today);
      _todaySteps = 0;
      _lastSensorValue = 0;
      developer.log('🔄 New day - steps reset', name: 'StepTracker');
    } else {
      _todaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    }
  }

  /// Add manual steps (fallback for when sensor doesn't work)
  static Future<void> addManualSteps(int steps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    await _checkAndResetForNewDay(profileId: profileId);
    
    final current = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    final newTotal = current + steps;
    
    await prefs.setInt(_getProfileKey(profileId), newTotal);
    await prefs.setString(_getProfileKey(profileId, prefix: _lastUpdateKey), DateTime.now().toIso8601String());
    _todaySteps = newTotal;
    _trackerMode = 'manual';
    
    developer.log('➕ Manual: +$steps steps (Total: $newTotal)', name: 'StepTracker');
  }

  /// Set steps directly (e.g., from wearable or manual input)
  static Future<void> setManualSteps(int steps, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    await _checkAndResetForNewDay(profileId: profileId);
    
    await prefs.setInt(_getProfileKey(profileId), steps);
    await prefs.setString(_getProfileKey(profileId, prefix: _lastUpdateKey), DateTime.now().toIso8601String());
    _todaySteps = steps;
    _trackerMode = 'manual';
    
    developer.log('✏️ Manual: Set to $steps steps', name: 'StepTracker');
  }

  /// Get today's steps
  static Future<int> getTodaySteps({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    
    await _checkAndResetForNewDay(profileId: profileId);
    
    _todaySteps = prefs.getInt(_getProfileKey(profileId)) ?? 0;
    developer.log('📊 Getting today\'s steps: $_todaySteps ($_trackerMode mode)', name: 'StepTracker');
    return _todaySteps;
  }

  /// Get tracker mode
  static String getTrackerMode() => _trackerMode;

  /// Get last update time
  static Future<DateTime?> getLastUpdate({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_getProfileKey(profileId, prefix: _lastUpdateKey));
    return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
  }

  /// Calculate calories burnt from steps
  static Future<int> getCaloriesBurntFromSteps({String? profileId, double caloriesPerStep = 0.05}) async {
    profileId ??= await getActiveProfileId();
    final steps = await getTodaySteps(profileId: profileId);
    return (steps * caloriesPerStep).toInt();
  }

  /// Save step history
  static Future<void> saveStepHistory(int steps, {String? profileId, String? date}) async {
    profileId ??= await getActiveProfileId();
    date ??= _getTodayDateString();
    final prefs = await SharedPreferences.getInstance();
    
    final historyString = prefs.getString(_getProfileKey(profileId, prefix: _stepHistoryKey)) ?? '{}';
    final history = Map<String, int>.from(jsonDecode(historyString));
    
    history[date] = steps;
    await prefs.setString(_getProfileKey(profileId, prefix: _stepHistoryKey), jsonEncode(history));
    developer.log('📊 Saved: $date: $steps steps', name: 'StepTracker');
  }

  /// Get step history
  static Future<Map<String, int>> getStepHistory({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_getProfileKey(profileId, prefix: _stepHistoryKey)) ?? '{}';
    return Map<String, int>.from(jsonDecode(historyString));
  }

  /// Get average steps (last 7 days)
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

  /// Get diagnostics for debugging
  static Future<Map<String, dynamic>> getDiagnostics({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    return {
      'mode': _trackerMode,
      'initialized': _isInitialized,
      'todaySteps': await getTodaySteps(profileId: profileId),
      'lastUpdate': await getLastUpdate(profileId: profileId),
      'average7Days': await getAverageSteps(profileId: profileId),
    };
  }
}
