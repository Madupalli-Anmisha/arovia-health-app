import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class OnlineCalorieService {
  // Using USDA FoodData Central API (free, no API key needed for basic queries)
  static const String _baseUrl = 'https://fdc.nal.usda.gov/api/foods/search';
  
  // Alternative: Nutritionix API (requires free API key, but better data)
  // You can get free API key at: https://developer.nutritionix.com/
  static const String _nutritionixUrl = 'https://trackapi.nutritionix.com/v2/search/instant';

  // Cache to store recently searched foods (to reduce API calls)
  static final Map<String, Map<String, dynamic>> _calorieCache = {};

  /// Search for food nutrition data from online API
  /// Returns: {calories, fiber, protein, carbs, fat, type}
  static Future<Map<String, dynamic>?> searchFoodNutrition(String foodName) async {
    try {
      // Check cache first
      final cacheKey = foodName.toLowerCase().replaceAll(' ', '_');
      if (_calorieCache.containsKey(cacheKey)) {
        print('📦 Using cached data for: $foodName');
        return _calorieCache[cacheKey];
      }

      print('🌐 Searching online for: $foodName');

      // Try Nutritionix first (better for common foods)
      final nutritionixResult = await _searchNutritionix(foodName);
      if (nutritionixResult != null) {
        _calorieCache[cacheKey] = nutritionixResult;
        return nutritionixResult;
      }

      // Fallback to USDA FoodData Central
      final usdaResult = await _searchUSDA(foodName);
      if (usdaResult != null) {
        _calorieCache[cacheKey] = usdaResult;
        return usdaResult;
      }

      return null;
    } catch (e) {
      print('❌ Error searching food nutrition: $e');
      return null;
    }
  }

  /// Search using Nutritionix API (requires internet connection)
  static Future<Map<String, dynamic>?> _searchNutritionix(String foodName) async {
    try {
      final uri = Uri.parse(_nutritionixUrl).replace(
        queryParameters: {
          'query': foodName,
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse common results
        if (data['common'] != null && data['common'].isNotEmpty) {
          final food = data['common'][0];
          return {
            'foodName': food['food_name'] ?? foodName,
            'calories': (food['nf_calories'] ?? 0).toInt(),
            'fiber': (food['nf_dietary_fiber'] ?? 0).toInt(),
            'protein': (food['nf_protein'] ?? 0).toInt(),
            'carbs': (food['nf_total_carbohydrate'] ?? 0).toInt(),
            'fat': (food['nf_total_fat'] ?? 0).toInt(),
            'type': _determineFoodType((food['nf_calories'] ?? 0).toInt(), foodName),
            'source': 'nutritionix',
          };
        }

        // Check branded results
        if (data['branded'] != null && data['branded'].isNotEmpty) {
          final food = data['branded'][0];
          return {
            'foodName': food['food_name'] ?? foodName,
            'calories': (food['nf_calories'] ?? 0).toInt(),
            'fiber': (food['nf_dietary_fiber'] ?? 0).toInt(),
            'protein': (food['nf_protein'] ?? 0).toInt(),
            'carbs': (food['nf_total_carbohydrate'] ?? 0).toInt(),
            'fat': (food['nf_total_fat'] ?? 0).toInt(),
            'type': _determineFoodType((food['nf_calories'] ?? 0).toInt(), foodName),
            'source': 'nutritionix_branded',
            'brand': food['brand_name'] ?? '',
          };
        }
      }
    } catch (e) {
      print('⚠️ Nutritionix search failed: $e');
    }
    return null;
  }

  /// Search using USDA FoodData Central API (free, public data)
  static Future<Map<String, dynamic>?> _searchUSDA(String foodName) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'query': foodName,
          'pageSize': '1',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          final nutrients = _extractUSDANutrients(food);
          
          return {
            'foodName': food['description'] ?? foodName,
            'calories': nutrients['calories'],
            'fiber': nutrients['fiber'],
            'protein': nutrients['protein'],
            'carbs': nutrients['carbs'],
            'fat': nutrients['fat'],
            'type': _determineFoodType(nutrients['calories'] ?? 0, foodName),
            'source': 'usda_fdc',
          };
        }
      }
    } catch (e) {
      print('⚠️ USDA search failed: $e');
    }
    return null;
  }

  /// Extract nutrients from USDA food data
  static Map<String, int> _extractUSDANutrients(Map<String, dynamic> food) {
    int calories = 0;
    int fiber = 0;
    int protein = 0;
    int carbs = 0;
    int fat = 0;

    if (food['foodNutrients'] != null) {
      for (var nutrient in food['foodNutrients']) {
        final nutrientName = nutrient['nutrientName']?.toString().toLowerCase() ?? '';
        final value = (nutrient['value'] ?? 0).toDouble();

        if (nutrientName.contains('energy') && nutrientName.contains('kcal')) {
          calories = value.toInt();
        } else if (nutrientName.contains('fiber')) {
          fiber = value.toInt();
        } else if (nutrientName.contains('protein')) {
          protein = value.toInt();
        } else if (nutrientName.contains('carbohydrate') && !nutrientName.contains('fiber')) {
          carbs = value.toInt();
        } else if (nutrientName.contains('fat')) {
          fat = value.toInt();
        }
      }
    }

    return {
      'calories': calories,
      'fiber': fiber,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Determine food type (healthy/balanced/junk) based on calories and name
  static String _determineFoodType(int calories, String foodName) {
    final lower = foodName.toLowerCase();

    // Junk food indicators
    if (lower.contains('ice cream') || 
        lower.contains('candy') || 
        lower.contains('chocolate') ||
        lower.contains('cake') ||
        lower.contains('pizza') ||
        lower.contains('burger') ||
        lower.contains('fries') ||
        lower.contains('chips') ||
        lower.contains('samosa') ||
        lower.contains('vada') ||
        lower.contains('pakora') ||
        lower.contains('junk') ||
        calories > 350) {
      return 'junk';
    }

    // Healthy food indicators
    if (lower.contains('spinach') ||
        lower.contains('broccoli') ||
        lower.contains('carrot') ||
        lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('dal') ||
        lower.contains('salad') ||
        lower.contains('vegetable') ||
        lower.contains('fruit') ||
        lower.contains('healthy') ||
        calories < 100) {
      return 'healthy';
    }

    return 'balanced';
  }

  /// Clear cache if needed (useful for testing)
  static void clearCache() {
    _calorieCache.clear();
    print('✅ Calorie cache cleared');
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _calorieCache.length,
      'items': _calorieCache.keys.toList(),
    };
  }
}
