import 'package:http/http.dart' as http;
import 'dart:convert';
import 'health_profile_service.dart';

class LLMSuggestionService {
  // Using Groq API (FREE - 30 requests per minute, no credit card needed)
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Get free API key from: https://console.groq.com
  // For now, using a free inference endpoint (alternative: use local LLM Studio)
  
  // Alternative: HuggingFace Inference API (also free)
  static const String _huggingfaceUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2';
  
  // Cache suggestions to reduce API calls
  static final Map<String, String> _suggestionCache = {};
  
  /// Get personalized meal suggestion based on food consumed and health profile
  static Future<String> getMealSuggestion({
    required String foodConsumed,
    required int caloriesConsumed,
    required int dailyGoal,
    required int caloriesSoFar,
    required List<HealthCondition> healthConditions,
    required int age,
    required String gender,
  }) async {
    try {
      final cacheKey = '${foodConsumed}_${healthConditions.map((c) => c.name).join('_')}'.toLowerCase();
      
      // Check cache
      if (_suggestionCache.containsKey(cacheKey)) {
        return _suggestionCache[cacheKey]!;
      }
      
      // Build detailed prompt
      String prompt = _buildPrompt(
        foodConsumed: foodConsumed,
        caloriesConsumed: caloriesConsumed,
        dailyGoal: dailyGoal,
        caloriesSoFar: caloriesSoFar,
        healthConditions: healthConditions,
        age: age,
        gender: gender,
      );
      
      // Try Groq API first (if you have API key)
      final groqResponse = await _callGroqAPI(prompt);
      if (groqResponse != null && groqResponse.isNotEmpty) {
        _suggestionCache[cacheKey] = groqResponse;
        return groqResponse;
      }
      
      // Fallback to HuggingFace (free, no key needed)
      final hfResponse = await _callHuggingFaceAPI(prompt);
      if (hfResponse != null && hfResponse.isNotEmpty) {
        _suggestionCache[cacheKey] = hfResponse;
        return hfResponse;
      }
      
      // Last resort: return smart rule-based suggestion
      return _generateSmartSuggestion(
        foodConsumed: foodConsumed,
        healthConditions: healthConditions,
        caloriesSoFar: caloriesSoFar,
        dailyGoal: dailyGoal,
      );
    } catch (e) {
      print('❌ Error getting LLM suggestion: $e');
      return _generateSmartSuggestion(
        foodConsumed: foodConsumed,
        healthConditions: healthConditions,
        caloriesSoFar: caloriesSoFar,
        dailyGoal: dailyGoal,
      );
    }
  }
  
