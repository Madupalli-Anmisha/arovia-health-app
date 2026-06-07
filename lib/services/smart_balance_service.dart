import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'health_profile_service.dart';
import 'food_service.dart';
import 'enhanced_step_tracker_service.dart';

/// Smart recommendations based on food intake AND exercise
class SmartBalanceService {
  static final Map<String, String> _recommendationCache = {};

  /// Get comprehensive health recommendation based on food + exercise balance
  static Future<String> getBalancedRecommendation({
    required int todayCalories,
    required int dailyGoal,
    required int todaySteps,
    required int stepGoal,
    required List<FoodEntry> foodEntries,
    required String gender,
    required int age,
  }) async {
    try {
      final cacheKey = '${todayCalories}_${todaySteps}_${foodEntries.length}'.toLowerCase();
      
      if (_recommendationCache.containsKey(cacheKey)) {
        return _recommendationCache[cacheKey]!;
      }

      // Calculate balance metrics
      final calorieRatio = todayCalories / dailyGoal;
      final stepRatio = todaySteps / stepGoal;
      
      // Count junk vs healthy food
      int junkCount = foodEntries.where((e) => e.foodType == 'junk').length;
      int healthyCount = foodEntries.where((e) => e.foodType == 'healthy').length;
      
      // Calculate junk calorie percentage
      int junkCalories = foodEntries
          .where((e) => e.foodType == 'junk')
          .fold(0, (sum, entry) => sum + entry.calories);
      final junkRatio = todayCalories > 0 ? junkCalories / todayCalories : 0;

      // Generate smart recommendation
      String recommendation = _generateSmartRecommendation(
        calorieRatio: calorieRatio,
        stepRatio: stepRatio,
        junkRatio: junkRatio,
        junkCount: junkCount,
        healthyCount: healthyCount,
        todaySteps: todaySteps,
        todayCalories: todayCalories,
        dailyGoal: dailyGoal,
        stepGoal: stepGoal,
      );

      _recommendationCache[cacheKey] = recommendation;
      return recommendation;
    } catch (e) {
      developer.log('Error in SmartBalanceService: $e', name: 'SmartBalance', level: 900);
      return _getFallbackRecommendation();
    }
  }

