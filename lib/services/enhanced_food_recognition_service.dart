import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

class EnhancedFoodRecognitionService {
  static final imageLabeler = GoogleMlKit.vision.imageLabeler();
  
  /// Recognize food from image using Google ML Kit
  /// Returns: recognized food labels with confidence scores
  static Future<List<FoodLabel>> recognizeFoodFromImage(String imagePath) async {
    try {
      print('🔍 Recognizing food in image...');
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await imageLabeler.processImage(inputImage);
      
      // Filter for food-related labels
      final foodLabels = labels
          .where((label) => _isFoodLabel(label.label))
          .map((label) => FoodLabel(
            name: label.label,
            confidence: label.confidence,
            rawScore: label.confidence,
          ))
          .toList();
      
      // Sort by confidence
      foodLabels.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      print('✅ Recognized labels: ${foodLabels.map((l) => '${l.name} (${(l.confidence*100).toStringAsFixed(1)}%)').join(', ')}');
      
      return foodLabels;
    } catch (e) {
      print('❌ Error recognizing food: $e');
      return [];
    }
  }
  
  /// Check if label is food-related
  static bool _isFoodLabel(String label) {
    final foodKeywords = [
      'food', 'dish', 'meal', 'appetizer', 'breakfast', 'lunch', 'dinner',
      'snack', 'dessert', 'bread', 'rice', 'curry', 'salad', 'soup',
      'meat', 'fish', 'chicken', 'vegetable', 'fruit', 'drink', 'beverage',
      'dosa', 'idli', 'biryani', 'pizza', 'burger', 'pasta', 'noodle',
      'cake', 'ice cream', 'tea', 'coffee', 'juice', 'milk', 'cheese'
    ];
    
    return foodKeywords.any((kw) => label.toLowerCase().contains(kw));
  }
  
  /// Extract best food guess from recognized labels
  static String? getBestFoodGuess(List<FoodLabel> labels) {
    if (labels.isEmpty) return null;
    
    // Return top label if confidence is decent
    if (labels[0].confidence > 0.5) {
      return labels[0].name;
    }
    
    // Otherwise return null (user should input manually)
    return null;
  }
  
  /// Get all recognized foods as suggestions
  static List<String> getFoodSuggestions(List<FoodLabel> labels) {
    return labels
        .where((l) => l.confidence > 0.3)
        .map((l) => l.name)
        .toList();
  }
  
  /// Cleanup
  static Future<void> dispose() async {
    await imageLabeler.close();
  }
}

class FoodLabel {
  final String name;
  final double confidence;
  final double rawScore;
  
  FoodLabel({
    required this.name,
    required this.confidence,
    required this.rawScore,
  });
  
  @override
  String toString() => '$name (${(confidence*100).toStringAsFixed(1)}%)';
}
