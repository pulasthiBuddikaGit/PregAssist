import 'package:flutter/material.dart';

class Exercise {
  final int id;
  final String title;
  final String duration;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final List<String> steps;

  Exercise({
    required this.id,
    required this.title,
    required this.duration,
    required this.description,
    required this.icon,
    required this.colors,
    required this.steps,
  });
}

class SuggestionScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const SuggestionScreen({super.key, required this.onContinue, this.onBack});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen>
    with SingleTickerProviderStateMixin {
  Exercise? _selectedExercise;
  bool _isPlaying = false;
  late AnimationController _breatheController;

  final List<Exercise> _exercises = [
    Exercise(
      id: 1,
      title: 'Deep Breathing',
      duration: '5 min',
      description: 'Calm your mind with guided breathing exercises',
      icon: Icons.air,
      colors: [Color(0xFF60A5FA), Color(0xFF06B6D4)],
      steps: [
        'Find a comfortable seated position',
        'Breathe in slowly through your nose for 4 counts',
        'Hold your breath for 4 counts',
        'Exhale slowly through your mouth for 6 counts',
        'Repeat for 5 minutes',
      ],
    ),
    Exercise(
      id: 2,
      title: 'Body Scan Meditation',
      duration: '10 min',
      description: 'Release tension and connect with your body',
      icon: Icons.auto_awesome,
      colors: [Color(0xFFA78BFA), Color(0xFFF472B6)],
      steps: [
        'Lie down in a comfortable position',
        'Close your eyes and take deep breaths',
        'Focus on each part of your body, starting from toes',
        'Notice any tension and consciously relax',
        'Move slowly up to your head',
      ],
    ),
    Exercise(
      id: 3,
      title: 'Loving-Kindness Meditation',
      duration: '7 min',
      description: 'Cultivate self-compassion and positive feelings',
      icon: Icons.favorite,
      colors: [Color(0xFFFB7185), Color(0xFFFB923C)],
      steps: [
        'Sit comfortably and close your eyes',
        'Think of someone you love deeply',
        'Send them wishes: "May you be happy, healthy, safe"',
        'Now direct those wishes to yourself',
        'Extend to your baby and loved ones',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  void _startExercise(Exercise exercise) {
    setState(() {
      _selectedExercise = exercise;
      _isPlaying = true;
      _breatheController.repeat();
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _breatheController.repeat();
      } else {
        _breatheController.stop();
      }
    });
  }

  void _backToList() {
    setState(() {
      _selectedExercise = null;
      _isPlaying = false;
      _breatheController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedExercise != null) {
      return _buildExerciseView(_selectedExercise!);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.onBack != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      const Text(
                        'Wellness Exercises',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Try these exercises to help manage stress and improve your mood',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1758274526671-ad18176acb01?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZWFjZWZ1bCUyMGJyZWF0aGluZyUyMG1lZGl0YXRpb258ZW58MXx8fHwxNzYyOTM0MDQ4fDA&ixlib=rb-4.1.0&q=80&w=1080',
                          height: 192,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 192,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Exercise cards
                      ..._exercises.map((exercise) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildExerciseCard(exercise),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: widget.onContinue,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Continue to Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
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

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () => _startExercise(exercise),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: exercise.colors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(exercise.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exercise.duration} • Tap to start',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseView(Exercise exercise) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _backToList,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const Text(
                      'Back to Exercises',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Exercise header
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: exercise.colors),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  exercise.icon,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                Text(
                                  exercise.duration,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              exercise.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exercise.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Animated circle
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _breatheController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF93C5FD), Color(0xFFC084FC)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isPlaying ? '🌸' : '${exercise.icon}',
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isPlaying ? 'Breathe...' : 'Ready to begin?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                if (_isPlaying)
                                  const Text(
                                    'Follow the rhythm',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Control button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isPlaying
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  )
                                : LinearGradient(colors: exercise.colors),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _togglePlay,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              _isPlaying ? 'Pause Exercise' : 'Start Exercise',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Steps
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...exercise.steps.asMap().entries.map((entry) {
                              final index = entry.key;
                              final step = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: exercise.colors,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          step,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1E40AF),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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
}
