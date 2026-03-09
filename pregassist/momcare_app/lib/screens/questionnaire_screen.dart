import 'package:flutter/material.dart';

class Question {
  final int id;
  final String question;
  final String emoji;

  Question({
    required this.id,
    required this.question,
    required this.emoji,
  });
}

class ResponseOption {
  final String label;
  final int value;
  final IconData icon;
  final List<Color> colors;

  ResponseOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });
}

class QuestionnaireScreen extends StatefulWidget {
  final Function(List<int>) onComplete;

  const QuestionnaireScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestion = 0;
  final List<int> _answers = [];
  int? _selectedAnswer;

  final List<Question> _questions = [
    Question(
      id: 1,
      question:
          'How often have you felt down, depressed, or hopeless in the past week?',
      emoji: '💭',
    ),
    Question(
      id: 2,
      question:
          'How often have you had little interest or pleasure in doing things?',
      emoji: '🎯',
    ),
    Question(
      id: 3,
      question: 'How would you rate your sleep quality recently?',
      emoji: '😴',
    ),
    Question(
      id: 4,
      question:
          'How often do you feel anxious or worried about your pregnancy?',
      emoji: '💗',
    ),
    Question(
      id: 5,
      question: 'How often do you feel overwhelmed by daily tasks?',
      emoji: '📋',
    ),
    Question(
      id: 6,
      question:
          'How connected do you feel to your support system (family, friends)?',
      emoji: '👥',
    ),
  ];

  final List<ResponseOption> _options = [
    ResponseOption(
      label: 'Not at all',
      value: 0,
      icon: Icons.sentiment_very_satisfied,
      colors: [Color(0xFF4ADE80), Color(0xFF10B981)],
    ),
    ResponseOption(
      label: 'Sometimes',
      value: 1,
      icon: Icons.sentiment_neutral,
      colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
    ),
    ResponseOption(
      label: 'Often',
      value: 2,
      icon: Icons.sentiment_dissatisfied,
      colors: [Color(0xFFF97316), Color(0xFFF87171)],
    ),
    ResponseOption(
      label: 'Almost always',
      value: 3,
      icon: Icons.sentiment_very_dissatisfied,
      colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
    ),
  ];

  void _handleAnswer(int value) {
    setState(() {
      _selectedAnswer = value;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      final newAnswers = [..._answers, value];

      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _answers.add(value);
          _currentQuestion++;
          _selectedAnswer = null;
        });
      } else {
        widget.onComplete(newAnswers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ((_currentQuestion + 1) / _questions.length) * 100;

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${_currentQuestion + 1} of ${_questions.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${progress.round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0xFFDBEAFE),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _questions[_currentQuestion].emoji,
                          key: ValueKey(_currentQuestion),
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                      const SizedBox(height: 24),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          key: ValueKey(_currentQuestion),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            _questions[_currentQuestion].question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.5,
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ..._options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildOptionButton(option, index),
                        );
                      }).toList(),

                      const SizedBox(height: 48),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _questions.length,
                          (index) => Container(
                            width: index == _currentQuestion ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              gradient: index == _currentQuestion
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFFA855F7)
                                      ],
                                    )
                                  : null,
                              color: index < _currentQuestion
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFFBFDBFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(ResponseOption option, int index) {
    final isSelected = _selectedAnswer == option.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.diagonal3Values(
  isSelected ? 0.95 : 1.0,
  isSelected ? 0.95 : 1.0,
  1.0,
),

      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: option.colors)
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFBFDBFE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isSelected ? 0.15 : 0.05,
              ),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleAnswer(option.value),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 24,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF60A5FA)
                            .withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
