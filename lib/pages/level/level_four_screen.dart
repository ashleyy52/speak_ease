import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class LevelFourScreen extends StatefulWidget {
  const LevelFourScreen({super.key});

  @override
  _LevelFourScreenState createState() => _LevelFourScreenState();
}

class _LevelFourScreenState extends State<LevelFourScreen> with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _confettiController;

  // Words for Level 4
  List<String> words = ['cake', 'juice', 'apple', 'candy', 'pizza'];
  List<String> wordImages = [
    'assets/images/cake.jpg',
    'assets/images/juice.jpg',
    'assets/images/apple.jpg',
    'assets/images/candy.jpg',
    'assets/images/pizza.jpg',
  ];
  List<bool> wordRecognized = [false, false, false, false, false];
  List<bool> wordUnlocked = [true, false, false, false, false];
  List<bool> isListeningList = [false, false, false, false, false];
  bool isLevelCompleted = false;

  // Timers for inactivity prompts
  List<Timer?> inactivityTimers = [null, null, null, null, null];
  final int inactivityTimeoutSeconds = 10;

  // Page controller for the card carousel
  late PageController _pageController;
  int _currentPage = 0;

  // Colors for kid-friendly food theme
  final Color _primaryColor = const Color(0xFF9C27B0); // Purple primary color
  final Color _accentColor = const Color(0xFFFF5722);  // Deep orange accent color
  final Color _backgroundColor1 = const Color(0xFFE1BEE7); // Light purple gradient start
  final Color _backgroundColor2 = const Color(0xFFCE93D8); // Medium purple gradient middle
  final Color _backgroundColor3 = const Color(0xFFBA68C8); // Deep purple gradient end

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

    // Listen to page changes
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
        // Cancel any active timers when changing pages
        _cancelInactivityTimer(_currentPage);
        // Start inactivity timer for the new page if word is unlocked
        if (wordUnlocked[next] && !wordRecognized[next]) {
          _startInactivityTimer(next);
        }
      }
    });

    // Start inactivity timer for initial page if unlocked
    if (wordUnlocked[0] && !wordRecognized[0]) {
      _startInactivityTimer(0);
    }
  }

  void _loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedRecognized = prefs.getStringList('level4_wordRecognized');
    List<String>? savedUnlocked = prefs.getStringList('level4_wordUnlocked');

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
        prefs.setBool('level5Unlocked', true);
      });
    }
  }

  void _startInactivityTimer(int index) {
    // Cancel any existing timer first
    _cancelInactivityTimer(index);

    // Start a new timer
    inactivityTimers[index] = Timer(Duration(seconds: inactivityTimeoutSeconds), () {
      if (mounted && wordUnlocked[index] && !wordRecognized[index]) {
        _promptUserForActivity(index);
      }
    });
  }

  void _cancelInactivityTimer(int index) {
    inactivityTimers[index]?.cancel();
    inactivityTimers[index] = null;
  }

  void _promptUserForActivity(int index) {
    if (mounted) {
      // Speak the prompt
      _flutterTts.speak("Let's try saying ${words[index]}. Tap the mic button and say it.");

      // Show a visual prompt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Let's practice saying '${words[index]}'!"),
          backgroundColor: _accentColor,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Practice',
            textColor: Colors.white,
            onPressed: () {
              _startListening(index);
            },
          ),
        ),
      );

      // Restart the timer for next prompt
      _startInactivityTimer(index);
    }
  }

  void _markWordAsRecognized(String word) async {
    int index = words.indexOf(word);
    if (index != -1 && !wordRecognized[index]) {
      setState(() {
        wordRecognized[index] = true;
        _unlockNextWord();
      });

      // Cancel inactivity timer for this word
      _cancelInactivityTimer(index);

      // Play success animation
      _confettiController.forward(from: 0.0);

      // Save progress
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('level4_wordRecognized', wordRecognized.map((e) => e.toString()).toList());
      prefs.setStringList('level4_wordUnlocked', wordUnlocked.map((e) => e.toString()).toList());

      // Check for level completion
      if (!wordRecognized.contains(false)) {
        setState(() {
          isLevelCompleted = true;
          prefs.setBool('level5Unlocked', true);
        });

        // Show level completion dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _showLevelCompletedDialog();
        });
      } else {
        // Start timer for the next unlocked word that's not recognized
        for (int i = 0; i < words.length; i++) {
          if (wordUnlocked[i] && !wordRecognized[i]) {
            _startInactivityTimer(i);
            break;
          }
        }
      }
    }
  }

  void _unlockNextWord() {
    for (int i = 0; i < wordUnlocked.length - 1; i++) {
      if (wordRecognized[i] && !wordUnlocked[i + 1]) {
        setState(() {
          wordUnlocked[i + 1] = true;
        });

        // Start inactivity timer for newly unlocked word if it's the current page
        if (i + 1 == _currentPage) {
          _startInactivityTimer(i + 1);
        }

        break;
      }
    }
  }

  void _startListening(int index) async {
    // Cancel any running inactivity timer
    _cancelInactivityTimer(index);

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
              _markWordAsRecognized(words[index]);
              _stopListening(index);

              // Provide positive feedback
              _flutterTts.speak("Great job saying ${words[index]}!");
            } else if (recognizedWord.isNotEmpty) {
              // Incorrect word was said
              _stopListening(index);

              // Provide guidance
              _flutterTts.speak("Let's try again. Say ${words[index]}.");

              // Show visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Try again! Please say '${words[index]}'"),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Restart inactivity timer
              _startInactivityTimer(index);
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

    // Restart inactivity timer if word not recognized
    if (!wordRecognized[index]) {
      _startInactivityTimer(index);
    }
  }

  void _speakWord(String word) async {
    // Cancel inactivity timer temporarily while speaking
    int index = words.indexOf(word);
    if (index != -1) {
      _cancelInactivityTimer(index);
    }

    await _flutterTts.speak(word);

    // Restart inactivity timer if word is not recognized
    if (index != -1 && !wordRecognized[index]) {
      _startInactivityTimer(index);
    }
  }

  void _showLevelCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Yummy Success!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You've completed Level 4!",
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
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

    // Cancel all inactivity timers
    for (int i = 0; i < inactivityTimers.length; i++) {
      inactivityTimers[i]?.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = wordRecognized.where((e) => e).length / words.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Level 4: Food Words',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              const SizedBox(height: 20),

              // Progress section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Progress label with stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Progress: ${(progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (progress * 5).floor() ? Icons.star : Icons.star_border,
                              color: index < (progress * 5).floor() ? Colors.amber : Colors.white70,
                              size: 24,
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Improved progress bar
                    Stack(
                      children: [
                        // Background
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.5),
                          ),
                        ),
                        // Progress fill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 45,
                          width: MediaQuery.of(context).size.width * 0.9 * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFCE93D8), Color(0xFF7B1FA2)], // Light purple to deep purple
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12.5),
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.5),
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

              const SizedBox(height: 30),

              // Word Cards as PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return _buildWordCard(index);
                  },
                ),
              ),

              // Navigation dots
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
                colors: [Color(0xffffffff), Colors.grey.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
                  : LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Word badge at the top
                if (isCurrentWordRecognized)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Yummy!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Word image in a decorative frame
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.asset(
                          wordImages[index],
                          height: 220,
                          width: 220,
                          fit: BoxFit.cover,
                          color: isCurrentWordUnlocked ? null : Colors.grey.withOpacity(0.7),
                          colorBlendMode: isCurrentWordUnlocked ? null : BlendMode.saturation,
                        ),
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

                // Word display
                Text(
                  words[index].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isCurrentWordUnlocked ? _primaryColor : Colors.white60,
                  ),
                ),

                const SizedBox(height: 30),

                // Action buttons
                if (isCurrentWordUnlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hear button
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

                      // Speak button
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
                                  size: 32
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

                // Lock icon and text for locked words
                if (!isCurrentWordUnlocked)
                  Column(
                    children: [
                      const Icon(
                          Icons.lock,
                          color: Colors.white70,
                          size: 50
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