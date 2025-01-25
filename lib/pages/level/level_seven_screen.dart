import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

class LevelSevenScreen extends StatefulWidget {
  @override
  _LevelSevenScreenState createState() => _LevelSevenScreenState();
}

class _LevelSevenScreenState extends State<LevelSevenScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = "";
  String _currentWord = ""; // Tracks the word being rehearsed
  bool _feedbackShown = false; // Tracks if feedback is already shown

  final List<String> words = ["Hello", "Welcome", "Thanks", "Goodbye", "Okay"];

  // Function to speak the word or feedback
  void _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1);
    await _flutterTts.speak(text);
  }

  // Function to start listening for a specific word
  void _startListening(String word) async {
    _currentWord = word; // Set the current word being rehearsed
    _feedbackShown = false; // Reset feedback flag

    // Request microphone permission
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print("Microphone permission granted");

      bool available = await _speech.initialize();
      if (available) {
        print("Speech recognition initialized successfully");
        setState(() {
          _isListening = true;
          _recognizedText = "";
        });
        _speech.listen(onResult: (result) {
          print("Speech result: ${result.recognizedWords}");
          setState(() {
            _recognizedText = result.recognizedWords.trim();
          });

          // Check if the recognized word matches the current word
          if (!_feedbackShown) {
            if (_recognizedText.toLowerCase() == word.toLowerCase()) {
              _feedbackShown = true;
              _speak("Good job! You said $word.");
              _showFeedbackDialog("Good Job!", "You said the correct word.");
            } else if (_recognizedText.isNotEmpty) {
              _feedbackShown = true;
              _speak("Try again. You said $_recognizedText.");
              _showFeedbackDialog("Try Again!", "You said $_recognizedText. Try saying $word.");
            }
          }
        });
      } else {
        print("Speech recognition failed to initialize");
      }
    } else {
      print("Microphone permission denied");
    }
  }

  // Function to stop listening
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Function to show feedback dialog
  void _showFeedbackDialog(String title, String message) {
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
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove AppBar shadow
        title: SizedBox.shrink(), // Empty title for a clean transparent app bar
      ),
      body: Container(
        // Set the background color for the entire body container
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff613DC1), Color(0xff2a004e)], // Violet gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Heading for the page
            Container(
              width: double.infinity,
              //padding: const EdgeInsets.symmetric(vertical: 20),
              child: Padding(
                padding: const EdgeInsets.only(left: 45,top: 80.0),
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: words.map((word) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Container(
                        height: 600,
                        width: 350, // Increased width to accommodate image and buttons
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1), // Light transparent background for frosted effect
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
                              // Apply the blur effect to the background
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 25),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4), // Transparent background
                                    ),
                                  ),
                                ),
                              ),
                              // Content inside the frosted glass box
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(50.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4), // Set rounded corners here
                                      child: Image.asset(
                                        'assets/images/$word.jpg',
                                        height: 250,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 10),
                                  Text(
                                    word,
                                    style: TextStyle(
                                      fontFamily: 'Impact',
                                      fontSize: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 30),
                                  // Replace Row with Column to stack buttons vertically
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Hear button with solid orange color
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          print("Hear button clicked for $word");
                                          _speak(word);
                                        },
                                        icon: Icon(Icons.volume_up,color: Colors.white,),
                                        label: Text("Hear"),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(250, 50),
                                          backgroundColor: Color(0xffdd5916), // Make the button wider
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10), // Rounded corners
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                          foregroundColor: Colors.white, // White text color
                                        ),
                                      ),
                                      SizedBox(height: 20), // Space between buttons
                                      // Rehearse button with solid orange color
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          print("Rehearse button clicked for $word");
                                          _isListening && _currentWord == word
                                              ? _stopListening()
                                              : _startListening(word);
                                        },
                                        icon: Icon(Icons.mic,color: Colors.white,),
                                        label: Text(_isListening && _currentWord == word
                                            ? "Stop"
                                            : "Rehearse"),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(250, 50),
                                          backgroundColor: Color(0xfffd9220), // Make the button wider
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10), // Rounded corners
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                          foregroundColor: Colors.white, // White text color
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
