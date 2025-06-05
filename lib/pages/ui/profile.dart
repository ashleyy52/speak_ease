import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new01/pages/theme_provider.dart';
import 'package:new01/pages/ui/update_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Settings/settings.dart';
import 'about.dart';
import '../authentication.dart';
import 'child_management.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Uint8List? _image;
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
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
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
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('wordRecognized');
        await prefs.remove('level2_wordRecognized');
        await prefs.remove('level3_wordRecognized');
        await prefs.remove('level4_wordRecognized');
        await prefs.remove('level5_wordRecognized');
        await prefs.remove('level6_wordRecognized');
        await prefs.remove('level7_wordRecognized');
        await prefs.remove('level2Unlocked');
        await prefs.remove('level3Unlocked');
        await prefs.remove('level4Unlocked');
        await prefs.remove('level5Unlocked');
        await prefs.remove('level6Unlocked');
        await prefs.remove('level7Unlocked');
        await prefs.setInt('level_progress', 1);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reset game progress: $e")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    }
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImageBase64 = prefs.getString('profile_image_${_auth.currentUser!.uid}');
    if (savedImageBase64 != null) {
      setState(() {
        _image = base64Decode(savedImageBase64);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _image = bytes;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_${_auth.currentUser!.uid}', base64Image);
    }
  }

  void _viewProfileImage() {
    final user = FirebaseAuth.instance.currentUser;
    if (_image == null && user?.photoURL == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerPage(
          image: _image,
          imageUrl: user?.photoURL,
          username: _username ?? user?.displayName ?? 'User',
        ),
      ),
    );
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  Widget _buildProfileImageWidget() {
    final user = FirebaseAuth.instance.currentUser;
    if (_image != null) {
      return CircleAvatar(
        radius: 70,
        backgroundImage: MemoryImage(_image!),
      );
    } else if (user?.photoURL != null) {
      return CircleAvatar(
        radius: 70,
        backgroundImage: NetworkImage(user!.photoURL!),
      );
    } else {
      return CircleAvatar(
        radius: 70,
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        child: Icon(
          Icons.person_outline,
          size: 80,
          color: Colors.deepPurple.withOpacity(0.7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFCC80),
            ],
          ),
        ),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // Centered Profile Picture with Username and Email
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _viewProfileImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: _buildProfileImageWidget(),
                              ),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _username ?? 'Username',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF323232),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'user@gmail.com',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 20,color: Colors.white,),
                              const SizedBox(width: 8),
                              Text(
                                'Edit Profile',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Options Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildProfileOptionTile(
                            icon: Icons.settings,
                            text: 'Settings',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SettingsPage()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildProfileOptionTile(
                            icon: Icons.supervisor_account,
                            text: 'Child Management',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChildManagementPage()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildProfileOptionTile(
                            icon: Icons.info,
                            text: 'About',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AboutPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Clear Data/Logout Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildProfileOptionTile(
                            icon: Icons.delete_forever,
                            text: 'Clear Data',
                            onTap: _clearData,
                            isRed: true,
                          ),
                          _buildDivider(),
                          _buildProfileOptionTile(
                            icon: Icons.logout,
                            text: 'Logout',
                            onTap: () => signOut(context),
                            isRed: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOptionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isRed ? Colors.red : Color(0xFF323232).withOpacity(0.7),
        size: 22,
      ),
      title: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isRed ? Colors.red : Color(0xFF323232),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.withOpacity(0.2),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _ImageViewerPage extends StatefulWidget {
  final Uint8List? image;
  final String? imageUrl;
  final String username;

  const _ImageViewerPage({
    Key? key,
    this.image,
    this.imageUrl,
    required this.username,
  }) : super(key: key);

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;
  static const double _minScale = 0.8;
  static const double _maxScale = 5.0;
  static const double _doubleTapScale = 3.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      _isZoomed = false;
    } else {
      final Matrix4 newMatrix = Matrix4.identity()..scale(_doubleTapScale);
      _transformationController.value = newMatrix;
      _isZoomed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;
    if (widget.image != null) {
      content = Image.memory(widget.image!);
    } else if (widget.imageUrl != null) {
      content = Image.network(widget.imageUrl!);
    } else {
      content = Container(
        color: theme.colorScheme.secondary.withOpacity(0.3),
        child: Center(
          child: Text(
            widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 100, color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(
          widget.username,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Double-tap to zoom in/out or pinch to zoom'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Hero(
              tag: 'profile_image',
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}