import 'package:http/http.dart' as http;
import 'dart:convert';

class EnhancedFoodService {
  // Nutritionix API - FREE, no key needed, covers 1M+ foods
  static const String _nutritionixUrl = 'https://trackapi.nutritionix.com/v2/search/instant';
  static const String _nutritionixItemUrl = 'https://trackapi.nutritionix.com/v2/search/item';
  
  // USDA FoodData Central - FREE alternative
  static const String _usdaUrl = 'https://fdc.nal.usda.gov/api/foods/search';
  
  // Cache recently searched foods
  static final Map<String, Map<String, dynamic>> _foodCache = {};
  
  /// Search for ANY food (uses Nutritionix API - covers 1M+ foods worldwide)
  /// Returns: {foodName, calories, protein, carbs, fat, fiber, type, source}
  static Future<Map<String, dynamic>?> searchFood(
    String foodName, {
    bool useCache = true,
  }) async {
    try {
      final cacheKey = foodName.toLowerCase().replaceAll(' ', '_');
      
      // Check cache
      if (useCache && _foodCache.containsKey(cacheKey)) {
        print('📦 Using cached data for: $foodName');
        return _foodCache[cacheKey];
      }
      
      print('🌐 Searching online for: $foodName');
      
      // Try Nutritionix first (better for common foods)
      final result = await _searchNutritionix(foodName);
      if (result != null) {
        _foodCache[cacheKey] = result;
        return result;
      }
      
      // Fallback to USDA
      final usdaResult = await _searchUSDA(foodName);
      if (usdaResult != null) {
        _foodCache[cacheKey] = usdaResult;
        return usdaResult;
      }
      
      return null;
    } catch (e) {
      print('❌ Error searching food: $e');
      return null;
    }
  }
  
  /// Search using Nutritionix (covers restaurant food + branded products)
  static Future<Map<String, dynamic>?> _searchNutritionix(String foodName) async {
    try {
      // First endpoint: instant search
      final instantUri = Uri.parse(_nutritionixUrl).replace(
        queryParameters: {'query': foodName},
      );
      
      final instantResponse = await http.get(instantUri).timeout(
        const Duration(seconds: 8),
      );
      
      if (instantResponse.statusCode == 200) {
        final data = jsonDecode(instantResponse.body);
        
        // Check branded items (products with nutrition info)
        if (data['branded'] != null && data['branded'].isNotEmpty) {
          return _parseNutritionixResult(data['branded'][0]);
        }
        
        // Check common items
        if (data['common'] != null && data['common'].isNotEmpty) {
          return _parseNutritionixResult(data['common'][0]);
        }
      }
      
      return null;
    } catch (e) {
      print('⚠️ Nutritionix instant search failed: $e');
      return null;
    }
  }
  
