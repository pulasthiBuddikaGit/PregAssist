import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/score_screen.dart';
import 'screens/suggestion_screen.dart';
import 'screens/summary_screen.dart';

void main() {
  runApp(const MomCareApp());
}

class MomCareApp extends StatelessWidget {
  const MomCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'System',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AppNavigator(),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentScreen = 0;
  List<int> _answers = [];
  int _score = 0;

  void _navigateToScreen(int screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  void _handleQuestionnaireComplete(List<int> answers) {
    setState(() {
      _answers = answers;
      _currentScreen = 4; // camera screen
    });
  }

  void _handleCameraComplete() {
    // Calculate score
    final totalScore = _answers.fold(0, (sum, answer) => sum + answer);
    final maxScore = _answers.length * 3;
    final normalizedScore = ((totalScore / maxScore) * 100).round();
    
    setState(() {
      _score = normalizedScore;
      _currentScreen = 5; // score screen
    });
  }

  void _handleScoreContinue() {
    if (_score >= 30 && _score < 60) {
      setState(() {
        _currentScreen = 6; // suggestion screen
      });
    } else {
      setState(() {
        _currentScreen = 7; // summary screen
      });
    }
  }

  void _handleStartNew() {
    setState(() {
      _answers = [];
      _score = 0;
      _currentScreen = 2; // chatbot screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 448),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 0:
        return WelcomeScreen(
          onGetStarted: () => _navigateToScreen(1),
        );
      case 1:
        return AuthScreen(
          onBack: () => _navigateToScreen(0),
          onComplete: () => _navigateToScreen(2),
        );
      case 2:
        return ChatbotScreen(
          onComplete: () => _navigateToScreen(3),
        );
      case 3:
        return QuestionnaireScreen(
          onComplete: _handleQuestionnaireComplete,
        );
      case 4:
        return CameraScreen(
          onComplete: _handleCameraComplete,
        );
      case 5:
        return ScoreScreen(
          answers: _answers,
          onContinue: _handleScoreContinue,
        );
      case 6:
        return SuggestionScreen(
          onContinue: () => _navigateToScreen(7),
        );
      case 7:
        return SummaryScreen(
          score: _score,
          onStartNew: _handleStartNew,
        );
      default:
        return const SizedBox();
    }
  }
}
