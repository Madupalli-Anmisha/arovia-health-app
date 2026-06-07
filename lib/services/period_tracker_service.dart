import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PeriodEntry {
  final DateTime date;
  final int flowIntensity; // 1-3: light, medium, heavy
  final String mood;
  final String symptoms; // comma-separated: cramps, headache, bloating, fatigue, etc.
  final String notes;

  PeriodEntry({
    required this.date,
    required this.flowIntensity,
    required this.mood,
    required this.symptoms,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'flowIntensity': flowIntensity,
      'mood': mood,
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  factory PeriodEntry.fromJson(Map<String, dynamic> json) {
    return PeriodEntry(
      date: DateTime.parse(json['date']),
      flowIntensity: json['flowIntensity'] ?? 1,
      mood: json['mood'] ?? 'neutral',
      symptoms: json['symptoms'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class PeriodTrackerService {
  static const String _periodEntriesKey = 'period_entries';
  static const String _cycleStartKey = 'cycle_start_date';
  static const String _cycleLengthKey = 'cycle_length'; // in days

  // Get profile-specific key
  static String _getProfileKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _periodEntriesKey;
    }
    return '${_periodEntriesKey}_$profileId';
  }

  static String _getCycleStartKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _cycleStartKey;
    }
    return '${_cycleStartKey}_$profileId';
  }

  static String _getCycleLengthKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _cycleLengthKey;
    }
    return '${_cycleLengthKey}_$profileId';
  }

  /// Add a period entry for a specific date
  static Future<void> addPeriodEntry(PeriodEntry entry, String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getProfileKey(profileId);

    List<PeriodEntry> entries = await getPeriodEntries(profileId);
    
    // Remove existing entry for the same date
    entries.removeWhere((e) => 
      e.date.year == entry.date.year &&
      e.date.month == entry.date.month &&
      e.date.day == entry.date.day
    );

    entries.add(entry);
    entries.sort((a, b) => a.date.compareTo(b.date));
    
    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(key, jsonList);

    final currentStart = await getCycleStart(profileId);
    if (currentStart == null || entry.date.isAfter(currentStart)) {
      await setCycleStart(entry.date, profileId);
    }
  }

  /// Get all period entries
  static Future<List<PeriodEntry>> getPeriodEntries(String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getProfileKey(profileId);
    
    final jsonList = prefs.getStringList(key) ?? [];
    return jsonList.map((json) => PeriodEntry.fromJson(jsonDecode(json))).toList();
  }

  /// Get period entries for a specific month
  static Future<List<PeriodEntry>> getPeriodEntriesForMonth(int month, int year, String? profileId) async {
    final entries = await getPeriodEntries(profileId);
    return entries.where((e) => e.date.month == month && e.date.year == year).toList();
  }

  /// Set the start date of the cycle
  static Future<void> setCycleStart(DateTime date, String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCycleStartKey(profileId);
    await prefs.setString(key, date.toIso8601String());
  }

  /// Get the start date of the cycle
  static Future<DateTime?> getCycleStart(String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCycleStartKey(profileId);
    final dateStr = prefs.getString(key);
    
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  /// Set the average cycle length (in days)
  static Future<void> setCycleLength(int days, String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCycleLengthKey(profileId);
    await prefs.setInt(key, days);
  }

  /// Get the average cycle length
  static Future<int> getCycleLength(String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCycleLengthKey(profileId);
    return prefs.getInt(key) ?? 28; // Default 28 days
  }

  /// Predict next period date
  static Future<DateTime?> predictNextPeriod(String? profileId) async {
    DateTime? cycleStart = await getCycleStart(profileId);
    final cycleLength = await getCycleLength(profileId);

    if (cycleStart == null) {
      final entries = await getPeriodEntries(profileId);
      if (entries.isEmpty) return null;
      cycleStart = entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
    }

    DateTime nextPeriod = cycleStart;
    while (nextPeriod.isBefore(DateTime.now())) {
      nextPeriod = nextPeriod.add(Duration(days: cycleLength));
    }

    return nextPeriod;
  }

  /// Get days until next period
  static Future<int?> daysUntilNextPeriod(String? profileId) async {
    final nextPeriod = await predictNextPeriod(profileId);
    if (nextPeriod == null) return null;

    final diff = nextPeriod.difference(DateTime.now());
    return diff.inDays;
  }

  /// Get current cycle phase (menstrual, follicular, ovulation, luteal)
  static Future<String> getCurrentPhase(String? profileId) async {
    DateTime? cycleStart = await getCycleStart(profileId);
    final cycleLength = await getCycleLength(profileId);

    if (cycleStart == null) {
      final entries = await getPeriodEntries(profileId);
      if (entries.isEmpty) return 'unknown';
      cycleStart = entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
    }

    DateTime currentCycleStart = cycleStart;
    while (currentCycleStart.add(Duration(days: cycleLength)).isBefore(DateTime.now())) {
      currentCycleStart = currentCycleStart.add(Duration(days: cycleLength));
    }

    final dayInCycle = DateTime.now().difference(currentCycleStart).inDays;

    if (dayInCycle < 5) return 'menstrual';
    if (dayInCycle < 12) return 'follicular';
    if (dayInCycle < 15) return 'ovulation';
    return 'luteal';
  }

  /// Get cycle statistics
  static Future<Map<String, dynamic>> getCycleStats(String? profileId) async {
    final entries = await getPeriodEntries(profileId);
    final cycleStart = await getCycleStart(profileId);
    final cycleLength = await getCycleLength(profileId);
    final nextPeriod = await predictNextPeriod(profileId);
    final daysUntil = await daysUntilNextPeriod(profileId);
    final phase = await getCurrentPhase(profileId);

    return {
      'totalEntries': entries.length,
      'cycleStartDate': cycleStart?.toIso8601String(),
      'avgCycleLength': cycleLength,
      'nextPeriodDate': nextPeriod?.toIso8601String(),
      'daysUntilNextPeriod': daysUntil,
      'currentPhase': phase,
      'lastPeriodDate': entries.isNotEmpty ? entries.last.date.toIso8601String() : null,
    };
  }

  /// Get symptoms analysis
  static Future<Map<String, int>> getCommonSymptoms(String? profileId) async {
    final entries = await getPeriodEntries(profileId);
    final Map<String, int> symptoms = {};

    for (var entry in entries) {
      if (entry.symptoms.isNotEmpty) {
        final symptomList = entry.symptoms.split(',');
        for (var symptom in symptomList) {
          final trimmed = symptom.trim();
          symptoms[trimmed] = (symptoms[trimmed] ?? 0) + 1;
        }
      }
    }

    return symptoms;
  }

  /// Get average flow intensity
  static Future<double> getAverageFlowIntensity(String? profileId) async {
    final entries = await getPeriodEntries(profileId);
    if (entries.isEmpty) return 0;

    final sum = entries.fold<int>(0, (prev, e) => prev + e.flowIntensity);
    return sum / entries.length;
  }

  /// Get mood analysis
  static Future<Map<String, int>> getMoodAnalysis(String? profileId) async {
    final entries = await getPeriodEntries(profileId);
    final Map<String, int> moods = {};

    for (var entry in entries) {
      moods[entry.mood] = (moods[entry.mood] ?? 0) + 1;
    }

    return moods;
  }

  /// Delete a period entry
  static Future<void> deletePeriodEntry(DateTime date, String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getProfileKey(profileId);

    List<PeriodEntry> entries = await getPeriodEntries(profileId);
    entries.removeWhere((e) => 
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    );

    final jsonList = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(key, jsonList);
  }

  /// Clear all period data (for testing or reset)
  static Future<void> clearAllData(String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getProfileKey(profileId));
    await prefs.remove(_getCycleStartKey(profileId));
    await prefs.remove(_getCycleLengthKey(profileId));
  }
}