  /// Call Groq API (requires free API key from https://console.groq.com)
  static Future<String?> _callGroqAPI(String prompt) async {
    try {
      // If you don't have API key, this will return null and fallback to HF
      // To get API key: go to https://console.groq.com, sign up, get free key
      const String apiKey = ''; // Add your Groq API key here
      
      if (apiKey.isEmpty) {
        print('⚠️ Groq API key not set. Using HuggingFace...');
        return null;
      }
      
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mixtral-8x7b-32768', // Fast, free model from Groq
          'messages': [
            {
              'role': 'system',
              'content': 'You are a health-conscious nutrition advisor. Give concise, actionable meal suggestions in max 2 sentences.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 100,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? null;
      }
      return null;
    } catch (e) {
      print('⚠️ Groq API error: $e');
      return null;
    }
  }
  
  /// Call HuggingFace Inference API (free, no key needed for public models)
  static Future<String?> _callHuggingFaceAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_huggingfaceUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 100,
            'temperature': 0.7,
          }
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['generated_text'] ?? null;
        }
      }
      return null;
    } catch (e) {
      print('⚠️ HuggingFace API error: $e');
      return null;
    }
  }
  
  /// Build detailed prompt for LLM
  static String _buildPrompt({
    required String foodConsumed,
    required int caloriesConsumed,
    required int dailyGoal,
    required int caloriesSoFar,
    required List<HealthCondition> healthConditions,
    required int age,
    required String gender,
  }) {
    String conditionsList = healthConditions.isEmpty
        ? 'No specific health conditions'
        : healthConditions.map((c) => '${c.name} (${c.severity})').join(', ');
    
    int caloriesRemaining = dailyGoal - caloriesSoFar;
    
    return '''
You are an OpenAI-style nutrition advisor. Based on this info, give ONE concise, actionable meal suggestion (max 2 sentences):

Person: $age year old $gender
Health conditions: $conditionsList
Daily goal: $dailyGoal calories (${caloriesRemaining} remaining)

Just ate: $foodConsumed ($caloriesConsumed cal)
Total today: $caloriesSoFar/$dailyGoal cal

If they ate junk food, recommend balanced, nutrient-rich alternatives.
If calories are high, suggest lighter, high-fiber or protein-rich options.
Always keep recommendations safe for their health conditions.
Be encouraging, specific, and practical.
''';
  }
  
  /// Smart rule-based suggestion (fallback when LLM not available)
  static String _generateSmartSuggestion({
    required String foodConsumed,
    required List<HealthCondition> healthConditions,
    required int caloriesSoFar,
    required int dailyGoal,
  }) {
    final foodLower = foodConsumed.toLowerCase();
    final caloriesRemaining = dailyGoal - caloriesSoFar;
    
    // Detect if junk food
    final junkKeywords = ['ice cream', 'chips', 'cake', 'burger', 'pizza', 'fries', 'fried', 'chocolate', 'candy', 'soda'];
    final isJunk = junkKeywords.any((kw) => foodLower.contains(kw));
    
    // Build suggestion
    String suggestion = '';
    
    if (isJunk) {
      suggestion = '🍔➡️🥗 You had junk food! ';
      
      // Add health-specific advice
      if (healthConditions.any((c) => c.name.toLowerCase() == 'diabetes')) {
        suggestion += 'Balance with leafy greens or Dal (high fiber, low GI).\n';
        suggestion += '💡 Next meal: Rice + Sambar + Spinach';
      } else if (healthConditions.any((c) => c.name.toLowerCase() == 'pcod')) {
        suggestion += 'Eat high protein to stabilize blood sugar: Dal or Curd.\n';
        suggestion += '💡 Next meal: Moong Dal + Brown Rice + Broccoli';
      } else if (healthConditions.any((c) => c.name.toLowerCase() == 'high_bp')) {
        suggestion += 'Avoid salt! Try fresh juice or coconut water.\n';
        suggestion += '💡 Next meal: Vegetable Curry (low salt) + Roti';
      } else {
        suggestion += 'Balance with fiber & protein: Dal or Green Gram.\n';
        suggestion += '💡 Next meal: Dal Rice + Salad';
      }
    } else {
      suggestion = '✅ Great choice! ';
      
      if (caloriesRemaining < 300) {
        suggestion += 'Calories getting high. Eat light: Salad, Buttermilk, or Fruit.';
      } else {
        suggestion += 'You can enjoy a moderate meal next.';
      }
    }
    
    return suggestion;
  }
  
  /// Get daily motivation message (changes daily)
  static Future<String> getDailyMotivation({
    required int age,
    required int caloriesConsumed,
    required int dailyGoal,
    required List<HealthCondition> healthConditions,
  }) async {
    try {
      final cacheKey = 'motivation_${DateTime.now().day}';
      
      if (_suggestionCache.containsKey(cacheKey)) {
        return _suggestionCache[cacheKey]!;
      }
      
      String prompt = '''
You are a motivational health coach. Generate ONE encouraging message for someone with:
- Age: $age
- Daily goal: $dailyGoal calories
- Consumed today: $caloriesConsumed calories (${((caloriesConsumed/dailyGoal)*100).toStringAsFixed(0)}%)
- Health: ${healthConditions.isEmpty ? 'Healthy' : healthConditions.map((c) => c.name).join(', ')}

Be brief (1-2 sentences), positive, and personalized. Today is ${DateTime.now().toString().split(' ')[0]}.
''';
      
      final groqResponse = await _callGroqAPI(prompt);
      if (groqResponse != null && groqResponse.isNotEmpty) {
        _suggestionCache[cacheKey] = groqResponse;
        return groqResponse;
      }
      
      final hfResponse = await _callHuggingFaceAPI(prompt);
      if (hfResponse != null && hfResponse.isNotEmpty) {
        _suggestionCache[cacheKey] = hfResponse;
        return hfResponse;
      }
      
      // Fallback messages
      final messages = [
        '💪 You\'re doing great! Keep up the healthy eating habits.',
        '🎯 Stay focused on your goal. Every meal choice matters!',
        '✨ You\'re on track! Keep making healthy choices.',
        '🌟 Great discipline today! Keep it up.',
        '🥗 One step closer to your health goals!',
      ];
      
      return messages[DateTime.now().day % messages.length];
    } catch (e) {
      return '💪 You\'re doing great! Keep going!';
    }
  }
}
