import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new01/pages/theme_provider.dart';
import 'package:new01/pages/update_profile.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'about.dart';
import 'authentication.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  File? _image;
  String? _imagePath; // Store image path locally
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _loadImagePath();
  }

  Future<void> _fetchUsername() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          setState(() {
            _username = docSnapshot['username'];
          });
        } else {
          setState(() {
            _username = user.displayName ?? 'UserName';
          });
        }
      } catch (e) {
        setState(() {
          _username = 'UserName';
        });
      }
    }
  }
  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all stored preferences
    await prefs.clear();

    // Reset level progress to Level 1
    await prefs.setInt('level_progress', 1);

    // Remove stored profile image path
    await prefs.remove('profile_image_${_auth.currentUser!.uid}');

    setState(() {
      _image = null;
      _imagePath = null;
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All data cleared. Restarting...")),
    );

    // Restart the app by navigating to the authentication screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) =>  AuthPage()), // Change to your login screen
          (route) => false,
    );
  }


  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_${_auth.currentUser!.uid}');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _imagePath = savedImagePath;
        _image = File(savedImagePath);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
        _imagePath = pickedFile.path;
      });

      // Save image path to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_${_auth.currentUser!.uid}', pickedFile.path);
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()), // Replace with your login/signup page widget
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: theme.textTheme.bodyLarge!.color),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? FontAwesomeIcons.sun
                  : FontAwesomeIcons.moon,
              color: theme.iconTheme.color,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                    theme.colorScheme.secondary.withOpacity(0.3),
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : user?.photoURL != null
                        ? NetworkImage(user!.photoURL!) as ImageProvider
                        : null,
                    child: _image == null && user?.photoURL == null
                        ? Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        color: theme.textTheme.bodyLarge!.color,
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(Icons.edit, color: theme.iconTheme.color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _username ?? 'username',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge!.color,
              ),
            ),
            Text(
              user?.email ?? 'user@gmail.com',
              style: TextStyle(color: theme.textTheme.bodySmall!.color),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const UpdateProfilePage()));
              },
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 24),
            ProfileListTile(
              icon: Icons.settings,
              text: 'Settings',
              onTap: () {},
              iconColor: theme.iconTheme.color,
              textColor: theme.textTheme.bodyLarge!.color,
            ),
            ProfileListTile(
              icon: Icons.supervisor_account,
              text: 'Child Management',
              onTap: () {},
              iconColor: theme.iconTheme.color,
              textColor: theme.textTheme.bodyLarge!.color,
            ),
            ProfileListTile(
              icon: Icons.info,
              text: 'About',
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const AboutPage()));
              },
              iconColor: theme.iconTheme.color,
              textColor: theme.textTheme.bodyLarge!.color,
            ),
            ProfileListTile(
              icon: Icons.info,
              text: 'Clear Data',
              onTap: _clearData,
              iconColor: theme.iconTheme.color,
              textColor: theme.textTheme.bodyLarge!.color,
            ),

            ProfileListTile(
              icon: Icons.logout,
              text: 'Logout',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const ProfileListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
      Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(
        text,
        style: TextStyle(
            color: textColor ?? Theme.of(context).textTheme.bodyLarge!.color),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
