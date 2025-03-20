import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new01/pages/home_page.dart';
import 'package:new01/pages/authentication.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to next screen after 3 seconds
    Timer(const Duration(seconds: 7), () {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is logged in, go to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } else {
        // User is not logged in, go to Authentication Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff4a5f95), Color(0xff080441)],
          ),
        ),
        child: Center(
          child: LottieBuilder.asset('assets/Lottie/speak1.json'),
        ),
      ),
    );
  }
}
