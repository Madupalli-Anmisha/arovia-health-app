

class MealPlanService {
  // Suggest healthy foods to balance junk intake
  static Future<List<String>> suggestBalancingFoods(int junkCalories, int currentFiber) async {
    List<String> suggestions = [];
    
    // High fiber foods for balance
    final highFiberFoods = {
      'Green Gram (1 cup cooked)': 8,
      'Moong Dal (1 cup cooked)': 8,
      'Red Lentils (1 cup cooked)': 8,
      'Chickpeas (1 cup cooked)': 12,
      'Black Beans (1 cup cooked)': 15,
      'Spinach (1 cup)': 2,
      'Broccoli (1 cup)': 2,
      'Peas (1 cup)': 8,
      'Okra Fry (1 cup)': 3,
      'Salad with vegetables': 5,
    };

    // Sort by fiber content (highest first)
    var sortedFoods = highFiberFoods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Suggest top 3 highest fiber foods
    for (var food in sortedFoods.take(3)) {
      suggestions.add('✅ ${food.key} (+${food.value}g fiber)');
    }

    return suggestions;
  }

  // Create personalized meal plan for the day
  static Future<String> createDailyMealPlan({
    required int junkCaloriesEaten,
    required int currentFiber,
    required int totalCaloriesEaten,
  }) async {
    String plan = '';
    int caloriesRemaining = 2000 - totalCaloriesEaten;
    int fiberNeeded = 25 - currentFiber;

    plan = '📋 TODAY\'S MEAL PLAN\n';
    plan += '━━━━━━━━━━━━━━━━━━━\n';

    if (junkCaloriesEaten > 0) {
      plan += '\n⚠️ JUNK DETECTED ($junkCaloriesEaten cal)\n';
      plan += 'Need to BALANCE:\n\n';
      
      // Next meal suggestion
      plan += '🍽️ NEXT MEAL:\n';
      plan += '• Roti + Lentil curry\n';
      plan += '• Side: Spinach (adds fiber)\n';
      plan += '• Drink: Buttermilk\n';
      plan += 'Calories: ~300 cal\n';
      plan += 'Fiber: +6g\n\n';

      // Evening meal suggestion
      plan += '🌙 EVENING MEAL:\n';
      plan += '• Green Gram curry (or Moong Dal)\n';
      plan += '• Rice (small portion)\n';
      plan += '• Fresh salad\n';
      plan += 'Calories: ~250 cal\n';
      plan += 'Fiber: +8g\n\n';

      // Snack suggestion
      plan += '🥜 SNACK:\n';
      plan += '• Roasted chickpeas\n';
      plan += '• Fresh fruit\n';
      plan += 'Calories: ~100 cal\n';
      plan += 'Fiber: +4g\n\n';

      plan += '💪 EXERCISE NEEDED:\n';
      int runMin = (junkCaloriesEaten / 10).ceil();
      int walkMin = (junkCaloriesEaten / 4).ceil();
      plan += '• Run: $runMin min\n';
      plan += '• OR Walk: $walkMin min\n';
      plan += '• OR Yoga: ${(junkCaloriesEaten / 3).ceil()} min\n';
    } else {
      plan += '\n✅ ALL HEALTHY SO FAR!\n';
      plan += 'Keep it up with:\n\n';
      
      plan += '🍽️ NEXT MEAL:\n';
      plan += '• Idli + Sambar\n';
      plan += '• Fresh juice\n';
      plan += 'Calories: ~180 cal\n';
      plan += 'Fiber: +3g\n\n';

      plan += '🌙 EVENING:\n';
      plan += '• Vegetable curry with rice\n';
      plan += '• Salad\n';
      plan += 'Calories: ~300 cal\n';
      plan += 'Fiber: +5g\n\n';

      plan += '💪 OPTIONAL EXERCISE:\n';
      plan += '• Light yoga (20 min)\n';
      plan += '• Walk (30 min)\n';
    }

    plan += '\n📊 SUMMARY:\n';
    plan += 'Calories remaining: $caloriesRemaining cal\n';
    plan += 'Fiber to reach 25g: $fiberNeeded g\n';
    plan += 'Goal: BALANCED & HEALTHY! 🎯';

    return plan;
  }

