import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/arovia_background.dart';
import 'profile_selector_screen.dart';
import 'profile_setup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoginMode = true;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersString = prefs.getString('users');
      final List users = usersString != null ? jsonDecode(usersString) : [];

      // Find user with matching email and password
      final userIndex = users.indexWhere((user) =>
          user['email'] == emailController.text &&
          user['password'] == passwordController.text);

      if (userIndex != -1) {
        // Login successful
        final userId = users[userIndex]['id'];
        await prefs.setString('currentUserId', userId);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                // Check if user has profiles
                final String? profilesString = prefs.getString('profiles_$userId');
                final List profiles =
                    profilesString != null ? jsonDecode(profilesString) : [];

                if (profiles.isEmpty) {
                  return ProfileSetupScreen(userId: userId);
                } else {
                  return const ProfileSelectionScreen();
                }
              },
            ),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signup() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersString = prefs.getString('users');
      final List users = usersString != null ? jsonDecode(usersString) : [];

      // Check if user already exists
      final userExists = users.any((user) => user['email'] == emailController.text);
      if (userExists) {
        setState(() {
          errorMessage = 'This email is already registered';
        });
        return;
      }

      // Create new user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      users.add({
        'id': userId,
        'email': emailController.text,
        'password': passwordController.text,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString('users', jsonEncode(users));
      await prefs.setString('currentUserId', userId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(userId: userId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AroviaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    isLoginMode ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Black for max contrast
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoginMode
                        ? 'Sign in to your account'
                        : 'Create a new account to get started',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87, // Dark gray-black
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // Login/Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (isLoginMode) {
                                _login();
                              } else {
                                _signup();
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isLoginMode ? 'Login' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Mode Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLoginMode
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isLoginMode = !isLoginMode;
                            errorMessage = null;
                            emailController.clear();
                            passwordController.clear();
                          });
                        },
                        child: Text(
                          isLoginMode ? 'Sign Up' : 'Login',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
