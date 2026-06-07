import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HealthCondition {
  final String id;
  final String name; // 'diabetes', 'pcod', 'high_bp', 'heart_disease', 'kidney_issues'
  final String severity; // 'mild', 'moderate', 'severe'
  
  HealthCondition({required this.id, required this.name, required this.severity});
  
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'severity': severity};
  factory HealthCondition.fromMap(Map<String, dynamic> map) =>
      HealthCondition(id: map['id'] ?? '', name: map['name'] ?? '', severity: map['severity'] ?? 'mild');
}

class HealthProfile {
  final String profileId;
  final int age;
  final String gender; // 'male', 'female', 'other'
  final double weight; // kg
  final double height; // cm
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final List<HealthCondition> healthConditions;
  final List<String> allergies; // ['nuts', 'gluten', 'dairy', etc]
  final String dietPreference; // 'vegetarian', 'vegan', 'non_vegetarian'
  final int targetCalories; // personalized daily goal
  final DateTime createdAt;
  
  HealthProfile({
    required this.profileId,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.healthConditions,
    required this.allergies,
    required this.dietPreference,
    required this.targetCalories,
    required this.createdAt,
  });
  
  Map<String, dynamic> toMap() => {
    'profileId': profileId,
    'age': age,
    'gender': gender,
    'weight': weight,
    'height': height,
    'activityLevel': activityLevel,
    'healthConditions': healthConditions.map((c) => c.toMap()).toList(),
    'allergies': allergies,
    'dietPreference': dietPreference,
    'targetCalories': targetCalories,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory HealthProfile.fromMap(Map<String, dynamic> map) => HealthProfile(
    profileId: map['profileId'] ?? '',
    age: map['age'] ?? 25,
    gender: map['gender'] ?? 'other',
    weight: (map['weight'] ?? 70.0).toDouble(),
    height: (map['height'] ?? 170.0).toDouble(),
    activityLevel: map['activityLevel'] ?? 'moderate',
    healthConditions: (map['healthConditions'] as List?)?.map((c) => HealthCondition.fromMap(c as Map<String, dynamic>)).toList() ?? [],
    allergies: List<String>.from(map['allergies'] ?? []),
    dietPreference: map['dietPreference'] ?? 'vegetarian',
    targetCalories: map['targetCalories'] ?? 2000,
    createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
  );
}

class HealthProfileService {
  static const String _profileKey = 'health_profile';
  
  // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
  static int calculateBMR({
    required int age,
    required String gender,
    required double weight,
    required double height,
  }) {
    late double bmr;
    
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    return bmr.toInt();
  }
  
  // Calculate TDEE (Total Daily Energy Expenditure) based on activity level
  static int calculateTDEE({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
  }) {
    int bmr = calculateBMR(age: age, gender: gender, weight: weight, height: height);
    
    double multiplier = 1.2; // sedentary
    switch (activityLevel.toLowerCase()) {
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
    }
    
    return (bmr * multiplier).toInt();
  }
  
  // Adjust calorie goal based on health conditions
  static int adjustCaloriesByHealthConditions({
    required int baseTDEE,
    required List<HealthCondition> conditions,
  }) {
    int adjustedCalories = baseTDEE;
    
    for (var condition in conditions) {
      switch (condition.name.toLowerCase()) {
        case 'diabetes':
          // Mild reduction for stable glucose
          if (condition.severity == 'mild') {
            adjustedCalories = (adjustedCalories * 0.95).toInt();
          } else if (condition.severity == 'moderate') {
            adjustedCalories = (adjustedCalories * 0.90).toInt();
          } else {
            adjustedCalories = (adjustedCalories * 0.85).toInt();
          }
          break;
          
        case 'pcod':
          // Insulin resistance: slight reduction + more protein
          adjustedCalories = (adjustedCalories * 0.92).toInt();
          break;
          
        case 'high_bp':
          // Lower sodium, slight reduction
          adjustedCalories = (adjustedCalories * 0.93).toInt();
          break;
          
        case 'heart_disease':
          // Conservative reduction
          adjustedCalories = (adjustedCalories * 0.88).toInt();
          break;
          
        case 'kidney_issues':
          // Protein restriction
          adjustedCalories = (adjustedCalories * 0.90).toInt();
          break;
      }
    }
    
    return adjustedCalories;
  }
  
  // Get active profile (convenience method)
  static Future<HealthProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = prefs.getString('activeProfileId');
    if (profileId == null) return null;
    return await getOrCreateProfile(profileId);
  }
  
