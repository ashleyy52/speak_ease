import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import '../home_page.dart';
import 'level_four_screen.dart'; // Ensure this import is correct

class LevelThreeScreen extends StatefulWidget {
  const LevelThreeScreen({super.key});

  @override
  _LevelThreeScreenState createState() => _LevelThreeScreenState();
}

class _LevelThreeScreenState extends State<LevelThreeScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _confettiController;

  // Animation controllers and visibility flags for EACH word
  List<AnimationController> _successAnimControllers = [];
  List<AnimationController> _errorAnimControllers = [];
  List<bool> _showSuccessAnimations = [];
  List<bool> _showErrorAnimations = [];
  List<bool> _showFeedbacks = [];
  List<String> _currentFeedbacks = [];

  // Words for Level 3
  List<String> words = ['cookie',  'ice cream','home', 'star', 'cloud'];

  // Updated wordImages to include both static images and Lottie animations
  List<String> wordImages = [
    'assets/Lottie/cookie.json',      // Lottie animation for "cat"
    'assets/Lottie/ice.json',
    'assets/Lottie/home.json',      // Lottie animation for "dog"
          // Lottie animation for "car"
    'assets/Lottie/star.json',      // Lottie animation for "bug"
    'assets/Lottie/cloud1.json',       // Static image for "sky"
  ];

  // Custom gradient colors for each word card (unlocked state)
  List<List<Color>> cardGradientColors = [
    [Color(0xfffdfbe6), Color(0xfffdfbe8)],
    [Color(0xfffdf0ee), Color(0xfffcded2)],// Gradient for "fun"
    [Color(0xfff4f4f4), Color(0xfff4f4f4)],  // Gradient for "moon"
    [Color(0xffffffff), Color(0xffffffff)],  // Gradient for "cloud"
    [Color(0xffb2d5dd), Color(0xff97dce8)],  // Gradient for "sky"
  ];

  // Custom gradient colors for locked state (darker shade, matching the solid-color style)
  List<List<Color>> lockedCardGradientColors = [
    [Color(0xff757575), Color(0xff757575)],  // Locked gradient for "fun"
    [Color(0xff757575), Color(0xff757575)],  // Locked gradient for "moon"
    [Color(0xff757575), Color(0xff757575)],  // Locked gradient for "star"
    [Color(0xff757575), Color(0xff757575)],  // Locked gradient for "cloud"
    [Color(0xff757575), Color(0xff757575)],  // Locked gradient for "sky"
  ];

  // Feedback phrases to display
  List<String> successPhrases = [
    'Great job!',
    'Fantastic!',
    'You did it!',
    'Amazing!',
    'Excellent!'
  ];

  List<String> tryAgainPhrases = [
    'Try again!',
    'Almost there!',
    'Let\'s try once more!',
    'You can do it!',
    'Keep trying!'
  ];

  List<bool> wordRecognized = [false, false, false, false, false];
  List<bool> wordUnlocked = [true, false, false, false, false];
  List<bool> isListeningList = [false, false, false, false, false];
  bool isLevelCompleted = false;

  // Page controller for the card carousel
  late PageController _pageController;
  int _currentPage = 0;

  // Colors for kid-friendly theme
  final Color _primaryColor = const Color(0xFF1976D2); // Blue primary color
  final Color _accentColor = const Color(0xFFFF9800);  // Orange accent color
  final Color _backgroundColor1 = const Color(0xFF8C66FF); // Dark purple gradient start
  final Color _backgroundColor2 = const Color(0xFF7341E6); // Dark purple gradient middle
  final Color _backgroundColor3 = const Color(0xFF5E35B1); // Dark purple gradient end

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _loadProgress();

    // Setup animation controller for success animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Initialize animation controllers and state arrays for each word
    for (int i = 0; i < words.length; i++) {
      _successAnimControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 2000),
          vsync: this,
        ),
      );

      _errorAnimControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 2000),
          vsync: this,
        ),
      );

      _showSuccessAnimations.add(false);
      _showErrorAnimations.add(false);
      _showFeedbacks.add(false);
      _currentFeedbacks.add('');

      // Add listeners to reset UI after animations complete for each controller
      _successAnimControllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showSuccessAnimations[i] = false;
            _showFeedbacks[i] = false;
          });
          _successAnimControllers[i].reset();
        }
      });

      _errorAnimControllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _showErrorAnimations[i] = false;
            _showFeedbacks[i] = false;
          });
          _errorAnimControllers[i].reset();
        }
      });
    }

    // Listen to page changes
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  void _loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedRecognized = prefs.getStringList('level3_wordRecognized');
    List<String>? savedUnlocked = prefs.getStringList('level3_wordUnlocked');

    if (savedRecognized != null && savedUnlocked != null) {
      setState(() {
        wordRecognized = savedRecognized.map((e) => e == 'true').toList();
        wordUnlocked = savedUnlocked.map((e) => e == 'true').toList();
      });
    }

    // Check if level is completed
    if (!wordRecognized.contains(false)) {
      setState(() {
        isLevelCompleted = true;
        prefs.setBool('level4Unlocked', true);
      });
    }
  }

  void _checkWordPronunciation(String word, bool isPractice) async {
    int index = words.indexOf(word);
    if (index != -1) {
      // If this is not practice mode (i.e., word not yet recognized), mark as recognized
      if (!isPractice && !wordRecognized[index]) {
        setState(() {
          wordRecognized[index] = true;
          _unlockNextWord();
        });

        // Save progress
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setStringList('level3_wordRecognized', wordRecognized.map((e) => e.toString()).toList());
        prefs.setStringList('level3_wordUnlocked', wordUnlocked.map((e) => e.toString()).toList());

        // Check for level completion
        if (!wordRecognized.contains(false)) {
          setState(() {
            isLevelCompleted = true;
            prefs.setBool('level4Unlocked', true);
          });

          // Show level completion dialog after a short delay
          Future.delayed(const Duration(milliseconds: 2500), () {
            _showLevelCompletedDialog();
          });
        }
      }

      // Show success animation and feedback regardless of practice mode
      _showSuccessAnimationAndFeedback(index);

      // Play success animation
      _confettiController.forward(from: 0.0);
    }
  }

  void _showSuccessAnimationAndFeedback(int index) {
    // Select a random success phrase
    final random = DateTime.now().millisecondsSinceEpoch % successPhrases.length;

    setState(() {
      _showSuccessAnimations[index] = true;
      _showFeedbacks[index] = true;
      _currentFeedbacks[index] = successPhrases[random];
    });

    // Play success animation only for this index
    if (_successAnimControllers[index].isAnimating) {
      _successAnimControllers[index].stop();
    }
    _successAnimControllers[index].forward();

    // Speak the feedback
    _flutterTts.speak("${successPhrases[random]} You said ${words[index]} correctly!");
  }

  void _showErrorAnimationAndFeedback(int index) {
    // Select a random try again phrase
    final random = DateTime.now().millisecondsSinceEpoch % tryAgainPhrases.length;

    setState(() {
      _showErrorAnimations[index] = true;
      _showFeedbacks[index] = true;
      _currentFeedbacks[index] = tryAgainPhrases[random];
    });

    // Play error animation only for this index
    if (_errorAnimControllers[index].isAnimating) {
      _errorAnimControllers[index].stop();
    }
    _errorAnimControllers[index].forward();

    // Speak the feedback
    _flutterTts.speak("${tryAgainPhrases[random]} Let's try saying ${words[index]} again.");
  }

  void _unlockNextWord() {
    for (int i = 0; i < wordUnlocked.length - 1; i++) {
      if (wordRecognized[i] && !wordUnlocked[i + 1]) {
        setState(() {
          wordUnlocked[i + 1] = true;
        });
        break;
      }
    }
  }

  void _startListening(int index) async {
    // Determine if this is practice mode (word already recognized)
    bool isPractice = wordRecognized[index];

    // Cancel any animations for this specific index if they're showing
    if (_showSuccessAnimations[index] || _showErrorAnimations[index]) {
      setState(() {
        _showSuccessAnimations[index] = false;
        _showErrorAnimations[index] = false;
        _showFeedbacks[index] = false;
      });
      _successAnimControllers[index].reset();
      _errorAnimControllers[index].reset();
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
    if (available) {
      setState(() {
        isListeningList[index] = true;
      });

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String recognizedWord = result.recognizedWords.toLowerCase();
            if (recognizedWord.contains(words[index])) {
              _checkWordPronunciation(words[index], isPractice);
              _stopListening(index);
            } else if (recognizedWord.isNotEmpty) {
              // Incorrect word was said
              _stopListening(index);
              _showErrorAnimationAndFeedback(index);
            }
          }
        },
      );
    }
  }

  void _stopListening(int index) {
    setState(() {
      isListeningList[index] = false;
    });
    _speech.stop();
  }

  void _speakWord(String word) async {
    await _flutterTts.speak(word);
  }

  void _showLevelCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              'LEVEL COMPLETED!',
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
                  'assets/Lottie/penguin.json',
                  repeat: true,
                  reverse: false,
                  animate: true,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Level 4 has been unlocked",
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
                      onPressed: () => Navigator.pop(context),
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

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _pageController.dispose();
    _confettiController.dispose();

    // Stop and dispose of all success animation controllers
    for (var controller in _successAnimControllers) {
      controller.stop();
      controller.dispose();
    }

    // Stop and dispose of all error animation controllers
    for (var controller in _errorAnimControllers) {
      controller.stop();
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = wordRecognized.where((e) => e).length / words.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 26),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 26),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("How to Play"),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("1. Tap the 🔊 button to hear the word"),
                        SizedBox(height: 8),
                        Text("2. Tap the 🎤 button and try to say the word"),
                        SizedBox(height: 8),
                        Text("3. When you say it correctly, you'll unlock the next word!"),
                        SizedBox(height: 8),
                        Text("4. You can practice completed words any time!"),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Got it!"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_backgroundColor1, _backgroundColor2, _backgroundColor3],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress section
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              ' L E V E L',
                              style: TextStyle(
                                fontFamily: "Impact",
                                fontSize: 20,
                                color: const Color(0xFFFFF780),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '  3',
                              style: TextStyle(
                                fontFamily: "Impact",
                                fontSize: 20,
                                color: const Color(0xFFFDF57F),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Advanced Words'.toUpperCase(),
                          style: TextStyle(
                            fontFamily: "Impact",
                            fontSize: 40,
                            color: const Color(0xFFFDF57F),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            bool isFilled = index < (progress * 5).floor();
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  isFilled ? Icons.star : Icons.star_border,
                                  color: Colors.black,
                                  size: 28,
                                ),
                                Icon(
                                  isFilled ? Icons.star : Icons.star_border,
                                  color: isFilled ? Colors.amber : Colors.white70,
                                  size: 24,
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            height: 36,
                            width: MediaQuery.of(context).size.width * 0.9 * progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFEB3B),
                                  Color(0xFFFFF780),
                                  Color(0xFFFFAB40),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF7A34AA).withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: -1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (progress > 0.05)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 6,
                                width: MediaQuery.of(context).size.width * 0.9 * progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              final markerProgress = (index + 1) / 5;
                              final markerReached = progress >= markerProgress;
                              return Container(
                                width: 2,
                                height: 8,
                                margin: EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: markerReached
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              );
                            }),
                          ),
                          Center(
                            child: Text(
                              "${(progress * 100).toInt()}%",
                              style: const TextStyle(
                                fontFamily: "Impact",
                                fontSize: 20,
                                color: Color(0x80fdf7f7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return _buildWordCard(index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(words.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10,
                      width: _currentPage == index ? 24 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? _accentColor : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(int index) {
    final bool isCurrentWordUnlocked = wordUnlocked[index];
    final bool isCurrentWordRecognized = wordRecognized[index];

    // Determine if the asset is an image or a Lottie animation based on the file extension
    bool isLottie = wordImages[index].endsWith('.json');

    return AnimatedScale(
      scale: _currentPage == index ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isCurrentWordRecognized ? Colors.green : Colors.transparent,
              width: isCurrentWordRecognized ? 3 : 0,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: isCurrentWordUnlocked
                  ? LinearGradient(
                colors: cardGradientColors[index],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
                  : LinearGradient(
                colors: lockedCardGradientColors[index],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isCurrentWordRecognized)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Completed!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Render either an image or a Lottie animation
                        isLottie
                            ? SizedBox(
                          height: 220,
                          width: 220,
                          child: Lottie.asset(
                            wordImages[index],
                           // fit: BoxFit.cover,
                            repeat: true,
                            animate: isCurrentWordUnlocked, // Animate only if unlocked
                          ),
                        )
                            : Image.asset(
                          wordImages[index],
                          height: 220,
                          width: 220,
                          fit: BoxFit.cover,
                          color: isCurrentWordUnlocked ? null : Colors.grey.withOpacity(0.7),
                          colorBlendMode: isCurrentWordUnlocked ? null : BlendMode.saturation,
                        ),
                        // Apply blur effect for locked words
                        if (!isCurrentWordUnlocked)
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  words[index].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isCurrentWordUnlocked ? _primaryColor : Colors.white60,
                  ),
                ),
                if (isCurrentWordRecognized && isCurrentWordUnlocked && !(_showSuccessAnimations[index] || _showErrorAnimations[index]))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Tap buttons below to practice!",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: _primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                if (_showFeedbacks[index])
                  AnimatedOpacity(
                    opacity: _showFeedbacks[index] ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _currentFeedbacks[index],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _showSuccessAnimations[index]
                              ? Colors.green
                              : _showErrorAnimations[index]
                              ? Colors.red
                              : _primaryColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                if (isCurrentWordUnlocked)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: (_showSuccessAnimations[index] || _showErrorAnimations[index]) ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => _speakWord(words[index]),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.volume_up, color: Colors.white, size: 32),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "HEAR",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: isListeningList[index]
                                  ? () => _stopListening(index)
                                  : () => _startListening(index),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isListeningList[index] ? Colors.red : _accentColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isListeningList[index] ? Colors.red : _accentColor).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      isListeningList[index] ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isListeningList[index] ? "STOP" : "SPEAK",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showSuccessAnimations[index])
                        AnimatedOpacity(
                          opacity: _showSuccessAnimations[index] ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 700),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: Lottie.asset(
                              'assets/Lottie/correct_animation.json',
                              controller: _successAnimControllers[index],
                              repeat: false,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      if (_showErrorAnimations[index])
                        AnimatedOpacity(
                          opacity: _showErrorAnimations[index] ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 3500),
                          child: SizedBox(
                            width: 180,
                            height: 130,
                            child: Lottie.asset(
                              'assets/Lottie/error_og.json',
                              controller: _errorAnimControllers[index],
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (!isCurrentWordUnlocked)
                  Column(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Colors.white70,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Complete previous word to unlock",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}