import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'profile_setup.dart';
import 'home_screen.dart';
import '../widgets/arovia_background.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<Map<String, dynamic>> profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
    final String? profilesString = prefs.getString('profiles_$currentUserId');

    if (profilesString != null) {
      final List decoded = jsonDecode(profilesString);
      setState(() {
        profiles = decoded.cast<Map<String, dynamic>>();
      });
    } else {
      setState(() {
        profiles = [];
      });
    }
  }

  Future<void> _selectProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeProfileId', profileId);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ✅ DELETE CONFIRMATION (CORRECT PLACE)
  Future<void> _confirmDelete(String profileId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('Are you sure you want to delete this profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final prefs = await SharedPreferences.getInstance();
    final String? currentUserId = prefs.getString('currentUserId');
    
    if (currentUserId == null) return;
    
    final profilesString = prefs.getString('profiles_$currentUserId');

    if (profilesString == null) return;

    List profilesList = jsonDecode(profilesString);
    profilesList.removeWhere((p) => p['id'] == profileId);

    await prefs.setString('profiles_$currentUserId', jsonEncode(profilesList));

    // If deleted profile was active → clear it
    final activeId = prefs.getString('activeProfileId');
    if (activeId == profileId) {
      await prefs.remove('activeProfileId');
    }

    _loadProfiles(); // refresh UI
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    await prefs.remove('activeProfileId');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 👈 IMPORTANT

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,

        title: const Text(
          "Select Profile 👤",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: AroviaBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: profiles.isEmpty
              ? const Center(
                  child: Text(
                    'No profiles found.\nAdd a new profile.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          profile['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Age: ${profile['age']}"),
                        onTap: () =>
                            _selectProfile(profile['id']),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDelete(profile['id']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4CAF50),
        child: const Icon(Icons.add),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final String? currentUserId = prefs.getString('currentUserId');
          
          if (currentUserId != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProfileSetupScreen(userId: currentUserId),
              ),
            );

            _loadProfiles(); // refresh after adding
          }
        },
      ),
    );
  }
}