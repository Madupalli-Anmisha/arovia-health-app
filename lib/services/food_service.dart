import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'online_calorie_service.dart';

class FoodEntry {
  final String id;
  final String foodName;
  final int calories;
  final String quantity;
  final int fiber; // grams of fiber
  final String foodType; // junk, healthy, balanced
  final DateTime timestamp;

  FoodEntry({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.quantity,
    required this.fiber,
    required this.foodType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'calories': calories,
      'quantity': quantity,
      'fiber': fiber,
      'foodType': foodType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] ?? '',
      foodName: map['foodName'] ?? '',
      calories: map['calories'] ?? 0,
      quantity: map['quantity'] ?? '',
      fiber: map['fiber'] ?? 0,
      foodType: map['foodType'] ?? 'balanced',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FoodService {
  static const String _foodEntriesKey = 'food_entries';
  static const String _dailyGoalKey = 'daily_calorie_goal';

  // Get profile-specific key for food entries
  static String _getProfileKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _foodEntriesKey;
    }
    return '${_foodEntriesKey}_$profileId';
  }

  // Get profile-specific key for daily goal
  static String _getGoalKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) {
      return _dailyGoalKey;
    }
    return '${_dailyGoalKey}_$profileId';
  }

  // Get active profile ID
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  // South Indian & Andhra Pradesh Food Database with calories and fiber
  static final Map<String, Map<String, dynamic>> foodDatabase = {
    // Breakfast - South Indian
    'Idli (1 piece)': {'calories': 40, 'fiber': 1, 'type': 'healthy'},
    'Dosa (1)': {'calories': 150, 'fiber': 2, 'type': 'balanced'},
    'Uttapam (1)': {'calories': 120, 'fiber': 2, 'type': 'balanced'},
    'Puttu (1 piece)': {'calories': 80, 'fiber': 2, 'type': 'healthy'},
    'Appam (1)': {'calories': 110, 'fiber': 1, 'type': 'balanced'},
    'Pesarattu (1)': {'calories': 140, 'fiber': 3, 'type': 'healthy'},
    'Upma (1 cup)': {'calories': 160, 'fiber': 2, 'type': 'balanced'},
    'Poha (1 cup)': {'calories': 100, 'fiber': 1, 'type': 'balanced'},
    'Semiya Upma (1 cup)': {'calories': 150, 'fiber': 1, 'type': 'balanced'},

    // Lunch - Rice & Curries
    'Biryani (1 cup)': {'calories': 280, 'fiber': 2, 'type': 'junk'},
    'Rice + Sambar (1 plate)': {'calories': 220, 'fiber': 3, 'type': 'balanced'},
    'Rice + Rasam (1 plate)': {'calories': 180, 'fiber': 2, 'type': 'healthy'},
    'Rice + Curd (1 plate)': {'calories': 200, 'fiber': 1, 'type': 'balanced'},
    'Dal Rice (1 plate)': {'calories': 240, 'fiber': 4, 'type': 'healthy'},
    'Chapati (1)': {'calories': 70, 'fiber': 2, 'type': 'balanced'},
    'Roti (1)': {'calories': 70, 'fiber': 2, 'type': 'balanced'},

    // Curries & Gravies
    'Chicken Curry (1 cup)': {'calories': 220, 'fiber': 1, 'type': 'junk'},
    'Mutton Curry (1 cup)': {'calories': 280, 'fiber': 1, 'type': 'junk'},
    'Fish Curry (1 cup)': {'calories': 180, 'fiber': 1, 'type': 'balanced'},
    'Paneer Butter Masala (1 cup)': {'calories': 300, 'fiber': 1, 'type': 'junk'},
    'Chana Masala (1 cup)': {'calories': 200, 'fiber': 5, 'type': 'healthy'},
    'Dal Fry (1 cup)': {'calories': 160, 'fiber': 6, 'type': 'healthy'},
    'Sambar (1 cup)': {'calories': 80, 'fiber': 3, 'type': 'healthy'},
    'Rasam (1 cup)': {'calories': 40, 'fiber': 1, 'type': 'healthy'},

    // Vegetables
    'Brinjal Fry (1 cup)': {'calories': 140, 'fiber': 3, 'type': 'balanced'},
    'Aloo Fry (1 cup)': {'calories': 180, 'fiber': 2, 'type': 'junk'},
    'Okra Fry (1 cup)': {'calories': 100, 'fiber': 3, 'type': 'healthy'},
    'Carrot (1 medium)': {'calories': 25, 'fiber': 2, 'type': 'healthy'},
    'Tomato (1 medium)': {'calories': 22, 'fiber': 1, 'type': 'healthy'},
    'Spinach (1 cup)': {'calories': 41, 'fiber': 2, 'type': 'healthy'},

    // Snacks - South Indian
    'Samosa (1)': {'calories': 200, 'fiber': 1, 'type': 'junk'},
    'Pakora (1 piece)': {'calories': 120, 'fiber': 1, 'type': 'junk'},
    'Vada (1)': {'calories': 150, 'fiber': 1, 'type': 'junk'},
    'Murukku (handful)': {'calories': 140, 'fiber': 1, 'type': 'junk'},
    'Chikhalwali (1)': {'calories': 180, 'fiber': 1, 'type': 'junk'},
    'Puffed Rice (1 cup)': {'calories': 50, 'fiber': 0, 'type': 'junk'},
    'Roasted Chickpeas (1 cup)': {'calories': 120, 'fiber': 4, 'type': 'healthy'},
    'Mixed Nuts (1 oz)': {'calories': 160, 'fiber': 2, 'type': 'healthy'},
    
    // Quick Snacks & Junk
    'Ice Cream (1 cup)': {'calories': 200, 'fiber': 0, 'type': 'junk'},
    'Ice cream (1 scoop)': {'calories': 130, 'fiber': 0, 'type': 'junk'},
    'Dessert': {'calories': 250, 'fiber': 0, 'type': 'junk'},
    'Chocolate (50g)': {'calories': 240, 'fiber': 3, 'type': 'junk'},
    'Cake (1 slice)': {'calories': 280, 'fiber': 1, 'type': 'junk'},
    'Burger (1)': {'calories': 500, 'fiber': 2, 'type': 'junk'},
    'Fries (1 serving)': {'calories': 365, 'fiber': 3, 'type': 'junk'},
    'Pizza (1 slice)': {'calories': 285, 'fiber': 2, 'type': 'junk'},
    'Candy (1 piece)': {'calories': 50, 'fiber': 0, 'type': 'junk'},
    'Chips (1 oz)': {'calories': 150, 'fiber': 1, 'type': 'junk'},
    'Fried Chicken (1 piece)': {'calories': 320, 'fiber': 0, 'type': 'junk'},
    
    // Legumes - Healthy
    'Green Gram (1 cup cooked)': {'calories': 105, 'fiber': 8, 'type': 'healthy'},
    'Moong Dal (1 cup cooked)': {'calories': 105, 'fiber': 8, 'type': 'healthy'},
    'Red Lentils (1 cup cooked)': {'calories': 230, 'fiber': 8, 'type': 'healthy'},
    'Chickpeas (1 cup cooked)': {'calories': 269, 'fiber': 12, 'type': 'healthy'},
    'Black Beans (1 cup cooked)': {'calories': 227, 'fiber': 15, 'type': 'healthy'},
    'Kidney Beans (1 cup cooked)': {'calories': 225, 'fiber': 11, 'type': 'healthy'},
    'Peas (1 cup)': {'calories': 118, 'fiber': 8, 'type': 'healthy'},
    'Sprouts (1 cup)': {'calories': 32, 'fiber': 2, 'type': 'healthy'},

    // Sweets & Desserts - Andhra Pradesh
    'Gulab Jamun (1)': {'calories': 220, 'fiber': 0, 'type': 'junk'},
    'Jalebi (50g)': {'calories': 180, 'fiber': 0, 'type': 'junk'},
    'Barfi (1 piece)': {'calories': 150, 'fiber': 1, 'type': 'junk'},
    'Kheer (1 cup)': {'calories': 250, 'fiber': 1, 'type': 'junk'},
    'Payasam (1 cup)': {'calories': 280, 'fiber': 1, 'type': 'junk'},
    'Gajjar Halwa (1 cup)': {'calories': 320, 'fiber': 2, 'type': 'junk'},
    'Laddu (1)': {'calories': 160, 'fiber': 1, 'type': 'junk'},

    // Drinks
    'Lassi (1 cup)': {'calories': 180, 'fiber': 0, 'type': 'balanced'},
    'Buttermilk (1 cup)': {'calories': 90, 'fiber': 0, 'type': 'healthy'},
    'Fresh Juice (1 cup)': {'calories': 120, 'fiber': 1, 'type': 'healthy'},
    'Tea (1 cup)': {'calories': 25, 'fiber': 0, 'type': 'healthy'},
    'Coffee (1 cup)': {'calories': 40, 'fiber': 0, 'type': 'balanced'},
    'Soft Drink (1 can)': {'calories': 140, 'fiber': 0, 'type': 'junk'},
    'Coconut Water (1 cup)': {'calories': 45, 'fiber': 2, 'type': 'healthy'},
  };

  // Get daily calorie goal (default 2000)
  static Future<int> getDailyGoal({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_getGoalKey(profileId)) ?? 2000;
  }

  // Set daily calorie goal
  static Future<void> setDailyGoal(int calories, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getGoalKey(profileId), calories);
  }

  // Add food entry
  static Future<void> addFoodEntry(FoodEntry entry, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final entries = await getFoodEntries(profileId: profileId);
    entries.add(entry);
    await prefs.setString(_getProfileKey(profileId), jsonEncode(
      entries.map((e) => e.toMap()).toList(),
    ));
  }

  // Get all food entries
  static Future<List<FoodEntry>> getFoodEntries({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_getProfileKey(profileId));
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((item) => FoodEntry.fromMap(item as Map<String, dynamic>)).toList();
  }

  // Get today's entries
  static Future<List<FoodEntry>> getTodayEntries({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final entries = await getFoodEntries(profileId: profileId);
    final today = DateTime.now();
    return entries.where((e) {
      return e.timestamp.year == today.year &&
          e.timestamp.month == today.month &&
          e.timestamp.day == today.day;
    }).toList();
  }

  // Get today's total calories
  static Future<int> getTodayCalories({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final entries = await getTodayEntries(profileId: profileId);
    int total = 0;
    for (var entry in entries) {
      total += entry.calories;
    }
    return total;
  }

  // Delete food entry
  static Future<void> deleteFoodEntry(String entryId, {String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final prefs = await SharedPreferences.getInstance();
    final entries = await getFoodEntries(profileId: profileId);
    entries.removeWhere((e) => e.id == entryId);
    await prefs.setString(_getProfileKey(profileId), jsonEncode(
      entries.map((e) => e.toMap()).toList(),
    ));
  }

  // Get nutrition advice based on today's calories and junk food
  static Future<String> getNutritionAdvice({String? profileId}) async {
    profileId ??= await getActiveProfileId();
    final todayCalories = await getTodayCalories(profileId: profileId);
    final dailyGoal = await getDailyGoal(profileId: profileId);
    final entries = await getTodayEntries(profileId: profileId);
    
    // Count food types
    int junkCount = entries.where((e) => e.foodType == 'junk').length;
    int healthyCount = entries.where((e) => e.foodType == 'healthy').length;
    int balancedCount = entries.where((e) => e.foodType == 'balanced').length;
    
    int junkCalories = entries
        .where((e) => e.foodType == 'junk')
        .fold(0, (sum, e) => sum + e.calories);
    int healthyCalories = entries
        .where((e) => e.foodType == 'healthy')
        .fold(0, (sum, e) => sum + e.calories);
    int fiber = entries.fold(0, (sum, e) => sum + e.fiber);

    String advice = '';
    
    // If ate both junk AND healthy - BALANCED diet
    if (junkCount > 0 && healthyCount > 0) {
      advice = '⚖️ BALANCED APPROACH!\n';
      advice += 'Junk: $junkCalories cal | Healthy: $healthyCalories cal\n';
      advice += 'Fiber: $fiber g (target: 25g)\n\n';
      advice += '🥗 BALANCE WITH FOOD:\n';
      if (fiber < 10) {
        advice += '🥬 Eat NOW: Spinach, Green Gram, or Salad\n';
      }
      advice += '🥕 Add fiber to next meal\n';
      advice += '💧 Drink: Buttermilk or Fresh juice\n\n';
      advice += '💪 OR LIGHT EXERCISE:\n';
      advice += '🚶 Walk ${(junkCalories / 5).ceil()} min\n';
      advice += '🧘 Yoga ${(junkCalories / 4).ceil()} min';
      return advice;
    }
    
    // If ONLY ate junk
    if (junkCount > 0 && healthyCount == 0) {
      advice = '⚠️ JUNK OVERLOAD ($junkCalories cal)\n';
      advice += 'Balance with HEALTHY foods, not just exercise!\n';
      advice += 'Fiber: $fiber g (need: 25g)\n\n';
      advice += '🥗 BALANCE OPTIONS:\n';
      advice += '1️⃣ Eat NOW: Green Gram or Lentil soup (high fiber)\n';
      advice += '2️⃣ Next meal: Add Spinach/Broccoli\n';
      advice += '3️⃣ Drink: Buttermilk or Fresh juice\n\n';
      advice += '💪 OR Exercise: ${_getExerciseRecommendation(junkCalories)}';
      return advice;
    }
    
    // If ONLY ate healthy
    if (healthyCount > 0 && junkCount == 0) {
      if (todayCalories < dailyGoal * 0.6) {
        advice = '🥗 Great! All healthy food!\n';
        advice += 'But eating too little ($todayCalories cal)\n';
        advice += 'Add more: Nuts, Rice, or Healthy grains\n';
        advice += 'Fiber: $fiber g ✅ (Goal: 25g)';
      } else {
        advice = '✅ PERFECT DAY!\n';
        advice += 'All healthy food ($todayCalories cal)\n';
        advice += 'Fiber: $fiber g ✅ Excellent!\n';
        advice += 'Keep this up tomorrow! 🌿';
      }
      return advice;
    }
    
    // If ate balanced foods (mixed junk+healthy or only balanced)
    if (balancedCount > 0) {
      advice = '⚖️ BALANCED DIET\n';
      advice += 'Total: $todayCalories cal\n';
      advice += 'Fiber: $fiber g\n';
      if (fiber < 15) {
        advice += '\n💡 Add fiber-rich food: Green Gram, Lentils, or Veggies';
      }
      return advice;
    }
    
    // Empty day
    if (entries.isEmpty) {
      return '🌅 No food logged yet!\n'
          'Start with: Breakfast with fiber\n'
          'Example: Idli (40 cal) + Green Gram (105 cal)\n'
          'Target: 25g fiber daily';
    }
    
    return 'Keep tracking! 🎯';
  }

  // Get exercise recommendation to burn junk food
  static String _getExerciseRecommendation(int junkCalories) {
    if (junkCalories == 0) return '💪 No junk food today!';
    
    int minutesRunning = (junkCalories / 10).ceil(); // ~10 cal per minute
    int minutesWalking = (junkCalories / 4).ceil();  // ~4 cal per minute
    int minutesYoga = (junkCalories / 3).ceil();     // ~3 cal per minute
    
    return 'EXERCISE TO BURN ($junkCalories cal):\n'
        '🏃 Run ${minutesRunning}min\n'
        '🚶 Walk ${minutesWalking}min\n'
        '🧘 Yoga ${minutesYoga}min\n\n'
        'OR BALANCE WITH FOOD:\n'
        '🥗 Eat Green Gram/Lentils (high fiber)\n'
        '🥬 Add Salad/Spinach with meal\n'
        '💧 Drink Buttermilk/Fresh juice';
  }

  // Estimate calories and fiber from food name with SMART type detection
  static (int, int, String) getCaloriesAndFiberFromFoodName(String foodName) {
    // Try exact match
    if (foodDatabase.containsKey(foodName)) {
      var data = foodDatabase[foodName]!;
      return (data['calories'], data['fiber'], data['type']);
    }

    // Try case-insensitive match
    final lowerName = foodName.toLowerCase();
    for (var entry in foodDatabase.entries) {
      if (entry.key.toLowerCase().contains(lowerName) ||
          lowerName.contains(entry.key.toLowerCase())) {
        var data = entry.value;
        return (data['calories'], data['fiber'], data['type']);
      }
    }

    // Smart detection based on food keywords
    return _detectFoodTypeFromName(foodName);
  }

  // Try to get food nutrition from online service (async version)
  // Falls back to local database if online fails or internet unavailable
  static Future<(int, int, String)> getCaloriesAndFiberFromFoodNameAsync(String foodName) async {
    try {
      // First, check local database
      if (foodDatabase.containsKey(foodName)) {
        var data = foodDatabase[foodName]!;
        return (data['calories'] as int, data['fiber'] as int, data['type'] as String);
      }

      // Try case-insensitive match in local database
      final lowerName = foodName.toLowerCase();
      for (var entry in foodDatabase.entries) {
        if (entry.key.toLowerCase().contains(lowerName) ||
            lowerName.contains(entry.key.toLowerCase())) {
          var data = entry.value;
          return (data['calories'] as int, data['fiber'] as int, data['type'] as String);
        }
      }

      // Try online service for foods not in local database
      print('🌐 Fetching nutrition data from online service for: $foodName');
      final result = await OnlineCalorieService.searchFoodNutrition(foodName);
      if (result != null) {
        print('✅ Got online data for: $foodName - ${result['calories']} cal');
        return (
          result['calories'] as int,
          result['fiber'] as int,
          result['type'] as String,
        );
      }
      
      print('⚠️ Online service returned null for: $foodName, using smart detection');
    } catch (e) {
      print('⚠️ Online service error, falling back to local detection: $e');
    }

    // Fallback to local smart detection
    return getCaloriesAndFiberFromFoodName(foodName);
  }

  // Detect if food is junk, healthy, or balanced based on keywords with better estimates
  static (int, int, String) _detectFoodTypeFromName(String foodName) {
    final lower = foodName.toLowerCase().trim();
    
    // JUNK FOOD KEYWORDS
    final junkKeywords = [
      'ice cream', 'icecream', 'dessert', 'desert', 'cake', 'candy', 'chocolate',
      'fried', 'burger', 'pizza', 'samosa', 'vada', 'pakora', 'chips',
      'fries', 'donut', 'pastry', 'cookie', 'biscuit', 'soda', 'coke',
      'pepsi', 'sugary', 'sweets', 'jalebi', 'gulab', 'barfi', 'laddu',
      'wafer', 'noodles instant', 'maggi', 'junk', 'fried', 'oil',
      'butter', 'cream', 'cheese', 'processed', 'snacks', 'popcorn',
      'brownie', 'fudge', 'toffee', 'cheesecake', 'pastry', 'fried rice',
    ];
    
    // HEALTHY FOOD KEYWORDS
    final healthyKeywords = [
      'salad', 'vegetable', 'broccoli', 'spinach', 'kale', 'lettuce',
      'carrot', 'tomato', 'cucumber', 'green', 'bean', 'lentil', 'dal',
      'sprout', 'chickpea', 'moong', 'gram', 'juice', 'fruit', 'apple',
      'banana', 'orange', 'milk', 'yogurt', 'curd', 'egg', 'white',
      'fish', 'chicken breast', 'turkey', 'lean', 'oat', 'wheat', 'whole',
      'nut', 'almond', 'walnut', 'healthy', 'organic', 'fresh',
    ];

    // PROTEIN FOOD KEYWORDS
    final proteinKeywords = [
      'chicken', 'meat', 'beef', 'mutton', 'lamb', 'pork', 'fish',
      'shrimp', 'crab', 'egg', 'tofu', 'paneer',
    ];

    // RICE/CARBS KEYWORDS
    final riceKeywords = [
      'rice', 'roti', 'chapati', 'bread', 'naan', 'paratha',
      'biryani', 'pulao', 'khichdi', 'porridge', 'oats',
    ];
    
    // Check junk keywords first - typically 200-300 cal
    for (var keyword in junkKeywords) {
      if (lower.contains(keyword)) {
        // Refine estimate based on specific type
        if (lower.contains('ice cream') || lower.contains('ice-cream')) {
          return (150, 0, 'junk'); // Ice cream: lighter
        } else if (lower.contains('burger') || lower.contains('pizza')) {
          return (500, 2, 'junk'); // Heavy fast food
        } else if (lower.contains('cake') || lower.contains('pastry')) {
          return (300, 1, 'junk'); // Desserts
        } else if (lower.contains('chips') || lower.contains('fries')) {
          return (350, 2, 'junk'); // Fried snacks
        } else {
          return (220, 1, 'junk'); // Generic junk: 220 cal
        }
      }
    }
    
    // Check healthy keywords - typically 80-150 cal
    for (var keyword in healthyKeywords) {
      if (lower.contains(keyword)) {
        if (lower.contains('fruit') || lower.contains('apple') || lower.contains('banana')) {
          return (95, 3, 'healthy'); // Fruits
        } else if (lower.contains('salad')) {
          return (120, 5, 'healthy'); // Salads
        } else if (lower.contains('juice')) {
          return (110, 2, 'healthy'); // Juices
        } else {
          return (100, 4, 'healthy'); // Other healthy: 100 cal
        }
      }
    }

    // Check protein keywords - typically 180-250 cal
    for (var keyword in proteinKeywords) {
      if (lower.contains(keyword)) {
        if (lower.contains('chicken breast')) {
          return (200, 0, 'balanced'); // Lean protein
        } else if (lower.contains('fish')) {
          return (210, 0, 'balanced'); // Fish
        } else {
          return (240, 0, 'balanced'); // Other meats
        }
      }
    }

    // Check rice/carbs keywords - typically 200-300 cal
    for (var keyword in riceKeywords) {
      if (lower.contains(keyword)) {
        if (lower.contains('rice')) {
          return (250, 2, 'balanced'); // Plain rice
        } else if (lower.contains('biryani')) {
          return (300, 2, 'balanced'); // Biryani (heavy)
        } else {
          return (200, 2, 'balanced'); // Other carbs
        }
      }
    }
    
    // Default to balanced for unknown foods - 180 cal average
    print('ℹ️ Using default detection for: $foodName');
    return (180, 2, 'balanced');
  }

  // Get all available foods for autocomplete
  static List<String> getAvailableFoods() {
    return foodDatabase.keys.toList();
  }
}
