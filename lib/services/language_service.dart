import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'app_title': 'Arovia 🌿',
      'habits': 'Habits',
      'food': 'Food',
      'analytics': 'Analytics',
      'today_nutrition': '📊 Today\'s Nutrition',
      'consumed': 'Consumed',
      'daily_goal': 'Daily Goal',
      'goal': 'Goal',
      'remaining': '{cal} kcal remaining',
      'over_goal': '{cal} kcal over goal',
      'add_food': '🍽️ Add Food',
      'take_photo': 'Take Photo',
      'choose_photo': 'Choose Photo',
      'add_manual': 'Add Manually',
      'add_manually': 'Add Manually',
      'todays_foods': 'Today\'s Foods',
      'no_food_today': 'No foods added today',
      'no_foods': 'No foods added yet',
      'select_food_photo': 'Select Food from Photo',
      'what_did_you_eat': 'What did you eat?',
      'search_food': 'Search food',
      'quantity_serving': 'Quantity/Serving',
      'calories': 'cal',
      'fiber': 'g fiber',
      'add': 'Add',
      'cancel': 'Cancel',
      'junk_detected': '⚠️ Junk food detected! Balance with exercise today.',
      'junk_warning': '⚠️ Junk food! Balance with exercise today.',
      'you_had_junk': 'You had',
      'junk_items': 'junk items today!',
      'fiber_target': 'g fiber (target: 25g)',
      'to_burn': 'To burn this junk:',
      'run': 'Run',
      'walk': 'Walk',
      'yoga': 'Yoga',
      'min': 'min',
      'no_junk': '💪 No junk food today!',
      'eating_too_little': '🥗 You\'re eating too little! Add healthy snacks.',
      'good_progress': '🥗 Good progress! Keep balanced.',
      'perfect': '✅ Perfect! On track.',
      'language': 'Language',
      'english': 'English',
      'telugu': 'తెలుగు (Telugu)',
    },
    'te': {
      'app_title': 'Arovia 🌿',
      'habits': 'అలవాట్లు',
      'food': 'ఆహారం',
      'analytics': 'విశ్లేషణ',
      'today_nutrition': '📊 ఈ రోజు పోషణ',
      'consumed': 'తీసుకున్నవి',
      'daily_goal': 'రోజువారీ లక్ష్యం',
      'goal': 'లక్ష్యం',
      'remaining': '{cal} కెసిఎల్ మిగిలినవి',
      'over_goal': '{cal} కెసిఎల్ ఎక్కువ',
      'add_food': '🍽️ ఆహారం జోడించు',
      'take_photo': 'ఫోటో తీసుకోండి',
      'choose_photo': 'ఫోటో ఎంచుకోండి',
      'add_manual': 'మానవీయంగా జోడించు',
      'add_manually': 'మానవీయంగా జోడించు',
      'todays_foods': 'ఈ రోజు ఆహారం',
      'no_food_today': 'ఈ రోజు ఆహారం జోడించబడలేదు',
      'no_foods': 'ఇంకా ఆహారం జోడించబడలేదు',
      'select_food_photo': 'ఫోటో నుండి ఆహారం ఎంచుకోండి',
      'what_did_you_eat': 'మీరు ఏమి తిన్నారు?',
      'search_food': 'ఆహారం కోసం శోధించండి',
      'quantity_serving': 'పరిమాణం/సేవ',
      'calories': 'క్యాలరీ',
      'fiber': 'గ్రా ఫైబర్',
      'add': 'జోడించు',
      'cancel': 'రద్దు చేయండి',
      'junk_detected': '⚠️ జంక్ ఆహారం గుర్తించబడింది! ఈ రోజు వ్యాయామం తో సమతుల్యం చేయండి.',
      'junk_warning': '⚠️ జంక్ ఆహారం! వ్యాయామం తో సమతుల్యం చేయండి.',
      'you_had_junk': 'మీరు కలిగి ఉన్నారు',
      'junk_items': 'జంక్ అంశాలు ఈ రోజు!',
      'fiber_target': 'గ్రా ఫైబర్ (లక్ష్యం: 25 గ్రా)',
      'to_burn': 'ఈ జంక్ కాలను కాలిపోయుటకు:',
      'run': 'పరుగు',
      'walk': 'నడక',
      'yoga': 'యోగా',
      'min': 'నిమిషాలు',
      'no_junk': '💪 ఈ రోజు జంక్ ఆహారం లేదు!',
      'eating_too_little': '🥗 మీరు చాలా తక్కువ తిన్నారు! ఆరోగ్యకరమైన చిరుతిండి జోడించండి.',
      'good_progress': '🥗 మంచి పురోగతి! సమతుల్యంగా ఉంచండి.',
      'perfect': '✅ ఖచ్చితమైనది! ట్రాక్‌లో ఉన్నారు.',
      'language': 'భాష',
      'english': 'English',
      'telugu': 'తెలుగు (Telugu)',
    },
  };

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static String translate(String key, String language) {
    return translations[language]?[key] ?? translations['en']![key] ?? key;
  }

  static List<String> getAvailableLanguages() {
    return ['en', 'te'];
  }

  static String getLanguageName(String code) {
    return code == 'te' ? 'తెలుగు (Telugu)' : 'English';
  }
}
