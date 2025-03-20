import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerificationSent = false; // NEW: Track email verification

  DateTime? _lastUsernameChange;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userData = await _firestore.collection('users').doc(user.uid).get();

    setState(() {
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = userData['phone'] ?? '';
      final lastChange = userData['lastUsernameChange'];
      if (lastChange != null) {
        _lastUsernameChange = DateTime.parse(lastChange);
      }
    });
  }

  bool _canChangeUsername() {
    if (_lastUsernameChange == null) return true;
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _lastUsernameChange!.isBefore(oneMonthAgo);
  }

  /// Re-authenticate and request email change
  Future<void> _requestEmailUpdate() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final emailCredential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(emailCredential);
      await user.updateEmail(_emailController.text);
      await user.sendEmailVerification();

      setState(() {
        _isVerificationSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check your inbox.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update email: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Confirm email verification and update Firestore data
  Future<void> _verifyAndUpdateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Refresh user to check if email is verified
    await user.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      try {
        final updates = <String, dynamic>{};

        // Update username only if eligible
        if (_usernameController.text.isNotEmpty &&
            _usernameController.text != refreshedUser.displayName &&
            _canChangeUsername()) {
          updates['username'] = _usernameController.text;
          updates['lastUsernameChange'] = DateTime.now().toIso8601String();
        }

        // Update phone number
        if (_phoneController.text.isNotEmpty) {
          updates['phone'] = _phoneController.text;
        }

        // Update email in Firestore (now it's verified)
        updates['email'] = refreshedUser.email;

        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(refreshedUser.uid).update(updates);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        await _loadUserData();
        setState(() {
          _isVerificationSent = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'New Email'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password (for re-authentication)'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (!_isVerificationSent)
              ElevatedButton(
                onPressed: _requestEmailUpdate,
                child: const Text('Update Email & Profile'),
              ),
            if (_isVerificationSent)
              ElevatedButton(
                onPressed: _verifyAndUpdateProfile,
                child: const Text('I Verified My Email'),
              ),
          ],
        ),
      ),
    );
  }
}
