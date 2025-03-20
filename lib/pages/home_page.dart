import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:new01/pages/profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level/level_five_screen.dart';
import 'level/level_four_screen.dart';
import 'level/level_one_screen.dart';
import 'level/level_seven_screen.dart';
import 'level/level_six_screen.dart';
import 'level/level_three_screen.dart';
import 'level/level_two_screen.dart';
 // Corrected typo

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Removes shadow under the AppBar
        leading: IconButton(
          icon: const Icon(Icons.menu_sharp, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          ), // Left icon action
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            ), // Right icon action
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background image that scrolls behind the AppBar
            Positioned.fill(
              child: Container(
                height: 200, // Set height for the container
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffdbd8ec), Color(0xff381a7b)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [],
                  ),
                ),
                SizedBox(height: 200),
                Consumer<LevelUnlockProvider>(
                  builder: (context, levelUnlockProvider, child) {
                    return Column(
                      children: [
                        // Level 1 Container
                        _buildLevelContainer(
                          'assets/images/Level1.png',
                          '1',
                          LinearGradient(
                            colors: [Color(0xff0f1d44), Color(0xff2d4c6f)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LevelOneScreen()),
                          ),
                        ),

                        // Level 2 Container (Locked)
                        _buildLevelContainer(
                          'assets/images/level2.png',
                          '2',
                          levelUnlockProvider.isLevelTwoUnlocked
                              ? LinearGradient(
                            colors: [Color(0xff610c09), Color(0xff864817)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelTwoUnlocked = prefs.getBool('level2Unlocked') ?? false;
                            levelUnlockProvider.isLevelTwoUnlocked = isLevelTwoUnlocked;

                            if (isLevelTwoUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelTwoScreen()),
                              );
                            }
                          },
                        ),

                        // Level 3 Container (Locked)
                        _buildLevelContainer(
                          'assets/images/level3.png',
                          '3',
                          levelUnlockProvider.isLevelThreeUnlocked
                              ? LinearGradient(
                            colors: [Color(0xff9b59b6), Color(0xff8e44ad)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelThreeUnlocked = prefs.getBool('level3Unlocked') ?? false;
                            levelUnlockProvider.isLevelThreeUnlocked = isLevelThreeUnlocked;

                            if (isLevelThreeUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelThreeScreen()),
                              );
                            }
                          },
                        ),

                        // Level 4 Container (Locked)
                        _buildLevelContainer(
                          'assets/images/level4_image.png',
                          '4',
                          levelUnlockProvider.isLevelFourUnlocked
                              ? LinearGradient(
                            colors: [Color(0xfff39c12), Color(0xffe67e22)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelFourUnlocked = prefs.getBool('level4Unlocked') ?? false;
                            levelUnlockProvider.isLevelFourUnlocked = isLevelFourUnlocked;

                            if (isLevelFourUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelFourScreen()),
                              );
                            }
                          },
                        ),

                        // Level 5 Container (Locked)
                        _buildLevelContainer(
                          'assets/images/level5_image.png',
                          '5',
                          levelUnlockProvider.isLevelFiveUnlocked
                              ? LinearGradient(
                            colors: [Color(0xfff1c40f), Color(0xfff39c12)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelFiveUnlocked = prefs.getBool('level5Unlocked') ?? false;
                            levelUnlockProvider.isLevelFiveUnlocked = isLevelFiveUnlocked;

                            if (isLevelFiveUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelFiveScreen()),
                              );
                            }
                          },
                        ),

                        // Repeat for all remaining levels (6 to 15)
                        _buildLevelContainer(
                          'assets/images/level6_image.png',
                          '6',
                          levelUnlockProvider.isLevelSixUnlocked
                              ? LinearGradient(
                            colors: [Color(0xff3498db), Color(0xff2980b9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelSixUnlocked = prefs.getBool('level6Unlocked') ?? false;
                            levelUnlockProvider.isLevelSixUnlocked = isLevelSixUnlocked;

                            if (isLevelSixUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelSixScreen()),
                              );
                            }
                          },
                        ),
                        _buildLevelContainer(
                          'assets/images/level7_image.png',
                          '7',
                          levelUnlockProvider.isLevelSevenUnlocked
                              ? LinearGradient(
                            colors: [Color(0xff16a085), Color(0xff1abc9c)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : LinearGradient(
                            colors: [Colors.grey, Colors.grey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                              () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            bool isLevelSevenUnlocked = prefs.getBool('level7Unlocked') ?? false;
                            levelUnlockProvider.isLevelSevenUnlocked = isLevelSevenUnlocked;

                            if (isLevelSevenUnlocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LevelSevenScreen()),
                              );
                            }
                          },
                        ),
                        // Continue adding the remaining levels...
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building level containers
  Widget _buildLevelContainer(String imagePath, String levelNumber, LinearGradient gradient, Function onTap) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: InkWell(
        onTap: () => onTap(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: SlantedRectangleClipper(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 200.0, right: 20.0),
                  child: Center(
                    child: Text(
                      'LEVEL $levelNumber',
                      style: const TextStyle(
                        color: Color(0xffffffff),
                        fontFamily: 'Impact',
                        fontSize: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -20,
              top: -20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  color: Colors.transparent,
                  child: Image.asset(
                    imagePath,
                    height: 250,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlantedRectangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LevelUnlockProvider with ChangeNotifier {
  bool _isLevelTwoUnlocked = false;
  bool _isLevelThreeUnlocked = false;
  bool _isLevelFourUnlocked = false;
  bool _isLevelFiveUnlocked = false;
  bool _isLevelSixUnlocked = false;
  bool _isLevelSevenUnlocked = false;
  // Add similar fields for other levels (8 to 15)

  bool get isLevelTwoUnlocked => _isLevelTwoUnlocked;
  bool get isLevelThreeUnlocked => _isLevelThreeUnlocked;
  bool get isLevelFourUnlocked => _isLevelFourUnlocked;
  bool get isLevelFiveUnlocked => _isLevelFiveUnlocked;
  bool get isLevelSixUnlocked => _isLevelSixUnlocked;
  bool get isLevelSevenUnlocked => _isLevelSevenUnlocked;
  // Add getters for other levels

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

// Add setters for other levels (8 to 15)
}
