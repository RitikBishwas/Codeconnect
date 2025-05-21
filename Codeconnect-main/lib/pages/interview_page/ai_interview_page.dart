import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nitd_code/utils/resume_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/view_reports_page.dart';

class AIInterviewPage extends StatefulWidget {
  final File? selectedFile;
  final Uint8List? webFileBytes;
  final bool isAI;

  const AIInterviewPage({
    super.key,
    this.selectedFile,
    this.webFileBytes,
    required this.isAI,
  });

  @override
  _AIInterviewPageState createState() => _AIInterviewPageState();
}

class _AIInterviewPageState extends State<AIInterviewPage> {
  List<String> _questions = [];
  final List<String> _answers = []; // ✅ Store user's answers
  double _interviewRating = 0.0; // ✅ Store interview rating
  String _feedback = ''; // ✅ Store feedback text

  bool _isParsing = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  int _currentQuestionIndex = 0;
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speechToText = stt.SpeechToText();
  int _countdown = 5;
  bool _showCountdown = true;
  bool _isPageActive = true;
  String _userAnswer = ''; // ✅ Store user's spoken answer
  double _opacity = 1.0;
  Color _bgColor = Colors.blue;
  final List<Color> _bgColors = [
    Colors.blue,
    Colors.purple,
    Colors.deepOrange,
    Colors.green,
    Colors.teal
  ];
  String _motivationalMessage = "Get ready to ace your interview!";
  final List<String> _motivationalMessages = [
    "Get ready to ace your interview!",
    "Speak with confidence!",
    "You’ve got this!",
    "Stay calm, stay sharp!",
    "Believe in yourself!"
  ];

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeSpeechToText();

