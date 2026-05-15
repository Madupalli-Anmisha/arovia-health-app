class FoodRecognitionService {
  // Ice cream brand database with calorie information
  static final Map<String, Map<String, dynamic>> iceCreamDatabase = {
    // Arun Ice Cream
    'arun butterscotch': {'calories': 120, 'fiber': 0, 'type': 'junk', 'brand': 'Arun'},
    'arun vanilla': {'calories': 110, 'fiber': 0, 'type': 'junk', 'brand': 'Arun'},
    'arun chocolate': {'calories': 130, 'fiber': 1, 'type': 'junk', 'brand': 'Arun'},
    'arun strawberry': {'calories': 115, 'fiber': 0, 'type': 'junk', 'brand': 'Arun'},
    'arun mango': {'calories': 125, 'fiber': 1, 'type': 'junk', 'brand': 'Arun'},
    'arun pistachio': {'calories': 135, 'fiber': 0, 'type': 'junk', 'brand': 'Arun'},
    
    // Baskin Robbins
    'baskin robbins butterscotch': {'calories': 150, 'fiber': 0, 'type': 'junk', 'brand': 'Baskin Robbins'},
    'baskin robbins vanilla': {'calories': 140, 'fiber': 0, 'type': 'junk', 'brand': 'Baskin Robbins'},
    'baskin robbins chocolate': {'calories': 160, 'fiber': 1, 'type': 'junk', 'brand': 'Baskin Robbins'},
    'baskin robbins cookie dough': {'calories': 170, 'fiber': 0, 'type': 'junk', 'brand': 'Baskin Robbins'},
    
    // Vadilal
    'vadilal butterscotch': {'calories': 115, 'fiber': 0, 'type': 'junk', 'brand': 'Vadilal'},
    'vadilal vanilla': {'calories': 105, 'fiber': 0, 'type': 'junk', 'brand': 'Vadilal'},
    'vadilal chocolate': {'calories': 125, 'fiber': 1, 'type': 'junk', 'brand': 'Vadilal'},
    'vadilal mango': {'calories': 120, 'fiber': 1, 'type': 'junk', 'brand': 'Vadilal'},
    'vadilal fruit and nut': {'calories': 140, 'fiber': 2, 'type': 'junk', 'brand': 'Vadilal'},
    
    // Amul
    'amul butterscotch': {'calories': 110, 'fiber': 0, 'type': 'junk', 'brand': 'Amul'},
    'amul vanilla': {'calories': 100, 'fiber': 0, 'type': 'junk', 'brand': 'Amul'},
    'amul chocolate': {'calories': 120, 'fiber': 1, 'type': 'junk', 'brand': 'Amul'},
    'amul mango': {'calories': 115, 'fiber': 1, 'type': 'junk', 'brand': 'Amul'},
    'amul kulfi': {'calories': 130, 'fiber': 0, 'type': 'junk', 'brand': 'Amul'},
    
    // Mother Dairy
    'mother dairy butterscotch': {'calories': 120, 'fiber': 0, 'type': 'junk', 'brand': 'Mother Dairy'},
    'mother dairy vanilla': {'calories': 110, 'fiber': 0, 'type': 'junk', 'brand': 'Mother Dairy'},
    'mother dairy chocolate': {'calories': 130, 'fiber': 1, 'type': 'junk', 'brand': 'Mother Dairy'},
    'mother dairy kesar pista': {'calories': 140, 'fiber': 1, 'type': 'junk', 'brand': 'Mother Dairy'},
    
    // Haagen Dazs (Premium)
    'haagen dazs butterscotch': {'calories': 170, 'fiber': 0, 'type': 'junk', 'brand': 'Haagen Dazs'},
    'haagen dazs vanilla': {'calories': 160, 'fiber': 0, 'type': 'junk', 'brand': 'Haagen Dazs'},
    'haagen dazs chocolate': {'calories': 180, 'fiber': 2, 'type': 'junk', 'brand': 'Haagen Dazs'},
    'haagen dazs strawberry': {'calories': 170, 'fiber': 1, 'type': 'junk', 'brand': 'Haagen Dazs'},
  };

  // Simple image-based food recognition using filename/user input
  static String? recognizeFoodFromImage(String? imagePath) {
    if (imagePath == null) return null;
    
    final fileName = imagePath.toLowerCase();
    
    // Check for ice cream keywords
    if (fileName.contains('ice') || fileName.contains('cream') || fileName.contains('icecream')) {
      // Try to detect brand from filename
      for (String brand in ['arun', 'baskin', 'vadilal', 'amul', 'mother', 'haagen']) {
        if (fileName.contains(brand)) {
          return brand;
        }
      }
      return 'ice_cream'; // Generic ice cream
    }
    
    // Check for other foods
    if (fileName.contains('dosa')) return 'Dosa (1)';
    if (fileName.contains('biryani')) return 'Biryani (1 cup)';
    if (fileName.contains('idli')) return 'Idli (1 piece)';
    if (fileName.contains('samosa')) return 'Samosa (1)';
    if (fileName.contains('pizza')) return 'Pizza (1 slice)';
    if (fileName.contains('burger')) return 'Burger (1)';
    if (fileName.contains('chocolate') || fileName.contains('choco')) return 'Chocolate Bar';
    if (fileName.contains('cake')) return 'Cake (1 slice)';
    
    return null;
  }

  // Get food details with better suggestions
  static Map<String, dynamic>? getFoodDetails(String? imagePath, String userInput) {
    final userInputLower = userInput.toLowerCase();
    
    // First check ice cream database
    for (String key in iceCreamDatabase.keys) {
      if (userInputLower.contains(key.split(' ')[0]) || // Check brand
          key.contains(userInputLower.split(' ')[0])) { // Check flavor
        return {
          ...iceCreamDatabase[key]!,
          'foodName': userInput,
        };
      }
    }
    
    // Check recognized food from image
    final recognizedFood = recognizeFoodFromImage(imagePath);
    if (recognizedFood != null && recognizedFood.startsWith('ice')) {
      // Show ice cream options
      return {
        'type': 'ice_cream_options',
        'recognized': true,
      };
    }
    
    return null;
  }

  // Get all available ice cream options
  static List<String> getIceCreamOptions() {
    return iceCreamDatabase.keys.toList();
  }

  // Get ice creams by brand
  static List<String> getIceCreamsByBrand(String brand) {
    return iceCreamDatabase.entries
        .where((e) => e.value['brand'] == brand)
        .map((e) => e.key)
        .toList();
  }

  // Get all brands
  static List<String> getAllBrands() {
    final brands = <String>{};
    for (var item in iceCreamDatabase.values) {
      brands.add(item['brand'] as String);
    }
    return brands.toList();
  }
}
