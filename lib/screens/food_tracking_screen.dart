import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/food_service.dart';
import '../services/food_recognition_service.dart';
import '../services/smart_notification_service.dart';
import '../services/meal_plan_service.dart';
import '../services/language_service.dart';
import 'weekly_report_screen.dart';
import 'personal_records_screen.dart';

class FoodTrackingScreen extends StatefulWidget {
  final String language;
  
  const FoodTrackingScreen({super.key, this.language = 'en'});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  List<FoodEntry> todayEntries = [];
  int todayCalories = 0;
  int todayFiber = 0;
  int junkCalories = 0;
  int dailyGoal = 2000;
  int fiberGoal = 25;
  String nutritionAdvice = '';
  final ImagePicker _imagePicker = ImagePicker();
  late String currentLanguage;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.language;
    _loadData();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await SmartNotificationService.initializeNotifications();
  }

  Future<void> _loadData() async {
    final entries = await FoodService.getTodayEntries();
    final calories = await FoodService.getTodayCalories();
    final goal = await FoodService.getDailyGoal();
    final advice = await FoodService.getNutritionAdvice();

    setState(() {
      todayEntries = entries;
      todayCalories = calories;
      dailyGoal = goal;
      nutritionAdvice = advice;
    });
  }

  Future<void> _addFoodFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    if (mounted) {
      _showFoodDialog(image.path);
    }
  }

  Future<void> _addFoodFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    if (mounted) {
      _showFoodDialog(image.path);
    }
  }

  void _showFoodDialog(String? imagePath) {
    final foodController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedFood = '';
    String foodName = '';

    // Food categories
    final Map<String, List<String>> foodCategories = {
      '🍛 Breakfast': ['Idli (1 piece)', 'Dosa (1)', 'Upma (1 cup)', 'Uttapam (1)'],
      '🍚 Rice & Curries': ['Rice + Sambar (1 plate)', 'Rice + Rasam (1 plate)', 'Dal Rice (1 plate)', 'Biryani (1 cup)'],
      '🥘 Curries': ['Dal Fry (1 cup)', 'Chana Masala (1 cup)', 'Paneer Butter Masala (1 cup)'],
      '🍪 Snacks': ['Samosa (1)', 'Vada (1)', 'Pakora (1 piece)'],
      '🍦 Ice Cream': ['arun butterscotch', 'arun vanilla', 'arun chocolate', 'baskin robbins vanilla', 'vadilal mango', 'amul chocolate'],
      '🍰 Sweets': ['Gulab Jamun (1)', 'Jalebi (50g)', 'Barfi (1 piece)'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('📱 Select Food'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                // Search box
                TextField(
                  controller: foodController,
                  onChanged: (val) {
                    setState(() {
                      foodName = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search or select below',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Categories or filtered results
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: foodController.text.isEmpty
                        ? // Show all categories
                        foodCategories.entries.expand((category) {
                            return [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
                                child: Text(
                                  category.key,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                              ...category.value.map((food) {
                                var data = _getFoodData(food);
                                String emoji = (data?['type'] == 'junk') ? '⚠️' : (data?['type'] == 'healthy') ? '✅' : '⚖️';
                                return ListTile(
                                  dense: true,
                                  title: Text('$emoji $food', style: const TextStyle(fontSize: 13)),
                                  subtitle: Text('${data?['calories'] ?? 0} cal', style: const TextStyle(fontSize: 11)),
                                  onTap: () {
                                    setState(() {
                                      selectedFood = food;
                                      foodController.text = food;
                                      foodName = food;
                                    });
                                  },
                                );
                              }).toList(),
                            ];
                          }).toList()
                        : // Show filtered results
                        [
                            ...foodCategories.values.expand((foods) => foods).where((food) => food.toLowerCase().contains(foodController.text.toLowerCase())).map((food) {
                              var data = _getFoodData(food);
                              String emoji = (data?['type'] == 'junk') ? '⚠️' : (data?['type'] == 'healthy') ? '✅' : '⚖️';
                              return ListTile(
                                dense: true,
                                title: Text('$emoji $food', style: const TextStyle(fontSize: 13)),
                                subtitle: Text('${data?['calories'] ?? 0} cal', style: const TextStyle(fontSize: 11)),
                                onTap: () {
                                  setState(() {
                                    selectedFood = food;
                                    foodController.text = food;
                                    foodName = food;
                                  });
                                },
                              );
                            }).toList(),
                          ],
                  ),
                ),
                
                if (foodName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., 1, 2 scoops',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: foodName.isEmpty
                  ? null
                  : () async {
                      var iceCreamData = FoodRecognitionService.iceCreamDatabase[foodName.toLowerCase()];
                      
                      late final int calories, fiber;
                      late final String foodType;
                      
                      if (iceCreamData != null) {
                        calories = iceCreamData['calories'];
                        fiber = iceCreamData['fiber'];
                        foodType = iceCreamData['type'];
                      } else {
                        // Use async version to fetch from online service if not in local DB
                        final (cal, fib, type) = await FoodService.getCaloriesAndFiberFromFoodNameAsync(foodName);
                        calories = cal;
                        fiber = fib;
                        foodType = type;
                      }

                      final entry = FoodEntry(
                        id: const Uuid().v4(),
                        foodName: foodName,
                        calories: calories,
                        quantity: quantityController.text,
                        fiber: fiber,
                        foodType: foodType,
                        timestamp: DateTime.now(),
                      );

                      await FoodService.addFoodEntry(entry);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();

                        if (foodType == 'junk') {
                          await SmartNotificationService.sendJunkFoodNotification(foodName, calories);
                          _showMealPlanDialog();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Added: $foodName ($calories cal)'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Add Food'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getFoodData(String food) {
    var iceCreamData = FoodRecognitionService.iceCreamDatabase[food.toLowerCase()];
    if (iceCreamData != null) return iceCreamData;
    return FoodService.foodDatabase[food];
  }

  void _showManualAddDialog() {
    final quantityController = TextEditingController(text: '1');
    String selectedFood = '';
    String foodName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(LanguageService.translate('add_manually', currentLanguage)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🔍 ${LanguageService.translate('search_food', currentLanguage)}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (val) {
                    setState(() {
                      foodName = val;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: LanguageService.translate('search_food', currentLanguage),
                    hintText: 'Dosa, Biryani, Sambar...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: FoodService.getAvailableFoods()
                        .where((food) =>
                            foodName.isEmpty ||
                            food.toLowerCase().contains(foodName.toLowerCase()))
                        .map((food) {
                          var data = FoodService.foodDatabase[food]!;
                          String emoji = data['type'] == 'junk'
                              ? '⚠️'
                              : data['type'] == 'healthy'
                              ? '✅'
                              : '⚖️';
                          bool isSelected = selectedFood == food;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.green.shade100,
                            title: Text('$emoji $food'),
                            subtitle: Text(
                              '${data['calories']} cal • ${data['fiber']}g',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                selectedFood = food;
                                foodName = food;
                              });
                            },
                          );
                        })
                        .toList(),
                  ),
                ),
                if (foodName.isNotEmpty && selectedFood != foodName) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: const Text(
                      '💡 Custom food - using default 200 cal',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
                if (foodName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(LanguageService.translate('quantity_serving', currentLanguage),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'e.g., 1, 2 pieces, 1 cup',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageService.translate('cancel', currentLanguage)),
            ),
            ElevatedButton(
              onPressed: foodName.isEmpty
                  ? null
                  : () async {
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('🔍 Finding nutrition info...'),
                            ],
                          ),
                        ),
                      );

                      try {
                        // Try to get online data first, falls back to local
                        final (calories, fiber, foodType) =
                            await FoodService.getCaloriesAndFiberFromFoodNameAsync(foodName);

                        final entry = FoodEntry(
                          id: const Uuid().v4(),
                          foodName: foodName,
                          calories: calories,
                          quantity: quantityController.text,
                          fiber: fiber,
                          foodType: foodType,
                          timestamp: DateTime.now(),
                        );

                        await FoodService.addFoodEntry(entry);

                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close food dialog
                          _loadData();

                          if (foodType == 'junk') {
                            // AUTO-TRIGGER NOTIFICATION
                            await SmartNotificationService.sendJunkFoodNotification(
                              foodName,
                              calories,
                            );
                            
                            // Show meal plan dialog
                            _showMealPlanDialog();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ Junk food! Consider healthier options.'),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Added: $foodName ($calories cal)'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error adding food: $e');
                        if (mounted) {
                          Navigator.pop(context); // Close loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(LanguageService.translate('add', currentLanguage)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFoodEntry(FoodEntry entry) async {
    await FoodService.deleteFoodEntry(entry.id);
    _loadData();
  }

  void _showMealPlanDialog() async {
    final mealPlan = await MealPlanService.createDailyMealPlan(
      junkCaloriesEaten: junkCalories,
      currentFiber: todayFiber,
      totalCaloriesEaten: todayCalories,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📋 Daily Meal Plan'),
          content: SingleChildScrollView(
            child: SelectableText(
              mealPlan,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK, Got it!'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    currentLanguage = widget.language;
    final progress = todayCalories / dailyGoal;
    final caloriesRemaining = (dailyGoal - todayCalories).clamp(0, dailyGoal);
    final isOverGoal = todayCalories > dailyGoal;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Calorie Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 ${LanguageService.translate('today_nutrition', currentLanguage)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LanguageService.translate('consumed', currentLanguage),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '$todayCalories kcal',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                LanguageService.translate('daily_goal', currentLanguage),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '$dailyGoal kcal',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverGoal ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOverGoal
                                ? '⚠️ ${LanguageService.translate('over_goal', currentLanguage).replaceFirst('{cal}', '${todayCalories - dailyGoal}')}'
                                : '✅ ${LanguageService.translate('remaining', currentLanguage).replaceFirst('{cal}', caloriesRemaining.toStringAsFixed(0))}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isOverGoal ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition Advice Card
              Card(
                elevation: 2,
                color: Colors.lightBlue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nutritionAdvice,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick links to reports
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeeklyReportScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('📊 Weekly'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalRecordsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('🏆 Records'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add Food Buttons
              Text(
                '🍽️ ${LanguageService.translate('add_food', currentLanguage)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addFoodFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(LanguageService.translate('take_photo', currentLanguage)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addFoodFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: Text(LanguageService.translate('choose_photo', currentLanguage)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showManualAddDialog,
                  icon: const Icon(Icons.edit),
                  label: Text(LanguageService.translate('add_manual', currentLanguage)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Today's Food List
              Text(
                '📋 ${LanguageService.translate('todays_foods', currentLanguage)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (todayEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          LanguageService.translate('no_food_today', currentLanguage),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = todayEntries[index];
                    String emoji = entry.foodType == 'junk' ? '⚠️' : 
                                   entry.foodType == 'healthy' ? '✅' : '⚖️';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: entry.foodType == 'junk' 
                          ? Colors.red.shade50 
                          : entry.foodType == 'healthy'
                          ? Colors.green.shade50
                          : Colors.white,
                      child: ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(entry.foodName),
                        subtitle: Text(
                          '${entry.quantity} • ${entry.calories} cal • ${entry.fiber}g ${LanguageService.translate('fiber', currentLanguage)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFoodEntry(entry),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
