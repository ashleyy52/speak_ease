import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:new01/pages/level/level_two_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

import '../home_page.dart';

class LevelOneScreen extends StatefulWidget {
  @override
  _LevelOneScreenState createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends State<LevelOneScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isRehearsing = false; // State variable for toggle
  String _recognizedText = "";
  String _currentWord = "";
  bool _feedbackShown = false;

  final List<String> words = ["Hello", "Welcome", "Thanks", "Goodbye", "Okay"];
  List<bool> wordUnlocked = [true, false, false, false, false];
  List<bool> wordRecognized = [false, false, false, false, false];
  bool isLevelCompleted = false;

  // Function to speak the word or feedback
  void _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1);
    await _flutterTts.speak(text);
  }

  // Function to start listening for a specific word
  void _startListening(String word) async {
    _currentWord = word;
    _feedbackShown = false;

    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = "";
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords.trim();
          });

          if (!_feedbackShown) {
            if (_recognizedText.toLowerCase() == word.toLowerCase()) {
              _feedbackShown = true;
              _speak("Good job! You said $word.");
              _showFeedbackDialog("Good Job!", "You said the correct word.", word == words.last);
              _markWordAsRecognized(word);
              setState(() {
                _isRehearsing = false;  // Reset rehearse state after correct recognition
              });
            } else if (_recognizedText.isNotEmpty) {
              _feedbackShown = true;
              _speak("Try again. You said $_recognizedText.");
              _showFeedbackDialog("Try Again!", "You said $_recognizedText. Try saying $word.", false);
              setState(() {
                _isRehearsing = false;  // Reset rehearse state after incorrect recognition
              });
            }
          }
        });
      }
    }
  }

  // Function to stop listening
  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _speech.stop();
  }

  // Function to mark a word as recognized
  void _markWordAsRecognized(String word) {
    int index = words.indexOf(word);
    if (index != -1 && !wordRecognized[index]) {
      setState(() {
        wordRecognized[index] = true;
        _unlockNextWord();

        if (!wordRecognized.contains(false)) {
          isLevelCompleted = true;
          print("Level Completed!");
        }
      });
    }
  }

  // Function to unlock the next word
  void _unlockNextWord() {
    setState(() {
      for (int i = 0; i < wordUnlocked.length; i++) {
        if (!wordUnlocked[i]) {
          wordUnlocked[i] = true;
          break;
        }
      }
    });
  }

  // Calculate progress based on correctly recognized words
  Future<double> getProgress() async {
    int recognizedCount = wordRecognized.where((recognized) => recognized).length;

    double progress = recognizedCount / words.length;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (progress == 1.0) {
      prefs.setBool('level2Unlocked', true);
    } else {
      prefs.setBool('level2Unlocked', false);
    }

    return progress;
  }

  // Function to show feedback dialog
  void _showFeedbackDialog(String title, String message, bool isLastWord) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isLastWord) {
                  // If it's the last word, navigate to the home screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LevelTwoScreen()), // Go to Home Screen
                  );
                } else {
                  // Navigate to the next level if it's not the last word
                  // You can replace this with navigation to your next level screen.
                  // For example:
                  // Navigator.pushReplacement(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => NextLevelScreen()),
                  // );
                }
              },
              child: Text(isLastWord ? "Go to Level Two" : "Okay"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SizedBox.shrink(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage()), // Replace current screen with home screen
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff613DC1), Color(0xff2a004e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 45, top: 80.0),
                  child: Text(
                    'Level 1',
                    style: TextStyle(
                      fontFamily: 'Impact',
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(left: 45.0),
                  child: Text(
                    'Greetings',
                    style: TextStyle(
                      fontFamily: 'Impact',
                      fontSize: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: FutureBuilder<double>(
                  future: getProgress(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Show a loading spinner
                    }

                    if (snapshot.hasData) {
                      double progress = snapshot.data ?? 0.0;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff613DC1), Color(0xff2a004e)], // Soft gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // Linear progress indicator
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.3), // Slightly transparent background
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xfffbf36d)),
                                minHeight: 45, // Reduced height for a more subtle look
                              ),
                              // Centered text displaying the completed level
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${(progress * 100).toStringAsFixed(0)}% Completed", // Display percentage
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff010203),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Text('Error loading progress');
                    }
                  },
                ),
              ),
              SizedBox(height: 50),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: words.asMap().entries.map((entry) {
                    int index = entry.key;
                    String word = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Container(
                        height: 650,
                        width: 350,
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 25),
                                  child: Container(
                                    color: wordUnlocked[index] ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(50.0),
                                    child: wordUnlocked[index]
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(
                                        'assets/images/$word.jpg',
                                        height: 280,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Container(
                                      height: 250,
                                      width: 250,
                                      color: Colors.black.withOpacity(0.5),
                                      child: Center(
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    word,
                                    style: TextStyle(
                                      fontFamily: 'Impact',
                                      fontSize: 32,
                                      color: wordUnlocked[index] ? Colors.white : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                  if (wordUnlocked[index]) ...[
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _speak(word);
                                      },
                                      icon: Icon(Icons.volume_up, color: Colors.white),
                                      label: Text("Hear"),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(250, 50),
                                        backgroundColor: Color(0xffdd5916),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (_isRehearsing) {
                                            _stopListening();
                                          } else {
                                            _startListening(word);
                                          }
                                          _isRehearsing = !_isRehearsing;
                                        });
                                      },
                                      icon: Icon(Icons.mic, color: Colors.white),
                                      label: Text(_isRehearsing ? "Stop" : "Rehearse"),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(250, 50),
                                        backgroundColor: Color(0xffdd9716),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
