import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new01/pages/authentication.dart';
import 'package:new01/pages/splashScreen.dart';
import 'package:new01/pages/theme_provider.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LevelUnlockProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Speakease',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home:  SplashScreen(), // Start with SplashScreen
    );
  }
}

class GetStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late bool isLogin = false;
  late String username = 'null';

  Future<void> getStorage() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc('user1').get();
      if (userDoc.exists) {
        isLogin = userDoc['isLogin'] ?? false;
        username = userDoc['username'] ?? 'null';
      }
    } catch (e) {
      print("Error fetching Firestore data: $e");
    }
  }
}

final GetStorage storeClass = GetStorage();
