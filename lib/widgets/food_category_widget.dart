import 'package:flutter/material.dart';
import '../services/food_service.dart';
import '../services/food_recognition_service.dart';

class FoodCategoryWidget extends StatefulWidget {
  final Function(String foodName) onFoodSelected;
  final String language;

  const FoodCategoryWidget({
    super.key,
    required this.onFoodSelected,
    required this.language,
  });

  @override
  State<FoodCategoryWidget> createState() => _FoodCategoryWidgetState();
}

class _FoodCategoryWidgetState extends State<FoodCategoryWidget> {
  final Map<String, List<String>> foodCategories = {
    '🍛 Indian Breakfast': [
      'Idli (1 piece)',
      'Dosa (1)',
      'Uttapam (1)',
      'Upma (1 cup)',
      'Pesarattu (1)',
    ],
    '🍚 Rice & Curries': [
      'Rice + Sambar (1 plate)',
      'Rice + Rasam (1 plate)',
      'Dal Rice (1 plate)',
      'Biryani (1 cup)',
    ],
    '🥘 Curries': [
      'Chana Masala (1 cup)',
      'Dal Fry (1 cup)',
      'Sambar (1 cup)',
      'Paneer Butter Masala (1 cup)',
    ],
    '🥗 Vegetables': [
      'Brinjal Fry (1 cup)',
      'Okra Fry (1 cup)',
      'Spinach (1 cup)',
      'Carrot (1 medium)',
    ],
    '🍪 Snacks': [
      'Samosa (1)',
      'Pakora (1 piece)',
      'Vada (1)',
      'Roasted Chickpeas (1 cup)',
    ],
    '🍦 Ice Cream': [
      'arun butterscotch',
      'arun vanilla',
      'arun chocolate',
      'baskin robbins vanilla',
      'vadilal mango',
      'amul chocolate',
    ],
    '🍰 Sweets': [
      'Gulab Jamun (1)',
      'Jalebi (50g)',
      'Barfi (1 piece)',
      'Laddu (1)',
    ],
    '☕ Drinks': [
      'Lassi (1 cup)',
      'Buttermilk (1 cup)',
      'Fresh Juice (1 cup)',
      'Soft Drink (1 can)',
    ],
  };

  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> getFilteredFoods() {
    final search = searchController.text.toLowerCase();
    final allFoods = <String>[];
    
    foodCategories.forEach((_, foods) {
      allFoods.addAll(foods);
    });
    
    if (search.isEmpty) {
      return allFoods;
    }
    
    return allFoods.where((food) => food.toLowerCase().contains(search)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = getFilteredFoods();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search box
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search food...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Food list with categories
        Container(
          constraints: BoxConstraints(
            maxHeight: searchController.text.isEmpty ? 300 : 250,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView(
            children: searchController.text.isEmpty
                ? [
                    // Show categories when no search
                    ...foodCategories.entries.expand((entry) {
                      final category = entry.key;
                      final foods = entry.value;
                      return [
                        // Category header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Foods in category
                        ...foods.map((food) {
                          var data = _getFoodData(food);
                          String emoji = data?['type'] == 'junk'
                              ? '⚠️'
                              : data?['type'] == 'healthy'
                                  ? '✅'
                                  : '⚖️';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            title: Text('$emoji $food'),
                            subtitle: Text(
                              '${data?['calories'] ?? 0} cal • ${data?['fiber'] ?? 0}g fiber',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              widget.onFoodSelected(food);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        const Divider(height: 1),
                      ];
                    }).toList()
                  ]
                : [
                    // Show filtered results
                    ...filteredFoods.map((food) {
                      var data = _getFoodData(food);
                      String emoji = data?['type'] == 'junk'
                          ? '⚠️'
                          : data?['type'] == 'healthy'
                              ? '✅'
                              : '⚖️';
                      return ListTile(
                        title: Text('$emoji $food'),
                        subtitle: Text(
                          '${data?['calories'] ?? 0} cal • ${data?['fiber'] ?? 0}g fiber',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          widget.onFoodSelected(food);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _getFoodData(String food) {
    // Check ice cream database first
    var iceCreamData = FoodRecognitionService.iceCreamDatabase[food.toLowerCase()];
    if (iceCreamData != null) {
      return iceCreamData;
    }
    
    // Check regular food database
    return FoodService.foodDatabase[food];
  }
}