  /// Parse Nutritionix food result
  static Map<String, dynamic>? _parseNutritionixResult(Map<String, dynamic> food) {
    try {
      return {
        'foodName': food['food_name'] ?? 'Unknown',
        'calories': (food['nf_calories'] ?? 0).toInt(),
        'protein': (food['nf_protein'] ?? 0).toInt(),
        'carbs': (food['nf_total_carbohydrate'] ?? 0).toInt(),
        'fat': (food['nf_total_fat'] ?? 0).toInt(),
        'fiber': (food['nf_dietary_fiber'] ?? 0).toInt(),
        'type': _determineFoodType(
          calories: (food['nf_calories'] ?? 0).toInt(),
          fiber: (food['nf_dietary_fiber'] ?? 0).toInt(),
          foodName: food['food_name']?.toString() ?? '',
        ),
        'source': 'nutritionix',
        'brand': food['brand_name'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Search using USDA FoodData Central (free, comprehensive)
  static Future<Map<String, dynamic>?> _searchUSDA(String foodName) async {
    try {
      final uri = Uri.parse(_usdaUrl).replace(
        queryParameters: {
          'query': foodName,
          'pageSize': '1',
        },
      );
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          
          // Extract nutrients
          final calories = _extractNutrient(food, 'Energy');
          final protein = _extractNutrient(food, 'Protein');
          final carbs = _extractNutrient(food, 'Carbohydrate');
          final fat = _extractNutrient(food, 'Total lipid');
          final fiber = _extractNutrient(food, 'Fiber');
          
          return {
            'foodName': food['description'] ?? foodName,
            'calories': (calories ?? 0).toInt(),
            'protein': (protein ?? 0).toInt(),
            'carbs': (carbs ?? 0).toInt(),
            'fat': (fat ?? 0).toInt(),
            'fiber': (fiber ?? 0).toInt(),
            'type': _determineFoodType(
              calories: (calories ?? 0).toInt(),
              fiber: (fiber ?? 0).toInt(),
              foodName: food['description']?.toString() ?? '',
            ),
            'source': 'usda',
          };
        }
      }
      return null;
    } catch (e) {
      print('⚠️ USDA search failed: $e');
      return null;
    }
  }
  
  /// Extract nutrient value from USDA food data
  static double? _extractNutrient(Map<String, dynamic> food, String nutrientName) {
    try {
      final nutrients = food['foodNutrients'] as List?;
      if (nutrients != null) {
        for (var nutrient in nutrients) {
          final name = nutrient['nutrientName']?.toString() ?? '';
          if (name.contains(nutrientName)) {
            final value = nutrient['value'];
            if (value is num) return value.toDouble();
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
  
  /// Determine food type (healthy/balanced/junk) based on nutrition
  static String _determineFoodType({
    required int calories,
    required int fiber,
    required String foodName,
  }) {
    final nameLower = foodName.toLowerCase();
    
    // Check for explicit junk keywords
    final junkKeywords = [
      'candy', 'chocolate', 'cake', 'cookie', 'chips', 'fries', 'fried',
      'burger', 'pizza', 'soda', 'soft drink', 'ice cream', 'dessert',
      'pastry', 'donut', 'fast food', 'processed'
    ];
    
    if (junkKeywords.any((kw) => nameLower.contains(kw))) {
      return 'junk';
    }
    
    // Check for healthy keywords
    final healthyKeywords = [
      'vegetable', 'salad', 'fruit', 'spinach', 'broccoli', 'carrot',
      'dal', 'lentil', 'bean', 'sprout', 'leaf', 'leaf greens', 'herb'
    ];
    
    if (healthyKeywords.any((kw) => nameLower.contains(kw)) || fiber >= 5) {
      return 'healthy';
    }
    
    // Default to balanced
    return 'balanced';
  }
  
  /// Get suggested food alternatives based on what user ate
  static Future<List<String>> getSuggestedAlternatives({
    required String foodEaten,
    required List<String> allergies,
    required List<String> foodRestrictions,
  }) async {
    try {
      // Build suggestion prompt for alternatives
      final alternatives = <String>[];
      
      // Based on food eaten
      if (foodEaten.toLowerCase().contains('fried')) {
        alternatives.add('Grilled version of the same food');
        alternatives.add('Steamed version');
      }
      
      if (foodEaten.toLowerCase().contains('cream') ||
          foodEaten.toLowerCase().contains('butter')) {
        alternatives.add('Yogurt-based curry instead');
        alternatives.add('Light oil-based version');
      }
      
      if (foodEaten.toLowerCase().contains('sugar') ||
          foodEaten.toLowerCase().contains('sweet')) {
        alternatives.add('Fruit (natural sweetness)');
        alternatives.add('Dark chocolate (small portion)');
      }
      
      // Add healthy proteins
      if (!allergies.contains('dairy')) {
        alternatives.add('Curd with salad');
      }
      if (!allergies.contains('legumes')) {
        alternatives.add('Dal Rice');
        alternatives.add('Green Gram Sprout Salad');
      }
      
      return alternatives;
    } catch (e) {
      return ['Try adding leafy greens or lentils to balance'];
    }
  }
  
  /// Check if food is safe for health conditions
  static bool isFoodSafe({
    required String foodName,
    required List<String> foodRestrictions,
    required List<String> allergies,
  }) {
    final foodLower = foodName.toLowerCase();
    
    // Check allergies
    if (allergies.any((allergy) => foodLower.contains(allergy.toLowerCase()))) {
      return false;
    }
    
    // Check health condition restrictions
    if (foodRestrictions.any((restriction) => foodLower.contains(restriction.toLowerCase()))) {
      return false;
    }
    
    return true;
  }
  
  /// Get comprehensive nutrition summary
  static String getNutritionSummary({
    required Map<String, dynamic> foodData,
    required int portion,
  }) {
    final multiplier = portion / 100; // Assume default serving is 100g
    
    final calories = (foodData['calories'] as int) * multiplier;
    final protein = (foodData['protein'] as int) * multiplier;
    final carbs = (foodData['carbs'] as int) * multiplier;
    final fat = (foodData['fat'] as int) * multiplier;
    final fiber = (foodData['fiber'] as int) * multiplier;
    
    return '''
${foodData['foodName']}
━━━━━━━━━━━━━━━━
🔥 Calories: ${calories.toStringAsFixed(0)} kcal
🥩 Protein: ${protein.toStringAsFixed(1)}g
🍞 Carbs: ${carbs.toStringAsFixed(1)}g
🧈 Fat: ${fat.toStringAsFixed(1)}g
🥬 Fiber: ${fiber.toStringAsFixed(1)}g
━━━━━━━━━━━━━━━━
''';
  }
  
  /// Clear cache to save memory
  static void clearCache() {
    _foodCache.clear();
    print('🗑️ Food cache cleared');
  }
}
