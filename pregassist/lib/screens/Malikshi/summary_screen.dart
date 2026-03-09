import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final int score;
  final VoidCallback onStartNew;
  final VoidCallback? onBack;

  const SummaryScreen({
    super.key,
    required this.score,
    required this.onStartNew,
    this.onBack,
  });

  String _getRiskLevel(int score) {
    if (score < 30) return 'low';
    if (score < 60) return 'medium';
    return 'high';
  }

  Color _getScoreColor(String status) {
    switch (status) {
      case 'low':
        return const Color(0xFF16A34A);
      case 'medium':
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFFDC2626);
    }
  }

  String _getEmoji() {
    final riskLevel = _getRiskLevel(score);
    switch (riskLevel) {
      case 'low':
        return '😊';
      case 'medium':
        return '😐';
      default:
        return '😟';
    }
  }

  String _getStatusText() {
    final riskLevel = _getRiskLevel(score);
    switch (riskLevel) {
      case 'low':
        return 'Great wellness';
      case 'medium':
        return 'Moderate concern';
      default:
        return 'Needs attention';
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousSessions = [
      {
        'date': 'Nov 10, 2025',
        'score': 45,
        'trend': 'down',
        'status': 'medium',
      },
      {'date': 'Nov 7, 2025', 'score': 58, 'trend': 'up', 'status': 'medium'},
      {'date': 'Nov 3, 2025', 'score': 32, 'trend': 'down', 'status': 'low'},
    ];

    final suggestions = [
      {
        'emoji': '🧘‍♀️',
        'title': 'Daily Meditation',
        'description': 'Practice 10 minutes daily',
      },
      {
        'emoji': '💤',
        'title': 'Sleep Schedule',
        'description': 'Maintain consistent sleep times',
      },
      {
        'emoji': '👥',
        'title': 'Social Connection',
        'description': 'Connect with loved ones regularly',
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: onBack != null
                                    ? IconButton(
                                        onPressed: onBack,
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.favorite,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),

                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MomCare',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Wellness Dashboard',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFDBEAFE),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Latest Assessment',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFDBEAFE),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$score',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        ' / 100',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getStatusText(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFDBEAFE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getEmoji(),
                                  style: const TextStyle(fontSize: 36),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.chat_bubble,
                            label: 'New Check-in',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                            ),
                            onTap: onStartNew,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.calendar_today,
                            label: 'View History',
                            gradient: null,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Recent Assessments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...previousSessions.map((session) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSessionCard(session),
                      );
                    }),
                    const SizedBox(height: 32),

                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...suggestions.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSuggestionCard(suggestion),
                      );
                    }),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDBEAFE), Color(0xFFE9D5FF)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💙 You\'re Not Alone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Remember, it\'s normal to experience ups and downs during pregnancy. We\'re here to support you every step of the way. Your mental health matters.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D4ED8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
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
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Gradient? gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          border: gradient == null
              ? Border.all(color: const Color(0xFFBFDBFE))
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (gradient != null)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: gradient != null ? Colors.white : const Color(0xFF2563EB),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: gradient != null
                    ? Colors.white
                    : const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final status = session['status'] as String;
    final trend = session['trend'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['date'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const Text(
                  'Wellness Check',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          Text(
            '${session['score']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(status),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            trend == 'down' ? Icons.trending_down : Icons.trending_up,
            color: trend == 'down'
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFE9D5FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                suggestion['emoji'] as String,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  suggestion['description'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
