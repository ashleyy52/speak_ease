import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level/level_eight_screen.dart';
import 'level/level_eleven_screen.dart';
import 'level/level_fifteen_screen.dart';
import 'level/level_five_screen.dart';
import 'level/level_four_screen.dart';
import 'level/level_nine_screen.dart';
import 'level/level_one_screen.dart';
import 'level/level_seven_screen.dart';
import 'level/level_six_screen.dart';
import 'level/level_ten_screen.dart';
import 'level/level_thirteen_screen.dart';
import 'level/level_three_screen.dart';
import 'level/level_twelve_screen.dart';
import 'level/level_two_screen.dart';
import 'level/leven_fourteen_screen.dart'; // Import the Level 1 screen

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool get isLevelTwoUnlocked => false;

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
            MaterialPageRoute(builder: (context) => LevelTwoScreen()),
          ), // Left icon action
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LevelOneScreen()),
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
                  gradient: LinearGradient(  // Gradient directly passed in the GestureDetector
                    colors: [Color(0xff130631), Color(0xff381a7b)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ), // Background color if needed
                ),
                child: Column(

                ),
              ),


            ),
            Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(top: 80.0,right: 0), // Add padding to avoid overlap with the AppBar
                  child:Stack(
                    alignment: Alignment.center,
                    children: [

                    ],
                  ),

                ),

                SizedBox(height: 200,),

                // Green Container wrapping all levels
                Column(
                  children: [
                    // Level 1 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelOneScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/images/level1.png',
                        '1',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Color(0xff0f1d44), Color(0xff2d4c6f)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 2 Container

                    GestureDetector(
                      onTap: () async {
                        // Fetch SharedPreferences and update the provider
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        bool isLevelTwoUnlocked = prefs.getBool('level2Unlocked') ?? false;

                        // Update the provider value
                        Provider.of<LevelUnlockProvider>(context, listen: false).isLevelTwoUnlocked = isLevelTwoUnlocked;

                        // Navigate to the next screen if level is unlocked
                        if (isLevelTwoUnlocked) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LevelTwoScreen()),
                          );
                        }
                      },
                      child: _interactiveLevelContainer(
                        'assets/images/level2.png',
                        '2',
                        // Use the provider value to determine the gradient
                        Provider.of<LevelUnlockProvider>(context).isLevelTwoUnlocked
                            ? LinearGradient(  // Gradient for unlocked level
                          colors: [Color(0xff610c09), Color(0xff864817)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : LinearGradient(  // Gray gradient for locked level
                          colors: [Colors.grey, Colors.grey],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    )


                    ,

                    // Level 3 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelThreeScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level3_image.png',
                        '3',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.purple, Colors.pink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 4 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelFourScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level4_image.png',
                        '4',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.red, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 5 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelFiveScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level5_image.png',
                        '5',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.yellow, Colors.amber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 6 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelSixScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level6_image.png',
                        '6',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.blueGrey, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 7 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelSevenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level7_image.png',
                        '7',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.cyan, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 8 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelEightScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level8_image.png',
                        '8',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.indigo, Colors.deepPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 9 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelNineScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level9_image.png',
                        '9',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.pinkAccent, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 10 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelTenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level10_image.png',
                        '10',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.teal, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 11 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelElevenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level11_image.png',
                        '11',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.orangeAccent, Colors.red],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 12 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelTwelveScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level12_image.png',
                        '12',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.purpleAccent, Colors.deepPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 13 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelThirteenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level13_image.png',
                        '13',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.greenAccent, Colors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 14 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelFourteenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level14_image.png',
                        '14',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.redAccent, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Level 15 Container
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelFifteenScreen()),
                        );
                      },
                      child: _interactiveLevelContainer(
                        'assets/level15_image.png',
                        '15',
                        LinearGradient(  // Gradient directly passed in the GestureDetector
                          colors: [Colors.cyanAccent, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Custom widget to create interactive level containers with an image on the left
  Widget _interactiveLevelContainer(String imagePath, String levelNumber, LinearGradient gradient) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Stack(
        clipBehavior: Clip.none, // Allow overflow for projection
        children: [
          // Main container
          ClipPath(
            clipper: SlantedRectangleClipper(),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,  // Use the gradient passed in
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
                      fontFamily: 'Impact', // Use Impact font
                      fontSize: 34, // Adjust font size
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Projected image
          Positioned(
            left: -20, // Adjust to overlap the container
            top: -20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30), // Rounded for a smoother projection
              child: Container(
                color: Colors.transparent, // Optional: Add a color for debugging
                child: Image.asset(
                  imagePath,
                  height: 250,
                  width: 180,
                  fit: BoxFit.cover, // Adjust image size
                ),
              ),
            ),
          ),
        ],
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

  bool get isLevelTwoUnlocked => _isLevelTwoUnlocked;

  set isLevelTwoUnlocked(bool value) {
    _isLevelTwoUnlocked = value;
    notifyListeners(); // Notify listeners when the value changes
  }
}
