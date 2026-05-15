import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class SmartNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize notifications
  static Future<void> initializeNotifications() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
    _initialized = true;
  }

  // Show notification
  static Future<void> showNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'arovia_notifications',
      'Health Reminders',
      channelDescription: 'Smart nutrition and fitness reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  // 🌅 MORNING NOTIFICATION - Daily Goals
  static Future<void> sendMorningGoalNotification() async {
    await showNotification(
      id: 1,
      title: '🌅 Good Morning! 🌿',
      body: 'Today\'s goals:\n'
          '• 2000 calories\n'
          '• 25g fiber\n'
          '• 10,000 steps\n'
          'Start with healthy breakfast!',
    );
  }

  // ⚠️ JUNK FOOD ALERT - Suggests balance
  static Future<void> sendJunkFoodNotification(
    String foodName,
    int junkCalories,
  ) async {
    int walkMinutes = (junkCalories / 4).ceil();
    int runMinutes = (junkCalories / 10).ceil();

    await showNotification(
      id: 2,
      title: '⚠️ Ate $foodName?',
      body: '$junkCalories cal junk detected!\n\n'
          'Balance options:\n'
          '🚶 Walk $walkMinutes min\n'
          '🏃 Run $runMinutes min\n'
          '🥬 Eat Green Gram or Salad',
    );
  }

  // 🥬 FIBER ALERT - Encourages healthy food
  static Future<void> sendLowFiberNotification(int currentFiber) async {
    int fiberNeeded = 25 - currentFiber;

    await showNotification(
      id: 3,
      title: '🥬 Low Fiber Alert!',
      body: 'Current: $currentFiber g\n'
          'Need: $fiberNeeded g more\n\n'
          'Eat now:\n'
          '✅ Green Gram (8g fiber)\n'
          '✅ Spinach (2g per cup)\n'
          '✅ Lentil soup (6g)',
    );
  }

  // 🏃 STEP MILESTONE - Celebrates progress
  static Future<void> sendStepMilestoneNotification(int steps) async {
    int caloriesBurnt = (steps * 0.05).toInt();
    String message = '';

    if (steps == 5000) {
      message = '🎉 5,000 Steps!\nBurnt ~250 calories!\nGreat progress!';
    } else if (steps == 7500) {
      message = '🚀 7,500 Steps!\nBurnt ~375 calories!\nAlmost there!';
    } else if (steps == 10000) {
      message = '🏆 10,000 STEPS!\nBurnt ~500 calories!\n🌟 Daily goal achieved!';
    }

    await showNotification(
      id: 4,
      title: '🏃 Step Milestone!',
      body: message,
    );
  }

  // 💪 EXERCISE REMINDER - Suggests workout
  static Future<void> sendExerciseReminder() async {
    await showNotification(
      id: 5,
      title: '💪 Time to Exercise!',
      body: 'Haven\'t exercised today?\n\n'
          'Try:\n'
          '🏃 15 min running\n'
          '🚶 30 min walking\n'
          '🧘 20 min yoga\n'
          'Check YouTube for videos!',
    );
  }

  // 💧 HYDRATION REMINDER
  static Future<void> sendHydrationReminder(int steps) async {
    await showNotification(
      id: 6,
      title: '💧 Drink Water!',
      body: 'You\'ve walked $steps steps!\n'
          'Stay hydrated:\n'
          '• 1 cup = 250ml\n'
          '• Target: 8 cups/day\n'
          'Have some buttermilk or juice!',
    );
  }

  // 📊 EVENING SUMMARY - Complete day analysis
  static Future<void> sendEveningSummaryNotification({
    required int steps,
    required int caloriesEaten,
    required int caloriesBurnt,
    required int fiber,
    required int junkCount,
    required int healthyCount,
  }) async {
    int netCalories = caloriesBurnt - caloriesEaten;
    String status = '';
    String emoji = '';

    if (junkCount > 0 && healthyCount > 0) {
      status = '⚖️ Balanced Day';
      emoji = 'Good work!';
    } else if (junkCount == 0 && healthyCount > 0) {
      status = '✅ Perfect Day';
      emoji = 'Excellent!';
    } else if (fiber >= 25) {
      status = '🥗 High Fiber';
      emoji = 'Great nutrition!';
    } else {
      status = '⚠️ More fiber needed';
      emoji = 'Try next time!';
    }

    await showNotification(
      id: 7,
      title: '📊 Today\'s Summary',
      body: '$status - $emoji\n\n'
          '🚶 Steps: $steps\n'
          '🍽️ Food: $caloriesEaten cal\n'
          '💪 Burnt: $caloriesBurnt cal\n'
          '🥬 Fiber: $fiber g (target: 25g)\n\n'
          'Net: ${netCalories > 0 ? "Deficit" : "Surplus"} $netCalories cal',
    );
  }

  // 🎯 PERSONALIZED MEAL SUGGESTION - Based on activity
  static Future<void> sendMealSuggestionNotification({
    required int steps,
    required int hoursActive,
  }) async {
    String meal = '';
    String reason = '';

    if (hoursActive < 4) {
      meal = '🥗 Light Lunch:\n'
          '• Salad with chickpeas\n'
          '• Fresh juice';
      reason = 'You\'ve been inactive';
    } else if (steps > 7000) {
      meal = '🥣 Energy Meal:\n'
          '• Rice + Dal + Spinach\n'
          '• Buttermilk';
      reason = 'You\'ve walked ${(steps / 1000).toStringAsFixed(1)}k steps!';
    } else {
      meal = '🥘 Balanced Meal:\n'
          '• Roti + Lentil curry\n'
          '• Green vegetable';
      reason = 'Time for lunch!';
    }

    await showNotification(
      id: 8,
      title: '🍽️ Meal Suggestion',
      body: '$reason\n\n$meal',
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Schedule daily notifications
  static Future<void> scheduleDailyNotifications() async {
    // Morning notification at 7 AM
    await _notificationsPlugin.zonedSchedule(
      1,
      '🌅 Good Morning!',
      'Set today\'s fitness goals',
      _nextInstanceOfTime(7, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'arovia_notifications',
          'Health Reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Exercise reminder at 5 PM
    await _notificationsPlugin.zonedSchedule(
      5,
      '💪 Exercise Time',
      'Have you worked out today?',
      _nextInstanceOfTime(17, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'arovia_notifications',
          'Health Reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Evening summary at 8 PM
    await _notificationsPlugin.zonedSchedule(
      7,
      '📊 Today\'s Summary',
      'Check your daily progress',
      _nextInstanceOfTime(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'arovia_notifications',
          'Health Reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Helper to get next instance of time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
