import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/profile_setup.dart';
import 'screens/profile_selector_screen.dart';
import 'services/notification_service.dart';
import 'services/smart_notification_service.dart';
import 'services/step_tracker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
  } catch (e) {
    print('Error initializing NotificationService: $e');
  }

  // Initialize other services in background (don't block app startup)
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      await SmartNotificationService.initializeNotifications();
      await SmartNotificationService.scheduleDailyNotifications();
    } catch (e) {
      print('Error initializing SmartNotificationService: $e');
    }
  });

  Future.delayed(const Duration(seconds: 1), () async {
    try {
      await StepTrackerService.initStepTracking();
    } catch (e) {
      print('Error initializing StepTrackerService: $e');
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arovia',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideStartScreen();
    });
  }

  Future<void> _decideStartScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in
      final String? currentUserId = prefs.getString('currentUserId');

      if (currentUserId == null) {
        // User not logged in → show login screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        // User is logged in → check for profiles
        final String? profilesString = prefs.getString('profiles_$currentUserId');
        final List profiles =
            profilesString != null ? jsonDecode(profilesString) : [];

        if (profiles.isEmpty) {
          // No profiles yet → create profile
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileSetupScreen(userId: currentUserId),
              ),
            );
          }
        } else {
          // Profiles exist → choose profile
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
            );
          }
        }
      }
    } catch (e) {
      print('Error in _decideStartScreen: $e');
      // Show error screen or fallback to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