  // Save health profile
  static Future<void> saveHealthProfile(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toMap()));
  }
  
  // Get health profile
  static Future<HealthProfile?> getHealthProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_profileKey}_$profileId');
    if (data == null) return null;
    return HealthProfile.fromMap(jsonDecode(data));
  }
  
  // Get or create default profile
  static Future<HealthProfile> getOrCreateProfile(String profileId) async {
    final existing = await getHealthProfile(profileId);
    if (existing != null) return existing;
    
    // Create default profile
    final profile = HealthProfile(
      profileId: profileId,
      age: 25,
      gender: 'other',
      weight: 70,
      height: 170,
      activityLevel: 'moderate',
      healthConditions: [],
      allergies: [],
      dietPreference: 'vegetarian',
      targetCalories: 2000,
      createdAt: DateTime.now(),
    );
    
    await saveHealthProfile(profile);
    return profile;
  }
  
  // Update health conditions
  static Future<void> updateHealthConditions(
    String profileId,
    List<HealthCondition> conditions,
  ) async {
    final profile = await getHealthProfile(profileId);
    if (profile == null) return;
    
    final updated = HealthProfile(
      profileId: profile.profileId,
      age: profile.age,
      gender: profile.gender,
      weight: profile.weight,
      height: profile.height,
      activityLevel: profile.activityLevel,
      healthConditions: conditions,
      allergies: profile.allergies,
      dietPreference: profile.dietPreference,
      targetCalories: adjustCaloriesByHealthConditions(
        baseTDEE: calculateTDEE(
          age: profile.age,
          gender: profile.gender,
          weight: profile.weight,
          height: profile.height,
          activityLevel: profile.activityLevel,
        ),
        conditions: conditions,
      ),
      createdAt: profile.createdAt,
    );
    
    await saveHealthProfile(updated);
  }
  
  // Update allergies
  static Future<void> updateAllergies(String profileId, List<String> allergies) async {
    final profile = await getHealthProfile(profileId);
    if (profile == null) return;
    
    final updated = HealthProfile(
      profileId: profile.profileId,
      age: profile.age,
      gender: profile.gender,
      weight: profile.weight,
      height: profile.height,
      activityLevel: profile.activityLevel,
      healthConditions: profile.healthConditions,
      allergies: allergies,
      dietPreference: profile.dietPreference,
      targetCalories: profile.targetCalories,
      createdAt: profile.createdAt,
    );
    
    await saveHealthProfile(updated);
  }
  
  // Get food restrictions based on health conditions
  static List<String> getFoodRestrictions(List<HealthCondition> conditions) {
    Set<String> restrictions = {};
    
    for (var condition in conditions) {
      switch (condition.name.toLowerCase()) {
        case 'diabetes':
          restrictions.addAll(['high sugar', 'refined carbs', 'sugary drinks']);
          break;
        case 'pcod':
          restrictions.addAll(['high sugar', 'processed foods', 'refined carbs']);
          break;
        case 'high_bp':
          restrictions.addAll(['high sodium', 'fried foods', 'processed meats']);
          break;
        case 'heart_disease':
          restrictions.addAll(['high saturated fat', 'trans fat', 'high sodium', 'fried foods']);
          break;
        case 'kidney_issues':
          restrictions.addAll(['high protein', 'high sodium', 'high potassium']);
          break;
      }
    }
    
    return restrictions.toList();
  }
  
  // Get recommended macros based on health profile
  static Map<String, int> getRecommendedMacros({
    required int dailyCalories,
    required List<HealthCondition> conditions,
  }) {
    // Default: 40% carbs, 30% protein, 30% fat
    double carbPercent = 0.40;
    double proteinPercent = 0.30;
    double fatPercent = 0.30;
    
    // Adjust for PCOD: higher protein
    if (conditions.any((c) => c.name.toLowerCase() == 'pcod')) {
      carbPercent = 0.35;
      proteinPercent = 0.35;
      fatPercent = 0.30;
    }
    
    // Adjust for diabetes: lower carbs
    if (conditions.any((c) => c.name.toLowerCase() == 'diabetes')) {
      carbPercent = 0.35;
      proteinPercent = 0.35;
      fatPercent = 0.30;
    }
    
    return {
      'carbs': (dailyCalories * carbPercent / 4).toInt(),
      'protein': (dailyCalories * proteinPercent / 4).toInt(),
      'fat': (dailyCalories * fatPercent / 9).toInt(),
    };
  }
}
