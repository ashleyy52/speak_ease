import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../authentication.dart';
import '../home_page.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String? initialEmail;

  const UserDetailsPage({
    Key? key,
    required this.userId,
    this.initialEmail,
  }) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _emailController;

  bool _isCheckingUsername = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedImage = prefs.getString('profile_image_${widget.userId}');

    if (savedImage != null) {
      setState(() {
        _base64Image = savedImage;
      });
    }
  }

  Future<void> _saveProfileImage() async {
    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_${widget.userId}', base64Image);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _base64Image = null; // Clear the base64 image when a new image is picked
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<bool> _checkUsernameExists(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCheckingUsername = true;
      });

      bool usernameExists =
      await _checkUsernameExists(_usernameController.text.trim());

      setState(() {
        _isCheckingUsername = false;
      });

      if (!usernameExists) {
        // Save profile image to shared preferences
        await _saveProfileImage();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .set({
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'dob': _dobController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'hasProfilePicture': _profileImage != null || _base64Image != null,
        });

        _showSuccessSnackBar('User details saved successfully!');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        _showErrorSnackBar('Username already taken. Please choose another.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _cancelSignUp() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
          (route) => false,
    );
  }

  Widget _buildProfileImageWidget() {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: FileImage(_profileImage!),
      );
    } else if (_base64Image != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: MemoryImage(base64Decode(_base64Image!)),
      );
    } else {
      return Icon(
        Icons.person_outline,
        size: 60,
        color: Colors.deepPurple.withOpacity(0.7),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _cancelSignUp();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF323232), size: 20),
            ),
            onPressed: _cancelSignUp,
          ),
          title: Text(
            'Complete Your Profile',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
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
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR',
                                style: TextStyle(
                                  fontFamily: "Impact",
                                  fontSize: 40,
                                  color: Color(0xFF323232),
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'DETAILS',
                                style: TextStyle(
                                  fontFamily: "Impact",
                                  fontSize: 40,
                                  color: Color(0xFFFDAA40),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                _buildProfileImageWidget(),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Form Card
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
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name Input
                              Text(
                                'Name',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.black),
                                validator: (value) =>
                                value!.isEmpty ? 'Name is required' : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF8F9FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter your full name',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                  errorStyle: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Username Input
                              Text(
                                'Username',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.black),
                                validator: (value) =>
                                value!.isEmpty ? 'Username is required' : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF8F9FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Choose a unique username',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                  errorStyle: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth
                              Text(
                                'Date of Birth',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                validator: (value) =>
                                value!.isEmpty ? 'Date of birth is required' : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF8F9FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Select your date of birth',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                  errorStyle: TextStyle(color: Colors.redAccent),
                                ),
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 16),

                              // Phone Number
                              Text(
                                'Phone Number (Optional)',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                style: const TextStyle(color: Colors.black),
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF8F9FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter your phone number',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email
                              Text(
                                'Email',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF323232),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.black),
                                keyboardType: TextInputType.emailAddress,
                                enabled: widget.initialEmail == null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFF8F9FA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Enter your email address',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black38,
                                  ),
                                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isCheckingUsername ? null : _saveUserDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: _isCheckingUsername
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    'Submit',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      ),
    );
  }
}