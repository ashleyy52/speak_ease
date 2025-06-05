import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:new01/pages/ui/appointment.dart';
import 'package:new01/pages/ui/extraworks.dart';
import 'package:new01/pages/ui/profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'level/level_five_screen.dart';
import 'level/level_four_screen.dart';
import 'level/level_one_screen.dart';
import 'level/level_seven_screen.dart';
import 'level/level_six_screen.dart';
import 'level/level_three_screen.dart';
import 'level/level_two_screen.dart';



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late Animation<double> _glowAnimation;
  double level1Progress = 0.0;
  double level2Progress = 0.0;
  double level3Progress = 0.0;
  double level4Progress = 0.0;
  double level5Progress = 0.0;
  double level6Progress = 0.0;
  double level7Progress = 0.0;
  List<Appointment> _appointments = [];
  bool _isLoadingAppointments = true;
  String? userName; // To store the user's name from Firestore
  bool _isLoadingUserName = true; // Loading state for fetching the user's name

  @override
  void initState() {
    super.initState();
    _titleAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0, end: 10).animate(_titleAnimationController);
    _loadAllLevelsProgress();
    initializeAppointments().then((_) => _loadAppointments());
    _fetchUserName(); // Fetch the user's name from Firestore
  }

  // Fetch the user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['name'] ?? 'User';
            _isLoadingUserName = false;
          });
        } else {
          setState(() {
            userName = 'User';
            _isLoadingUserName = false;
          });
        }
      } else {
        setState(() {
          userName = 'User';
          _isLoadingUserName = false;
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        userName = 'User';
        _isLoadingUserName = false;
      });
    }
  }

  void _loadAllLevelsProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? savedRecognized1 = prefs.getStringList('wordRecognized');
      if (savedRecognized1 != null) {
        level1Progress = savedRecognized1.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized2 = prefs.getStringList('level2_wordRecognized');
      if (savedRecognized2 != null) {
        level2Progress = savedRecognized2.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized3 = prefs.getStringList('level3_wordRecognized');
      if (savedRecognized3 != null) {
        level3Progress = savedRecognized3.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized4 = prefs.getStringList('level4_wordRecognized');
      if (savedRecognized4 != null) {
        level4Progress = savedRecognized4.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized5 = prefs.getStringList('level5_wordRecognized');
      if (savedRecognized5 != null) {
        level5Progress = savedRecognized5.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized6 = prefs.getStringList('level6_wordRecognized');
      if (savedRecognized6 != null) {
        level6Progress = savedRecognized6.where((e) => e == 'true').length / 5;
      }
      List<String>? savedRecognized7 = prefs.getStringList('level7_wordRecognized');
      if (savedRecognized7 != null) {
        level7Progress = savedRecognized7.where((e) => e == 'true').length / 5;
      }
    });
  }

  // Calculate the number of completed levels
  int _calculateCompletedLevels() {
    int completedLevels = 0;
    List<double> levelsProgress = [
      level1Progress,
      level2Progress,
      level3Progress,
      level4Progress,
      level5Progress,
      level6Progress,
      level7Progress,
    ];

    for (double progress in levelsProgress) {
      if (progress >= 1.0) {
        completedLevels++;
      }
    }
    return completedLevels;
  }

  Future<void> _loadAppointments() async {
    final appointments = await AppointmentService.getAppointments();
    setState(() {
      _appointments = appointments;
      _isLoadingAppointments = false;
    });
  }

  Future<double> _getLevelProgress(String levelTask) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    double progress = 0.0;

    final levelNumber = int.tryParse(levelTask.replaceAll('Complete Level ', '')) ?? 0;
    if (levelNumber == 0) return 0.0;

    String key;
    switch (levelNumber) {
      case 1:
        key = 'wordRecognized';
        break;
      case 2:
        key = 'level2_wordRecognized';
        break;
      case 3:
        key = 'level3_wordRecognized';
        break;
      case 4:
        key = 'level4_wordRecognized';
        break;
      case 5:
        key = 'level5_wordRecognized';
        break;
      case 6:
        key = 'level6_wordRecognized';
        break;
      case 7:
        key = 'level7_wordRecognized';
        break;
      default:
        return 0.0;
    }

    List<String>? savedRecognized = prefs.getStringList(key);
    if (savedRecognized != null) {
      progress = savedRecognized.where((e) => e == 'true').length / 5;
    }

    return progress;
  }

  Future<bool> _areAllTasksCompleted(Appointment appointment) async {
    if (appointment.toDo.isEmpty) {
      return true;
    }

    for (String task in appointment.toDo) {
      double progress = await _getLevelProgress(task);
      if (progress < 1.0) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    super.dispose();
  }

  String _formatTimeTo12Hour(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the number of completed levels
    int completedLevels = _calculateCompletedLevels();

    return PopScope(
      canPop: false,
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
              child: const Icon(Icons.menu_rounded, color: Color(0xFF323232), size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ),
          ),
          title: Text(
            '',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          _isLoadingUserName
                              ? const CircularProgressIndicator(
                            color: Colors.deepPurple,
                          )
                              : Row(
                            children: [
                              Text(
                                'Hi, $userName',
                                style: TextStyle(
                                  fontFamily: "Impact",
                                  fontSize: 35,
                                  color: const Color(0xFF5A5656),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildSummaryBox(
                        'Progress',
                        Colors.deepPurple,
                        'Levels Completed: $completedLevels/7', // Update with dynamic value
                        Icons.star,
                      ),
                      const SizedBox(width: 15),
                      _buildPremiumAppointmentReminder(),
                      const SizedBox(width: 15),
                      _buildSummaryBox(
                        'Extra practice',
                        Colors.teal,
                        'Read the story',
                        Icons.workspace_premium,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StoryGenerationScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                    padding: const EdgeInsets.all(25.0),
                    child: Consumer<LevelUnlockProvider>(
                      builder: (context, levelUnlockProvider, child) {
                        return Column(
                          children: [
                            _buildEnhancedLevelContainer(
                              'assets/images/Level1.png',
                              '1',
                              'Simple Syllables',
                              const LinearGradient(
                                colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelOneScreen()))
                                  .then((_) => _loadAllLevelsProgress()),
                              isUnlocked: true,
                              progress: level1Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/level2.png',
                              '2',
                              'Short Words',
                              levelUnlockProvider.isLevelTwoUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFFFCCBC), Color(0xFFFFAB91)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelTwoUnlocked = prefs.getBool('level2Unlocked') ?? false;
                                levelUnlockProvider.isLevelTwoUnlocked = isLevelTwoUnlocked;
                                if (isLevelTwoUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelTwoScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 2);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelTwoUnlocked,
                              progress: level2Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/level3.png',
                              '3',
                              'Advanced Words',
                              levelUnlockProvider.isLevelThreeUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelThreeUnlocked = prefs.getBool('level3Unlocked') ?? false;
                                levelUnlockProvider.isLevelThreeUnlocked = isLevelThreeUnlocked;
                                if (isLevelThreeUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelThreeScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 3);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelThreeUnlocked,
                              progress: level3Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/level4.png',
                              '4',
                              'Food Words',
                              levelUnlockProvider.isLevelFourUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelFourUnlocked = prefs.getBool('level4Unlocked') ?? false;
                                levelUnlockProvider.isLevelFourUnlocked = isLevelFourUnlocked;
                                if (isLevelFourUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelFourScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 4);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelFourUnlocked,
                              progress: level4Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/Level1.png',
                              '5',
                              'Animal Words',
                              levelUnlockProvider.isLevelFiveUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelFiveUnlocked = prefs.getBool('level5Unlocked') ?? false;
                                levelUnlockProvider.isLevelFiveUnlocked = isLevelFiveUnlocked;
                                if (isLevelFiveUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelFiveScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 5);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelFiveUnlocked,
                              progress: level5Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/level2.png',
                              '6',
                              'Activities',
                              levelUnlockProvider.isLevelSixUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFFFB4B4), Color(0xFFFB9292)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelSixUnlocked = prefs.getBool('level6Unlocked') ?? false;
                                levelUnlockProvider.isLevelSixUnlocked = isLevelSixUnlocked;
                                if (isLevelSixUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelSixScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 6);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelSixUnlocked,
                              progress: level6Progress,
                            ),
                            const SizedBox(height: 20),
                            _buildEnhancedLevelContainer(
                              'assets/images/level3.png',
                              '7',
                              'Advanced Skills',
                              levelUnlockProvider.isLevelSevenUnlocked
                                  ? const LinearGradient(
                                colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : const LinearGradient(
                                colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                  () async {
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                bool isLevelSevenUnlocked = prefs.getBool('level7Unlocked') ?? false;
                                levelUnlockProvider.isLevelSevenUnlocked = isLevelSevenUnlocked;
                                if (isLevelSevenUnlocked) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => LevelSevenScreen()))
                                      .then((_) => _loadAllLevelsProgress());
                                } else {
                                  _showEnhancedLockedLevelDialog(context, 7);
                                }
                              },
                              isUnlocked: levelUnlockProvider.isLevelSevenUnlocked,
                              progress: level7Progress,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String title, Color color, String data, IconData icon, {String? subData, Function? onTap}) {
    return InkWell(
      onTap: onTap != null ? () => onTap() : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                data,
                style: GoogleFonts.nunito(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subData != null) ...[
                const SizedBox(height: 5),
                Text(
                  subData,
                  style: GoogleFonts.nunito(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAppointmentReminder() {
    if (_isLoadingAppointments) {
      return Container(
        width: 280,
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1A8FE3),
          ),
        ),
      );
    }

    Appointment? upcomingAppointment;
    if (_appointments.isNotEmpty) {
      final now = DateTime.now();
      final futureAppointments = _appointments
          .where((appointment) => appointment.date.isAfter(now))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      upcomingAppointment = futureAppointments.isNotEmpty ? futureAppointments.first : null;
    }

    if (upcomingAppointment == null) {
      return Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4ECDC4).withOpacity(0.9),
              Color(0xFF1A8FE3).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1A8FE3).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No upcoming appointments',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    int daysRemaining = upcomingAppointment.date.difference(DateTime.now()).inDays;

    return FutureBuilder<bool>(
      future: _areAllTasksCompleted(upcomingAppointment),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 280,
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A8FE3),
              ),
            ),
          );
        }

        bool allTasksCompleted = snapshot.data ?? false;
        final gradient = allTasksCompleted
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF66BB6A).withOpacity(0.9),
            Color(0xFF4CAF50).withOpacity(0.9),
          ],
        )
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7043).withOpacity(0.9),
            Color(0xFFF4511E).withOpacity(0.9),
          ],
        );

        return InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailsPage(
                  appointmentId: upcomingAppointment!.id,
                ),
              ),
            );

            if (result == true) {
              await _loadAppointments();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 280,
            height: 180,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (allTasksCompleted ? Color(0xFF4CAF50) : Color(0xFFF4511E)).withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: Color(0xFF1A8FE3),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upcoming Visit",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                upcomingAppointment!.appointmentType,
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 26,
                              width: 26,
                              decoration: BoxDecoration(
                                color: daysRemaining <= 3 ? Colors.red.withOpacity(0.9) : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  daysRemaining.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "days remaining",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "${upcomingAppointment!.date.month}/${upcomingAppointment!.date.day}/${upcomingAppointment!.date.year} · ${_formatTimeTo12Hour(upcomingAppointment!.date)}",
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedLevelContainer(
      String imagePath,
      String levelNumber,
      String levelName,
      LinearGradient gradient,
      Function onTap, {
        required bool isUnlocked,
        required double progress,
      }) {
    final Color accentColor = const Color(0xFFFF8C00);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22.0),
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                height: 260,
                width: double.infinity,
                child: CustomPaint(
                  size: Size(double.infinity, 260),
                  painter: SlantedBackgroundPainter(gradient: gradient),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 180.0, right: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUnlocked)
                          Padding(
                            padding: const EdgeInsets.only(left: 60.0),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 65,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Colors.black45,
                                  offset: Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 5),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isUnlocked
                                ? [Colors.white, Colors.white70]
                                : [Colors.white, Colors.white70],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Text(
                            'LEVEL $levelNumber',
                            style: TextStyle(
                              fontFamily: 'Impact',
                              fontSize: 32,
                              letterSpacing: 1.5,
                              color: Colors.white,
                              shadows: isUnlocked
                                  ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ]
                                  : [],
                            ),
                          ),
                        ),
                        Text(
                          levelName,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isUnlocked)
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < (progress * 5).floor() ? Icons.star : Icons.star_border,
                                        color: index < (progress * 5).floor() ? Colors.amber : Colors.white70,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 15,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(10.5),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: 15,
                                        width: 100 * progress.clamp(0.0, 1.0),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFFF780), Color(0xFFDDCB22)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentColor.withOpacity(0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -10,
              top: -30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 240,
                  width: 180,
                  color: Colors.transparent,
                  child: isUnlocked
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : ColorFiltered(
                    colorFilter: ColorFilter.matrix(_grayscaleMatrix()),
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _grayscaleMatrix() {
    return [
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  void _showEnhancedLockedLevelDialog(BuildContext context, int level) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Color(0xFF845BCD), Color(0xFF693DB8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'LEVEL LOCKED',
              style: TextStyle(
                fontFamily: 'Impact',
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/Lottie/popup.json',
                  repeat: true,
                  reverse: false,
                  animate: true,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Complete the previous level to unlock Level $level!",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF323232),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 218.0),
                child: SizedBox(
                  width: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E67D5), Color(0xFF6638B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "Got it!",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SlantedBackgroundPainter extends CustomPainter {
  final LinearGradient gradient;

  SlantedBackgroundPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LevelUnlockProvider with ChangeNotifier {
  bool _isLevelTwoUnlocked = false;
  bool _isLevelThreeUnlocked = false;
  bool _isLevelFourUnlocked = false;
  bool _isLevelFiveUnlocked = false;
  bool _isLevelSixUnlocked = false;
  bool _isLevelSevenUnlocked = false;

  bool get isLevelTwoUnlocked => _isLevelTwoUnlocked;
  bool get isLevelThreeUnlocked => _isLevelThreeUnlocked;
  bool get isLevelFourUnlocked => _isLevelFourUnlocked;
  bool get isLevelFiveUnlocked => _isLevelFiveUnlocked;
  bool get isLevelSixUnlocked => _isLevelSixUnlocked;
  bool get isLevelSevenUnlocked => _isLevelSevenUnlocked;

  set isLevelTwoUnlocked(bool value) {
    _isLevelTwoUnlocked = value;
    notifyListeners();
  }

  set isLevelThreeUnlocked(bool value) {
    _isLevelThreeUnlocked = value;
    notifyListeners();
  }

  set isLevelFourUnlocked(bool value) {
    _isLevelFourUnlocked = value;
    notifyListeners();
  }

  set isLevelFiveUnlocked(bool value) {
    _isLevelFiveUnlocked = value;
    notifyListeners();
  }

  set isLevelSixUnlocked(bool value) {
    _isLevelSixUnlocked = value;
    notifyListeners();
  }

  set isLevelSevenUnlocked(bool value) {
    _isLevelSevenUnlocked = value;
    notifyListeners();
  }

  Future<void> unlockLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    switch (level) {
      case 2:
        _isLevelTwoUnlocked = true;
        prefs.setBool('level2Unlocked', true);
        break;
      case 3:
        _isLevelThreeUnlocked = true;
        prefs.setBool('level3Unlocked', true);
        break;
      case 4:
        _isLevelFourUnlocked = true;
        prefs.setBool('level4Unlocked', true);
        break;
      case 5:
        _isLevelFiveUnlocked = true;
        prefs.setBool('level5Unlocked', true);
        break;
      case 6:
        _isLevelSixUnlocked = true;
        prefs.setBool('level6Unlocked', true);
        break;
      case 7:
        _isLevelSevenUnlocked = true;
        prefs.setBool('level7Unlocked', true);
        break;
    }
    notifyListeners();
  }
}