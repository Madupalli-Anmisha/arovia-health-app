import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HybridFoodService {
  // 30+ Vegetarian Indian foods (NO NON-VEG)
  static final Map<String, Map<String, dynamic>> localDatabase = {
    // Grains & Staples
    'rice': {'calories': 130, 'fiber': 0.4, 'type': 'balanced'},
    'roti': {'calories': 70, 'fiber': 1.5, 'type': 'healthy'},
    'bread': {'calories': 80, 'fiber': 2.0, 'type': 'healthy'},
    'jowar': {'calories': 110, 'fiber': 3.0, 'type': 'healthy'},
    'bajra': {'calories': 120, 'fiber': 2.5, 'type': 'healthy'},

    // Pulses & Legumes (HIGH PROTEIN)
    'dal': {'calories': 120, 'fiber': 6.0, 'type': 'healthy'},
    'green gram': {'calories': 105, 'fiber': 8.0, 'type': 'healthy'},
    'moong dal': {'calories': 105, 'fiber': 8.0, 'type': 'healthy'},
    'chickpea': {'calories': 140, 'fiber': 10.0, 'type': 'healthy'},
    'lentil': {'calories': 115, 'fiber': 8.0, 'type': 'healthy'},
    'kidney bean': {'calories': 127, 'fiber': 8.5, 'type': 'healthy'},
    'black bean': {'calories': 132, 'fiber': 8.0, 'type': 'healthy'},

    // Curries & Cooked Items (VEG ONLY)
    'biryani': {'calories': 280, 'fiber': 2.0, 'type': 'junk'},
    'sambar': {'calories': 80, 'fiber': 3.0, 'type': 'healthy'},
    'rasam': {'calories': 40, 'fiber': 1.0, 'type': 'healthy'},
    'vegetable curry': {'calories': 120, 'fiber': 4.0, 'type': 'healthy'},

    // Vegetables (HIGH FIBER)
    'spinach': {'calories': 23, 'fiber': 2.0, 'type': 'healthy'},
    'broccoli': {'calories': 34, 'fiber': 2.0, 'type': 'healthy'},
    'carrot': {'calories': 41, 'fiber': 3.5, 'type': 'healthy'},
    'salad': {'calories': 50, 'fiber': 5.0, 'type': 'healthy'},
    'peas': {'calories': 81, 'fiber': 5.0, 'type': 'healthy'},
    'okra': {'calories': 33, 'fiber': 2.0, 'type': 'healthy'},
    'tomato': {'calories': 18, 'fiber': 1.5, 'type': 'healthy'},
    'cucumber': {'calories': 16, 'fiber': 0.5, 'type': 'healthy'},

    // Dairy (VEG PROTEIN)
    'curd': {'calories': 100, 'fiber': 0.0, 'type': 'healthy'},
    'milk': {'calories': 61, 'fiber': 0.0, 'type': 'healthy'},
    'paneer': {'calories': 265, 'fiber': 0.0, 'type': 'healthy'},
    'cheese': {'calories': 110, 'fiber': 0.0, 'type': 'balanced'},

    // Snacks
    'idli': {'calories': 40, 'fiber': 0.5, 'type': 'healthy'},
    'dosa': {'calories': 130, 'fiber': 1.5, 'type': 'balanced'},
    'samosa': {'calories': 120, 'fiber': 1.0, 'type': 'junk'},

    // Junk (NO MEAT-BASED)
    'ice cream': {'calories': 200, 'fiber': 0.0, 'type': 'junk'},
    'pizza': {'calories': 285, 'fiber': 1.0, 'type': 'junk'},
    'burger': {'calories': 250, 'fiber': 1.5, 'type': 'junk'},
    'chips': {'calories': 150, 'fiber': 1.0, 'type': 'junk'},
    'cake': {'calories': 300, 'fiber': 0.5, 'type': 'junk'},
    'soda': {'calories': 140, 'fiber': 0.0, 'type': 'junk'},
  };

  static const String _customFoodsKey = 'custom_foods_db';
  static const String _foodHistoryKey = 'food_history';

  // Get food from local database first
  static Future<Map<String, dynamic>?> getFood(String foodName) async {
    String normalized = foodName.toLowerCase().trim();

    // Check local database first
    if (localDatabase.containsKey(normalized)) {
      return localDatabase[normalized];
    }

    // Check custom foods saved locally
    final prefs = await SharedPreferences.getInstance();
    final customFoodsStr = prefs.getString(_customFoodsKey) ?? '{}';
    final Map<String, dynamic> customFoods = jsonDecode(customFoodsStr);

    if (customFoods.containsKey(normalized)) {
      return Map<String, dynamic>.from(customFoods[normalized]);
    }

    // Not found locally - try USDA API (if internet available)
    try {
      return await _searchUSDADatabase(foodName);
    } catch (e) {
      // If API fails, use smart keyword detection
      return _detectFoodByKeywords(foodName);
    }
  }

  // Search USDA FoodData Central API (FREE)
  static Future<Map<String, dynamic>?> _searchUSDADatabase(
      String foodName) async {
    try {
      // Using USDA FoodData Central Free API
      final url = Uri.parse(
        'https://fdc.nal.usda.gov/api/foods/search?query=$foodName&pageSize=1',
      );

      final response = await http.get(url).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          final foodName = food['description'] ?? 'Unknown';
          final calories = _extractNutrient(food, 'Energy') ?? 100;
          final fiber = _extractNutrient(food, 'Fiber') ?? 2;

          final Map<String, dynamic> result = {
            'calories': (calories).toInt(),
            'fiber': (fiber).toInt(),
            'type': _detectFoodType(fiber),
            'source': 'USDA API',
          };

          // Save to custom foods for future use
          await _saveCustomFood(foodName, result);
          return result;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Extract nutrient value from USDA food data
  static double? _extractNutrient(Map<String, dynamic> food, String nutrient) {
    try {
      final nutrients = food['foodNutrients'] as List?;
      if (nutrients != null) {
        for (var nutrient in nutrients) {
          if (nutrient['nutrientName'] != null &&
              nutrient['nutrientName'].toString().contains(nutrient)) {
            return nutrient['value'] as double?;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  // Smart keyword detection (fallback if API unavailable)
  static Map<String, dynamic> _detectFoodByKeywords(String foodName) {
    String lower = foodName.toLowerCase();

    // Junk keywords
    final junkKeywords = [
      'ice cream',
      'dessert',
      'desert',
      'cake',
      'candy',
      'chocolate',
      'fried',
      'burger',
      'pizza',
      'samosa',
      'vada',
      'pakora',
      'chips',
      'fries',
      'pastry',
      'soda',
      'coke',
      'pepsi'
    ];

    // Healthy keywords (VEGETARIAN + FOOD ITEMS, not just veggies)
    final healthyKeywords = [
      // South Indian items
      'idli',
      'dosa',
      'pesarattu',
      'upma',
      'sambar',
      'rasam',
      'gongura',
      'tamarind',
      
      // Food categories
      'salad',
      'vegetable',
      'curry',
      'dal',
      'pulse',
      'legume',
      
      // Vegetables (specific items)
      'broccoli',
      'spinach',
      'peas',
      'carrot',
      'tomato',
      'cucumber',
      'okra',
      'kale',
      'lettuce',
      'cabbage',
      'cauliflower',
      'beetroot',
      'radish',
      
      // Proteins
      'paneer',
      'tofu',
      'chickpea',
      'moong',
      'gram',
      'bean',
      'lentil',
      'egg',
      
      // Dairy
      'milk',
      'yogurt',
      'curd',
      'cheese',
      
      // Others
      'juice',
      'fruit',
      'nut',
      'almond',
      'walnut',
      'peanut',
      'sesame',
      'healthy',
      'organic',
      'fresh',
      
      // Telugu keywords
      'వరి',
      'రొటీ',
      'దాల్',
      'పెర్ణిక',
      'కూర',
      'గువ్వ',
      'పాలక్',
      'పెసరట్టు',
    ];

    for (var keyword in junkKeywords) {
      if (lower.contains(keyword)) {
        return {'calories': 180, 'fiber': 0, 'type': 'junk', 'source': 'Keyword'};
      }
    }

    for (var keyword in healthyKeywords) {
      if (lower.contains(keyword)) {
        return {
          'calories': 120,
          'fiber': 5,
          'type': 'healthy',
          'source': 'Keyword'
        };
      }
    }

    // Default: balanced
    return {
      'calories': 150,
      'fiber': 2,
      'type': 'balanced',
      'source': 'Default'
    };
  }

  // Detect food type from fiber content
  static String _detectFoodType(double fiber) {
    if (fiber >= 5) return 'healthy';
    if (fiber == 0) return 'junk';
    return 'balanced';
  }

  // Save custom food for future use (builds personal database)
  static Future<void> _saveCustomFood(
    String foodName,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodsStr = prefs.getString(_customFoodsKey) ?? '{}';
    final Map<String, dynamic> customFoods = jsonDecode(customFoodsStr);

    customFoods[foodName.toLowerCase()] = data;
    await prefs.setString(_customFoodsKey, jsonEncode(customFoods));
  }

  // Add food entry with source tracking
  static Future<void> addFoodEntry({
    required String foodName,
    required int calories,
    required int fiber,
    required String foodType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final historyKey = '$_foodHistoryKey:$today';

    final historyStr = prefs.getString(historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr);

    history.add({
      'foodName': foodName,
      'calories': calories,
      'fiber': fiber,
      'foodType': foodType,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(historyKey, jsonEncode(history));
  }

  // Get today's food entries
  static Future<List<Map<String, dynamic>>> getTodayFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final historyKey = '$_foodHistoryKey:$today';

    final historyStr = prefs.getString(historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr);

    return List<Map<String, dynamic>>.from(
      history.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // Get food history for a specific date
  static Future<List<Map<String, dynamic>>> getFoodsForDate(
      DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = date.toIso8601String().split('T')[0];
    final historyKey = '$_foodHistoryKey:$dateStr';

    final historyStr = prefs.getString(historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyStr);

    return List<Map<String, dynamic>>.from(
      history.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  // Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final prefs = await SharedPreferences.getInstance();
    final customFoodsStr = prefs.getString(_customFoodsKey) ?? '{}';
    final customFoods = jsonDecode(customFoodsStr) as Map;

    return {
      'localFoods': localDatabase.length,
      'customFoods': customFoods.length,
      'totalFoods': localDatabase.length + customFoods.length,
      'usingHybridMode': true,
    };
  }
}
