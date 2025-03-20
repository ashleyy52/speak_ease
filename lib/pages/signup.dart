import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:new01/pages/userdetails.dart';
import 'login.dart';

// Custom scroll physics that prevents bouncing at the top
class CustomScrollPhysics extends BouncingScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Prevent bouncing only at the top (value < 0)
    if (value < position.minScrollExtent) {
      return value - position.minScrollExtent; // Clamp to top
    }

    if(value>0)
      {
        return value - position.minScrollExtent;
      }
    // Allow normal bouncing behavior at the bottom
    return super.applyBoundaryConditions(position, value);
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool obscurePassword = true;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDetailsPage(
            userId: userCredential.user!.uid,
            initialEmail: userCredential.user!.email ?? '',
          )),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Signup Failed!")),
        );
      }
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
              Color(0xFFBBDEFB), // Light blue
              Color(0xFF115DA6), // Darker blue
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const CustomScrollPhysics(), // Applied custom scroll physics
          child: Stack(
            children: [
              // Lottie Animation
              Positioned(
                top: screenHeight * 0.01,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: screenHeight * 0.60, // Matches LoginPage
                  child: Lottie.asset(
                    'assets/Lottie/hello.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.31), // Matches LoginPage spacing
                      const SizedBox(height: 40),
                      GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(24), // Matches LoginPage padding
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Input (Matched to LoginPage)
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

                                // Password Input (Matched to LoginPage)
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
                                    prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF323232).withOpacity(0.7), size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: const Color(0xFF323232).withOpacity(0.7),
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

                                // Forgot Password Section
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // Placeholder for forgot password logic
                                    },
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

                                // Register Button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFDAA40),
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
                      // "Or continue with" section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.5),
                                thickness: 0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.5),
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Social login buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(Icons.g_mobiledata, 'Google'),
                            const SizedBox(width: 16),
                            _buildSocialButton(Icons.apple, 'Apple'),
                            const SizedBox(width: 16),
                            _buildSocialButton(Icons.facebook, 'Facebook'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Center(
                          child: Text(
                            'Already Have an Account? Login',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
    );
  }

  Widget _buildSocialButton(IconData icon, String platform) {
    Color buttonColor;

    if (platform == 'Google') {
      buttonColor = const Color(0xFF42A5F5);
    } else if (platform == 'Apple') {
      buttonColor = const Color(0xFF1976D2);
    } else {
      buttonColor = const Color(0xFF64B5F6);
    }

    return InkWell(
      onTap: () {
        // Add social signup logic here if needed
      },
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Matches LoginPage
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1562B1).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.5), width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24), // Matches LoginPage
      child: child,
    );
  }
}