  // Get detailed food suggestions with reasons
  static Future<String> getDetailedFoodSuggestions({
    required String mealType, // breakfast, lunch, snack, dinner
    required int calorieTarget,
    required int fiberTarget,
  }) async {
    String suggestion = '';

    switch (mealType) {
      case 'breakfast':
        suggestion = '🌅 BREAKFAST OPTIONS ($calorieTarget cal, $fiberTarget+ g fiber):\n\n';
        suggestion += '✅ BEST:\n';
        suggestion += '• Idli (40 cal) + Green Gram curry (105 cal)\n';
        suggestion += '• Sambar (80 cal) + Curd (100 cal)\n';
        suggestion += 'Total: 325 cal, 12g fiber\n\n';
        
        suggestion += '✅ GOOD:\n';
        suggestion += '• Pesarattu (140 cal) + Chutney (50 cal)\n';
        suggestion += '• Upma (160 cal) + Juice (100 cal)\n\n';
        
        suggestion += '⚠️ AVOID:\n';
        suggestion += '• Biryani + Sweets\n';
        suggestion += '• Fried foods\n';
        break;

      case 'lunch':
        suggestion = '🍽️ LUNCH OPTIONS ($calorieTarget cal, $fiberTarget+ g fiber):\n\n';
        suggestion += '✅ BEST:\n';
        suggestion += '• Dal Rice (240 cal) + Salad (50 cal)\n';
        suggestion += '• Sambar Rice (220 cal) + Rasam (40 cal)\n';
        suggestion += 'Total: 300-310 cal, 7g+ fiber\n\n';
        
        suggestion += '✅ GOOD:\n';
        suggestion += '• Lentil curry (200 cal) + Roti (70 cal)\n';
        suggestion += '• Chana Masala (200 cal) + Chapati (70 cal)\n\n';
        
        suggestion += '⚠️ AVOID:\n';
        suggestion += '• Biryani\n';
        suggestion += '• Butter Masala\n';
        suggestion += '• Fried chicken\n';
        break;

      case 'snack':
        suggestion = '🥜 SNACK OPTIONS ($calorieTarget cal, $fiberTarget+ g fiber):\n\n';
        suggestion += '✅ BEST:\n';
        suggestion += '• Roasted Chickpeas (120 cal, 4g fiber)\n';
        suggestion += '• Mixed Nuts (160 cal, 2g fiber)\n';
        suggestion += '• Fresh Fruit (80-120 cal)\n\n';
        
        suggestion += '✅ GOOD:\n';
        suggestion += '• Buttermilk (90 cal)\n';
        suggestion += '• Fresh Juice (120 cal, 1g fiber)\n';
        suggestion += '• Green Gram (105 cal, 8g fiber)\n\n';
        
        suggestion += '⚠️ AVOID:\n';
        suggestion += '• Chips\n';
        suggestion += '• Ice cream\n';
        suggestion += '• Pastries\n';
        break;

      case 'dinner':
        suggestion = '🌙 DINNER OPTIONS ($calorieTarget cal, $fiberTarget+ g fiber):\n\n';
        suggestion += '✅ BEST:\n';
        suggestion += '• Green Gram curry (105 cal) + Rice (100 cal)\n';
        suggestion += '• Lentil soup (150 cal) + Roti (70 cal)\n';
        suggestion += 'Total: 255-320 cal, 8g+ fiber\n\n';
        
        suggestion += '✅ GOOD:\n';
        suggestion += '• Fish curry (180 cal) + Roti (70 cal)\n';
        suggestion += '• Vegetable curry (120 cal) + Roti (70 cal)\n\n';
        
        suggestion += '⚠️ AVOID:\n';
        suggestion += '• Heavy fried foods\n';
        suggestion += '• Biryani\n';
        suggestion += '• Desserts\n';
        break;
    }

    return suggestion;
  }
}