    if (kIsWeb) {
      if (widget.webFileBytes != null) {
        _parseWebResume(widget.webFileBytes!);
      } else {
        _showError('No resume file uploaded for web.');
      }
    } else {
      if (widget.selectedFile != null) {
        _parseResume(widget.selectedFile!);
      } else {
        _showError('No resume file uploaded.');
      }
    }
  }

  // ✅ Initialize TTS
  void _initializeTTS() {
    flutterTts.setLanguage('en-US');
    flutterTts.setPitch(1.4);
    flutterTts.setSpeechRate(1.6);
    flutterTts.setCompletionHandler(() {
      if (_isPageActive) {
        _startListening(); // Start listening after speaking completes
      }
    });
  }

  // ✅ Initialize Speech-to-Text
  void _initializeSpeechToText() async {
    await speechToText.initialize();
  }

  // ✅ Parse Resume for Mobile/Desktop
  Future<void> _parseResume(File resumeFile) async {
    setState(() {
      _isParsing = true;
    });

    try {
      List<String> questions = await ResumeParser().parseResume(resumeFile);
      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _isParsing = false;
        });
        _startCountdown();
      } else {
        _showError('No questions generated from resume.');
      }
    } catch (e) {
      _showError('Error parsing resume: $e');
    }
  }

  // ✅ Parse Resume for Web
  Future<void> _parseWebResume(Uint8List webBytes) async {
    setState(() {
      _isParsing = true;
    });

    try {
      List<String> questions = await ResumeParser().parseWebResume(webBytes);
      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _isParsing = false;
        });
        _startCountdown();
      } else {
        _showError('No questions generated from resume.');
      }
    } catch (e) {
      _showError('Error parsing web resume: $e');
    }
  }

  // ✅ Start Countdown with Motivational UI
  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        setState(() {
          _showCountdown = false;
        });
        _startQuestion();
      } else {
        setState(() {
          _countdown--;
          _opacity = _opacity == 1.0 ? 0.0 : 1.0; // Blinking effect
          _bgColor = _bgColors[5 - _countdown]; // Changing background color
          _motivationalMessage = _motivationalMessages[5 - _countdown];
        });
      }
    });
  }

  // ✅ Start First Question
  void _startQuestion() {
    if (_questions.isNotEmpty && _isPageActive) {
      _speakQuestion(_questions[_currentQuestionIndex]);
    }
  }

  // ✅ Speak Full Question Only (No Text Display)
  Future<void> _speakQuestion(String question) async {
    setState(() {
      _isSpeaking = true;
    });

    await flutterTts.speak(question); // Speak the entire question
  }

  // ✅ Start Listening for Answer
  void _startListening() async {
    if (!_isPageActive) return;

    setState(() {
      _isListening = true;
      _userAnswer = ''; // Clear previous answer
    });

    speechToText.listen(onResult: (result) {
      setState(() {
        _userAnswer = result.recognizedWords; // Show live answer
      });

      if (result.finalResult) {
        _stopListening();
      }
    });
  }

  // ✅ Stop Listening and Wait for Double Tap
  void _stopListening() async {
    if (!_isPageActive) return;

    setState(() {
      _isListening = false;
    });

    if (_userAnswer.isNotEmpty) {
      _answers.add(_userAnswer); // ✅ Save user's answer
    } else {
      _answers.add("No answer given"); // ✅ Handle empty answer
    }
  }

  // ✅ Move to Next Question on Double Tap
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = ''; // Clear previous answer
      });
      _speakQuestion(_questions[_currentQuestionIndex]);
    } else {
      _showCompletionDialog();
    }
  }

  // ✅ Calculate Feedback and Rating
  void _calculateFeedback() {
    int correctAnswers = 0;
    for (String answer in _answers) {
      if (answer.toLowerCase().contains('correct')) {
        correctAnswers++;
      }
    }

    double accuracy = (correctAnswers / _questions.length) * 100;
    _interviewRating = (accuracy / 20).clamp(1.0, 5.0); // Rating out of 5

    if (accuracy >= 80) {
      _feedback = "Excellent performance! Keep it up!";
    } else if (accuracy >= 60) {
      _feedback = "Good effort! Focus on improving specific areas.";
    } else {
      _feedback = "Practice more and enhance your knowledge.";
    }
  }

  // ✅ Show Interview Completion Dialog and Save Report
  // ✅ Show Interview Completion Dialog and Save Report
  void _showCompletionDialog() {
    if (!_isPageActive) return;

    _calculateFeedback(); // ✅ Calculate feedback and rating dynamically

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Interview Completed!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
            'All AI-generated questions have been asked. Great job!'),
        actions: [
          TextButton(
            onPressed: () async {
              _stopAll();
              await _saveInterviewReport(); // ✅ Save report before exiting

              // Fetch user-specific interview data after saving the report
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('interviews')
                  .get()
                  .then((querySnapshot) {
                // Make sure to check if the querySnapshot has documents
                if (querySnapshot.docs.isNotEmpty) {
                  List<DocumentSnapshot> interviews = querySnapshot.docs;
                  Navigator.of(context).pop(); // Close the dialog

                  // Navigate to ViewReportsPage, passing the interviews data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewReportsPage(
                        interviews: interviews, // Passing fetched interviews
                      ),
                    ),
                  );
                } else {
                  // Handle case where there are no interviews
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No interview data found.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ✅ Save Interview Report to Firebase
  Future<void> _saveInterviewReport() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Use the user's UID to save to their specific document
        .collection('interviews') // Nested subcollection
        .add({
      'intervieweeId': userId,
      'interviewerId': 'AI',
      'date': DateTime.now().toIso8601String(),
      'questions': _questions,
      'answers': _answers,
      'rating': _interviewRating,
      'feedback': _feedback,
      'type': widget.isAI ? 'AI' : 'Scheduled',
      'status': 'completed',
    });

    print("Interview report saved successfully!");
  }

  // ✅ Stop TTS and Speech on Exit or Back Press
  void _stopAll() {
    flutterTts.stop(); // Stop TTS
    speechToText.stop(); // Stop listening
    setState(() {
      _isPageActive = false;
    });
  }

  // ✅ Stop when exiting the page
  @override
  void dispose() {
    _stopAll(); // Stop everything when exiting
    super.dispose();
  }

  // ✅ Show Error Message
  void _showError(String message) {
    setState(() {
      _isParsing = false;
    });

    if (_isPageActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _nextQuestion, // ✅ Double-tap to proceed to next question
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white, // 🎨 Change the back button color here
          ),
          backgroundColor: Colors.black,
          title: const Text(
            'AI Interview',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewReportsPage(interviews: [])),
                );
              },
            ),
          ],
        ),
        body: AnimatedContainer(
          duration: const Duration(seconds: 1),
          decoration: _showCountdown
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_bgColor, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : const BoxDecoration(
                  color: Colors.black,
                ),
          child: Center(
            child: _showCountdown
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        _motivationalMessage,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _opacity,
                        child: Text(
                          '$_countdown',
                          style: TextStyle(
                            fontSize: _countdown == 1 ? 80 : 60,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.orange, Colors.pink],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                            shadows: const [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.black54,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isListening)
                        const Text(
                          'Listening...',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        ),
                      if (_userAnswer.isNotEmpty)
                        Text(
                          'You said: $_userAnswer',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Double-tap to proceed to the next question.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
