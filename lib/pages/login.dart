import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart'; // For UserDetailsPage
import 'package:new01/pages/ui/userdetails.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'PhoneAuth.dart';
import 'authentication.dart';
import 'home_page.dart';
import 'signup.dart';

// Custom scroll physics that prevents bouncing at the top
class CustomScrollPhysics extends BouncingScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value > 0) {
      return value;
    }
    if (value < 0) {
      return value;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  bool obscurePassword = true;
  bool isLoading = false;
  String socialLoginProvider = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  // Helper method to check Firestore and navigate (used only for social logins)
  Future<void> _checkUserDetailsAndNavigate(User user) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        // User details exist, navigate to HomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } else {
        // No user details, navigate to UserDetailsPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UserDetailsPage(
              userId: user.uid,
              initialEmail: user.email ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error checking user details: ${e.toString()}');
    }
  }

  Future<void> _login() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );
        // Directly navigate to MyHomePage for email login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MyHomePage()),
        );
      } catch (e) {
        _showErrorSnackBar('Login failed: ${e.toString()}');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      socialLoginProvider = 'Google';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
          socialLoginProvider = '';
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _checkUserDetailsAndNavigate(userCredential.user!);
    } catch (e) {
      _showErrorSnackBar('Google sign-in failed: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
        socialLoginProvider = '';
      });
    }
  }

  Future<void> _signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _showErrorSnackBar('Apple Sign In is only supported on iOS and macOS devices');
      return;
    }

    setState(() {
      isLoading = true;
      socialLoginProvider = 'Apple';
    });

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

      UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      await _checkUserDetailsAndNavigate(userCredential.user!);
    } catch (e) {
      _showErrorSnackBar('Apple sign-in failed: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
        socialLoginProvider = '';
      });
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      isLoading = true;
      socialLoginProvider = 'Facebook';
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        await _checkUserDetailsAndNavigate(userCredential.user!);
      } else if (result.status == LoginStatus.cancelled) {
        // User canceled the sign-in flow
      } else {
        _showErrorSnackBar('Facebook login failed: ${result.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Facebook sign-in failed: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
        socialLoginProvider = '';
      });
    }
  }

  Future<void> _forgotPassword() async {
    final TextEditingController resetEmailController = TextEditingController();
    bool isResetEmailValid = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email address to receive a password reset link',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF8F9FA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Email address',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                      errorText: isResetEmailValid ? null : (resetEmailController.text.isEmpty ? null : 'Enter a valid email'),
                    ),
                    onChanged: (value) {
                      final bool isValid = RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]').hasMatch(value);
                      setDialogState(() {
                        isResetEmailValid = isValid;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: !isResetEmailValid ? null : () async {
                    Navigator.of(context).pop();
                    _sendPasswordResetEmail(resetEmailController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xfffc8482),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Password reset link sent to $email');
    } catch (e) {
      _showErrorSnackBar('Failed to send reset email: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AuthPage()),
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
        child: SingleChildScrollView(
          physics: const CustomScrollPhysics(),
          child: Stack(
            children: [
              Positioned(
                top: screenHeight * 0.01,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: screenHeight * 0.60,
                  child: Lottie.asset(
                    'assets/Lottie/hai.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 90, // Slightly adjusted for better balance
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME',
                        style: TextStyle(
                          fontFamily: 'Impact', // Use Impact font
                          fontSize: 64, // Reduced for elegance
                          //fontWeight: FontWeight.w600, // Slightly lighter for refinement
                          letterSpacing: 0.5, // Condensed for a polished look
                          height: 1.1, // Tighter line height
                          color: Colors.black, // Base color for ShaderMask
                        ),
                      ),

                      const SizedBox(height: 2), // Reduced spacing for compactness
                      Text(
                        'BACK!',
                        style: TextStyle(
                        fontFamily: 'Impact', // Use Impact font
                        fontSize: 64, // Reduced for elegance
                        //fontWeight: FontWeight.w600, // Slightly lighter for refinement
                        letterSpacing: 0.5, // Condensed for a polished look
                        height: 1.1, // Tighter line height
                        color: Color(0xfffdaa40), // Base color for ShaderMask
                      ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.28),
                      const SizedBox(height: 40),
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
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                  style: const TextStyle(color: Colors.black),
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Email is required!';
                                    } else if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]').hasMatch(value)) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFFF8F9FA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'name@example.com',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black38,
                                    ),
                                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                    errorStyle: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Password',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF323232),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  style: const TextStyle(color: Colors.black),
                                  controller: passController,
                                  obscureText: obscurePassword,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Password is required!';
                                    } else if (value.length < 6) {
                                      return 'Password must have at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFFF8F9FA),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: '••••••••',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black38,
                                    ),
                                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF323232).withOpacity(0.7), size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: Color(0xFF323232).withOpacity(0.7),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                    ),
                                    errorStyle: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      padding: const EdgeInsets.all(0),
                                    ),
                                    child: isLoading && socialLoginProvider.isEmpty
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(
                                      'Sign In',
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
                                color: Colors.black26,
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
                                color: Colors.black26,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don’t have an account?',
                            style: GoogleFonts.nunito(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            child: Text(
                              'Sign Up',
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
              if (isLoading && socialLoginProvider.isNotEmpty)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Signing in with $socialLoginProvider...',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform, VoidCallback onTap) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
          color: platform == 'Google'
              ? Colors.red
              : platform == 'Apple'
              ? Colors.black
              : Colors.blue,
          size: 28,
        ),
      ),
    );
  }
}

// Glassmorphism Container
class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 1.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: child,
      ),
    );
  }
}

InputDecoration inputDeco(String hint, IconData icon) {
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xffffffff),
    contentPadding: const EdgeInsets.all(15),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.black, width: .9),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.black, width: .9),
    ),
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 14,
      color: Color(0xFF454545),
    ),
    prefixIcon: Icon(icon, color: Colors.black),
  );
}