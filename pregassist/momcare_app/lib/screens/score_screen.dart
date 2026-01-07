import 'package:flutter/material.dart';
import 'dart:async';

class ScoreScreen extends StatefulWidget {
  final List<int> answers;
  final VoidCallback onContinue;

  const ScoreScreen({
    Key? key,
    required this.answers,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with SingleTickerProviderStateMixin {
  int _displayScore = 0;
  bool _showAlert = false;
  late AnimationController _controller;

  int get normalizedScore {
    final totalScore = widget.answers.fold(0, (sum, answer) => sum + answer);
    final maxScore = widget.answers.length * 3;
    return ((totalScore / maxScore) * 100).round();
  }

  String get riskLevel {
    if (normalizedScore < 30) return 'low';
    if (normalizedScore < 60) return 'medium';
    return 'high';
  }

  Map<String, dynamic> get riskConfig {
    switch (riskLevel) {
      case 'low':
        return {
          'colors': [Color(0xFF4ADE80), Color(0xFF10B981)],
          'bgColor': Color(0xFFF0FDF4),
          'textColor': Color(0xFF15803D),
          'icon': Icons.check_circle,
          'title': 'You\'re Doing Great! 🌟',
          'message':
              'Your mental wellness indicators are positive. Keep up the great work with self-care!',
          'iconColor': Color(0xFF22C55E),
        };
      case 'medium':
        return {
          'colors': [Color(0xFFFBBF24), Color(0xFFF97316)],
          'bgColor': Color(0xFFFEFCE8),
          'textColor': Color(0xFF854D0E),
          'icon': Icons.info,
          'title': 'Let\'s Support You 💛',
          'message':
              'Your responses suggest you might benefit from some extra support and relaxation techniques.',
          'iconColor': Color(0xFFEAB308),
        };
      default:
        return {
          'colors': [Color(0xFFF87171), Color(0xFFF43F5E)],
          'bgColor': Color(0xFFFEF2F2),
          'textColor': Color(0xFF991B1B),
          'icon': Icons.error,
          'title': 'We\'re Here for You ❤️',
          'message':
              'Your responses indicate you may need immediate support. We\'ve notified your trusted contact.',
          'iconColor': Color(0xFFEF4444),
        };
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animateScore();
  }

  void _animateScore() {
    const duration = 2000;
    const steps = 60;
    final increment = normalizedScore / steps;
    var currentStep = 0;

    Timer.periodic(const Duration(milliseconds: duration ~/ steps), (timer) {
      if (currentStep >= steps) {
        timer.cancel();
        if (riskLevel == 'high') {
          setState(() {
            _showAlert = true;
          });
        }
      } else {
        setState(() {
          _displayScore = (increment * currentStep).round();
        });
        currentStep++;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = riskConfig;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFFAF5FF),
              Color(0xFFDBEAFE),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),

                const Text(
                  'Your Wellness Assessment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on your responses and facial analysis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 48),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: config['colors'] as List<Color>,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_displayScore',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const Text(
                            'Wellness Score',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: config['bgColor'] as Color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          config['icon'] as IconData,
                          size: 32,
                          color: config['iconColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: config['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        config['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: config['textColor'] as Color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        config['message'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: config['textColor'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showAlert && riskLevel == 'high') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFECDD3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: Color(0xFFEF4444),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Emergency Support Activated',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7F1D1D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your trusted contact has been notified. Please consider reaching out to them or a mental health professional.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF991B1B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crisis Helplines:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7F1D1D),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'National Suicide Prevention: 988\nCrisis Text Line: Text "HELLO" to 741741',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF991B1B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Assessment Components',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressBar('Questionnaire', normalizedScore),
                      const SizedBox(height: 12),
                      _buildProgressBar('Facial Analysis', 45),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        riskLevel == 'medium'
                            ? 'View Suggested Exercises'
                            : 'View Summary',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int percentage) {
    final config = riskConfig;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: const Color(0xFFDBEAFE),
              valueColor: AlwaysStoppedAnimation<Color>(
                (config['colors'] as List<Color>)[0],
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
      ],
    );
  }
}