  /// Generate smart contextual recommendation
  static String _generateSmartRecommendation({
    required double calorieRatio,
    required double stepRatio,
    required double junkRatio,
    required int junkCount,
    required int healthyCount,
    required int todaySteps,
    required int todayCalories,
    required int dailyGoal,
    required int stepGoal,
  }) {
    final underCalories = calorieRatio < 0.8;
    final overCalories = calorieRatio > 1.0;
    final lowSteps = stepRatio < 0.5;
    final goodSteps = stepRatio >= 0.8;
    final highJunk = junkRatio > 0.4;

    // Case 1: Eating junk + low steps - MOST URGENT
    if (highJunk && lowSteps) {
      int stepsNeeded = (stepGoal * 0.8 - todaySteps).toInt();
      return '''
⚠️ **BALANCE ALERT!**

You\'ve had $junkCount junk items (${(junkRatio * 100).toStringAsFixed(0)}% of calories), but only $todaySteps steps today.

**IMMEDIATE ACTION PLAN:**
1. 🚶 Go for a brisk walk: **Need ${stepsNeeded > 0 ? stepsNeeded : 'more'} more steps** to balance intake
2. 💪 Try 20 mins of moderate exercise (walk, jog, dance)
3. 🥗 For dinner, choose protein + greens (e.g., grilled chicken + salad)
4. 💧 Stay hydrated - drink water between meals

**Why?** Junk food + low activity = increased health risk. Exercise helps regulate blood sugar!
      '''.trim();
    }

    // Case 2: Eating healthy + good steps - GREAT!
    if (!highJunk && goodSteps) {
      return '''
✅ **EXCELLENT BALANCE!**

You\'re doing amazing! $healthyCount healthy choices + $todaySteps steps (${ (stepRatio * 100).toStringAsFixed(0)}%).

**Keep this up:**
- 🌟 Maintain this rhythm tomorrow
- 🎯 Your calorie intake: $todayCalories/$dailyGoal kcal
- 💪 You\'re burning calories through activity - great combo!

**Tip:** This balance helps improve metabolism and energy levels! 🔥
      '''.trim();
    }

    // Case 3: Eating junk but compensating with steps
    if (highJunk && goodSteps) {
      return '''
⚠️ **HIGH JUNK, HIGH ACTIVITY**

Good news: $todaySteps steps is excellent (${(stepRatio * 100).toStringAsFixed(0)}%)! 
But you had $junkCount junk items today.

**To improve:**
- 🥗 Tomorrow: Reduce junk by 50%, add more proteins & veggies
- 💪 Keep the exercise level - that\'s fantastic!
- 🍽️ Replace 1 junk item with healthier alternative

**Science fact:** Exercise doesn\'t fully offset junk food - diet quality matters! 🧬
      '''.trim();
    }

    // Case 4: Eating healthy but low steps
    if (!highJunk && lowSteps) {
      int stepsNeeded = (stepGoal * 0.8 - todaySteps).toInt();
      return '''
🥗 **GOOD DIET, TIME TO MOVE!**

Your food choices are great - $healthyCount healthy items! 
But you need more movement: $todaySteps/${stepGoal} steps.

**MOVE NOW:**
- 🚶 Walk for 20-30 mins: Need ~${ stepsNeeded > 0 ? stepsNeeded : 500} more steps
- 🎯 Aim for ${stepGoal ~/ 1000}K steps daily
- 💪 Any activity: walk, dance, stretch, clean house
- 🏃 Try these: stairs, parking farther away, standing desk

**Why?** Good diet + exercise = 💯 health gains! Alone, they\'re only 50% effective.
      '''.trim();
    }

    // Case 5: Under calories + good steps
    if (underCalories && goodSteps) {
      int caloriesNeeded = (dailyGoal - todayCalories).toInt();
      return '''
⚠️ **UNDER-EATING WITH HIGH ACTIVITY!**

Steps: $todaySteps (great! ${ (stepRatio * 100).toStringAsFixed(0)}%)
Calories: $todayCalories/$dailyGoal ($caloriesNeeded needed)

**FUEL YOUR ACTIVITY:**
- 🍎 Eat $caloriesNeeded more kcal of healthy food
- 🥜 Add: nuts, protein bars, lean meat, whole grains
- ⚡ Undereating + exercise = fatigue & muscle loss
- 💪 Recovery needs fuel!

**Action:** Add 1-2 healthy snacks today
      '''.trim();
    }

    // Case 6: Over calories + low steps
    if (overCalories && lowSteps) {
      int stepsNeeded = (stepGoal * 0.8 - todaySteps).toInt();
      int excessCalories = (todayCalories - dailyGoal).toInt();
      return '''
⚠️ **OVER GOAL - TIME TO MOVE!**

Calories: $todayCalories/$dailyGoal (+$excessCalories excess)
Steps: Only $todaySteps (need ~${ stepsNeeded > 0 ? stepsNeeded : 1000} more)

**BALANCE IT OUT:**
- 🚶 Go for a walk: 30 mins burns ~200 kcal
- 💪 Light exercise: stairs, yoga, dancing
- 🚫 No more heavy snacks today
- 💧 Drink water - sometimes hunger is thirst

**Goal:** Move ${ stepsNeeded > 0 ? stepsNeeded : 1000}+ steps today
      '''.trim();
    }

    // Case 7: Perfect calorie balance but low steps
    if (calorieRatio >= 0.85 && calorieRatio <= 1.0 && lowSteps) {
      int stepsNeeded = (stepGoal * 0.8 - todaySteps).toInt();
      return '''
✅ **CALORIE PERFECT, LET\'S ADD MOVEMENT!**

Food: $todayCalories/$dailyGoal kcal (right on target!) 🎯
Steps: $todaySteps (${(stepRatio * 100).toStringAsFixed(0)}% - could be better)

**QUICK WINS:**
- 🚶 30 min walk = better metabolism
- 🎯 Aim for ${ stepsNeeded > 0 ? stepsNeeded : 2000} more steps
- 💪 Any movement helps: stretch, dance, clean
- 🧘 Improves digestion after eating

**Combined = Perfect health! 🌟**
      '''.trim();
    }

    // Default case
    return _getFallbackRecommendation();
  }

  /// Fallback recommendation
  static String _getFallbackRecommendation() {
    return '''
💡 **HEALTH TIP**

Your balance of food & exercise shapes your health!

**3-Step Daily Plan:**
1. 🥗 Eat more greens, less junk
2. 🚶 Aim for 8,000+ steps
3. 💧 Drink plenty of water

Small changes = Big results! 🌟
    '''.trim();
  }

  /// Get emoji indicator for health balance
  static String getHealthEmoji({
    required int todayCalories,
    required int dailyGoal,
    required int todaySteps,
    required int stepGoal,
  }) {
    final calorieRatio = todayCalories / dailyGoal;
    final stepRatio = todaySteps / stepGoal;
    
    if (calorieRatio > 1.2 || stepRatio < 0.3) return '🔴'; // Critical
    if (calorieRatio > 1.0 || stepRatio < 0.5) return '🟡'; // Warning
    if (calorieRatio < 0.5 || stepRatio < 0.2) return '⚪'; // Under
    return '🟢'; // Good
  }
}



