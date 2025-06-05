import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this for Firestore
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:new01/pages/ui/userdetails.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'home_page.dart';
import 'login.dart';

// Removed CustomScrollPhysics since we'll use default BouncingScrollPhysics
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Add Firestore instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool isLoading = false;

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  // Helper method to check if user details exist in Firestore and navigate accordingly
  Future<void> _navigateBasedOnUserDetails(User user) async {
    final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
    if (docSnapshot.exists) {
      // User details exist, navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } else {
      // New user, navigate to UserDetailsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailsPage(
            userId: user.uid,
            initialEmail: user.email ?? '',
          ),
        ),
      );
    }
  }

  // Email & Password Sign Up
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Successful!")),
        );

        await _navigateBasedOnUserDetails(userCredential.user!);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Signup Failed!")),
        );
      } finally {
        _setLoading(false);
      }
    }
  }

  // Google Sign In
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userCredential.additionalUserInfo?.isNewUser ?? false
            ? "Google Signup Successful!"
            : "Google Login Successful!")),
      );

      await _navigateBasedOnUserDetails(userCredential.user!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      _setLoading(false);
    }
  }

  // Facebook Sign In
  Future<void> _signInWithFacebook() async {
    _setLoading(true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw FirebaseAuthException(
          code: 'ERROR_FACEBOOK_LOGIN_FAILED',
          message: result.message ?? 'Facebook login failed',
        );
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.token);
      final userCredential = await _auth.signInWithCredential(credential);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userCredential.additionalUserInfo?.isNewUser ?? false
            ? "Facebook Signup Successful!"
            : "Facebook Login Successful!")),
      );

      await _navigateBasedOnUserDetails(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Facebook Sign-In Failed!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      _setLoading(false);
    }
  }

  // Apple Sign In
  Future<void> _signInWithApple() async {
    _setLoading(true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (credential.givenName != null && credential.familyName != null) {
        await userCredential.user?.updateDisplayName('${credential.givenName} ${credential.familyName}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userCredential.additionalUserInfo?.isNewUser ?? false
            ? "Apple Signup Successful!"
            : "Apple Login Successful!")),
      );

      await _navigateBasedOnUserDetails(userCredential.user!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Apple Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFCC80),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFDAA40),
                  ),
                ),
              ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // Use default BouncingScrollPhysics explicitly
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight, // Ensures content takes at least full screen height
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: screenHeight * 0.01,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: screenHeight * 0.50,
                        child: Lottie.asset(
                          'assets/Lottie/hi.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.31),
                            const SizedBox(height: 0),
                            GlassContainer(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Email',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF323232),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        style: const TextStyle(color: Colors.black),
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Email is required!';
                                          } else if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]').hasMatch(value)) {
                                            return 'Enter a valid email';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF8F9FA),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          hintText: 'name@example.com',
                                          hintStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black38,
                                          ),
                                          prefixIcon: Icon(Icons.email_outlined, color: const Color(0xFF323232).withOpacity(0.7), size: 20),
                                          errorStyle: const TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Password',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF323232),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        style: const TextStyle(color: Colors.black),
                                        controller: _passwordController,
                                        obscureText: obscurePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Password is required!';
                                          } else if (value.length < 6) {
                                            return 'Password must have at least 6 characters';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF8F9FA),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          hintText: '••••••••',
                                          hintStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black38,
                                          ),
                                          prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFFFC817D).withOpacity(0.7), size: 20),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                              color: const Color(0xFF1E1F22).withOpacity(0.7),
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                obscurePassword = !obscurePassword;
                                              });
                                            },
                                          ),
                                          errorStyle: const TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                      const SizedBox(height: 70),
                                      SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : _signUp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF5D2BAD),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                            padding: const EdgeInsets.all(0),
                                          ),
                                          child: Text(
                                            'R E G I S T E R',
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
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withOpacity(0.5),
                                      thickness: 0.5,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Or continue with',
                                      style: GoogleFonts.nunito(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.black.withOpacity(0.5),
                                      thickness: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(Icons.g_mobiledata, 'Google', _signInWithGoogle),
                                  const SizedBox(width: 16),
                                  _buildSocialButton(Icons.apple, 'Apple', _signInWithApple),
                                  const SizedBox(width: 16),
                                  _buildSocialButton(Icons.facebook, 'Facebook', _signInWithFacebook),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: GoogleFonts.nunito(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    'Log in',
                                    style: GoogleFonts.nunito(
                                      color: Colors.pinkAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform, VoidCallback onTap) {
    Color buttonColor;

    if (platform == 'Google') {
      buttonColor = const Color(0xFF42A5F5);
    } else if (platform == 'Apple') {
      buttonColor = const Color(0xFF000000);
    } else {
      buttonColor = const Color(0xFF2195F1);
    }

    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: platform == 'Google'
            ? Image.asset(
          'assets/images/google.png',
          width: 28,
          height: 28,
        )
            : Icon(
          icon,
          color: buttonColor,
          size: 28,
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}