import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/Malikshi/emotion_record.dart';

/// Screen that displays an emotion timeline graph and session summary
/// after a chatbot session ends.
class EmotionGraphScreen extends StatefulWidget {
  final List<EmotionRecord> emotionRecords;
  final VoidCallback onStartNew;
  final VoidCallback? onBack;
  final VoidCallback? onAlertTrustedPerson;
  final VoidCallback? onViewExercises;

  const EmotionGraphScreen({
    super.key,
    required this.emotionRecords,
    required this.onStartNew,
    this.onBack,
    this.onAlertTrustedPerson,
    this.onViewExercises,
  });

  @override
  State<EmotionGraphScreen> createState() => _EmotionGraphScreenState();
}

class _EmotionGraphScreenState extends State<EmotionGraphScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // All combined records (text + image detections)
  List<EmotionRecord> get _textRecords =>
      widget.emotionRecords.where((r) => r.source == 'combined').toList();

  bool get _hasImageRecords =>
      widget.emotionRecords.any((r) => r.source == 'combined');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Computed Values ───

  int get _totalInteractions => _textRecords.length;

  int get _negativeCount => _textRecords.where((r) => r.isNegative).length;

  /// Most frequently detected emotion across all records.
  String get _dominantEmotion {
    if (_textRecords.isEmpty) return 'Neutral';
    final freq = <String, int>{};
    for (final r in _textRecords) {
      freq[r.emotionLabel] = (freq[r.emotionLabel] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Frequency count of each emotion label.
  Map<String, int> get _emotionFrequency {
    final freq = <String, int>{};
    for (final label in _emotionLabels) {
      freq[label] = 0;
    }
    for (final r in _textRecords) {
      if (freq.containsKey(r.emotionLabel)) {
        freq[r.emotionLabel] = freq[r.emotionLabel]! + 1;
      }
    }
    return freq;
  }

  static String _emotionEmoji(String emotion) {
    switch (emotion) {
      case 'Happy':   return '😊';
      case 'Neutral': return '😐';
      case 'Sad':     return '😢';
      case 'Fear':    return '😨';
      case 'Anger':   return '😠';
      default:        return '😐';
    }
  }

  String get _riskLevel {
    if (_totalInteractions == 0) return 'Low';
    final ratio = _negativeCount / _totalInteractions;
    if (ratio >= 0.6) return 'High';
    if (ratio >= 0.3) return 'Medium';
    return 'Low';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData get _riskIcon {
    switch (_riskLevel) {
      case 'High':
        return Icons.warning_rounded;
      case 'Medium':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  static Color _emotionColor(String label) {
    switch (label) {
      case 'Happy':
        return const Color(0xFF10B981);
      case 'Neutral':
        return const Color(0xFF3B82F6);
      case 'Sad':
        return const Color(0xFF6366F1);
      case 'Fear':
        return const Color(0xFFF97316);
      case 'Anger':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static const List<String> _emotionLabels = [
    'Anger',
    'Fear',
    'Sad',
    'Neutral',
    'Happy',
  ];

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _totalInteractions == 0
                    ? _buildEmptyState()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Row(
            children: [
              if (widget.onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Emotion Analysis',
                      style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty State ───

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                size: 40,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasImageRecords
                  ? 'No text-based emotion data was captured this session.\nThe graph reflects image-based signals only.'
                  : 'No emotion data was captured this session.\nStart a chat to see your emotional patterns.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Main Content ───
  
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        children: [
          _buildDominantEmotionCard(),
          const SizedBox(height: 16),
          _buildSummaryPanel(),
          const SizedBox(height: 20),
          _buildFrequencyBars(),
          const SizedBox(height: 16),
          _buildChartCard(),
          const SizedBox(height: 12),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildDisclaimer(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ─── Dominant Emotion Card ───

  Widget _buildDominantEmotionCard() {
    final emotion = _dominantEmotion;
    final color = _emotionColor(emotion);
    final count = _emotionFrequency[emotion] ?? 0;
    final percent = _totalInteractions > 0
        ? (count / _totalInteractions * 100).toStringAsFixed(0)
        : '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _emotionEmoji(emotion),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Most Common Emotion',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emotion,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$count out of $_totalInteractions interactions ($percent%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Emotion Frequency Bars ───

  Widget _buildFrequencyBars() {
    final freq = _emotionFrequency;
    final max = freq.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emotion Frequency',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...(_emotionLabels.map((label) {
            final count = freq[label] ?? 0;
            final ratio = max > 0 ? count / max : 0.0;
            final color = _emotionColor(label);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio.toDouble(),
                        minHeight: 14,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  // ─── Summary Panel ───

  Widget _buildSummaryPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Interactions',
                value: '$_totalInteractions',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.sentiment_dissatisfied_rounded,
                label: 'Negative',
                value: '$_negativeCount',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 12),
              _buildRiskCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _riskColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _riskColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(_riskIcon, size: 22, color: _riskColor),
            const SizedBox(height: 6),
            Text(
              _riskLevel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _riskColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Risk Level',
              style: TextStyle(
                fontSize: 11,
                color: _riskColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chart ───

  Widget _buildChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'Emotion Timeline',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: -0.5,
                maxY: 4.5,
                minX: 0,
                maxX: (_textRecords.length - 1).toDouble().clamp(
                  1,
                  double.infinity,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 0.8),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Interaction',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble() &&
                            value >= 0 &&
                            value < _textRecords.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${value.toInt() + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _emotionLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _emotionLabels[idx],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _emotionColor(_emotionLabels[idx]),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _textRecords
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(e.key.toDouble(), e.value.numericValue),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          const Color(0xFF3B82F6).withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final emotion = _textRecords[index].emotionLabel;
                        return FlDotCirclePainter(
                          radius: 6,
                          color: _emotionColor(emotion),
                          strokeWidth: 2.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final record = _textRecords[spot.spotIndex];
                        return LineTooltipItem(
                          record.emotionLabel,
                          TextStyle(
                            color: _emotionColor(record.emotionLabel),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Legend ───

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: _emotionLabels.map((label) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _emotionColor(label),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── Disclaimer ───

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF60A5FA)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This visualization reflects temporary emotional patterns '
              'and is not a medical diagnosis.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF3B82F6),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Risk-based action button
        if (_riskLevel == 'High' && widget.onAlertTrustedPerson != null) ...[
          _buildHighRiskAlert(),
          const SizedBox(height: 12),
        ],
        if (_riskLevel == 'Medium' && widget.onViewExercises != null) ...[
          _buildMediumRiskExercises(),
          const SizedBox(height: 12),
        ],
        // Back to Chat
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onStartNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              icon: const Icon(Icons.chat_rounded, color: Colors.white),
              label: const Text(
                'Back to Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── High Risk: Alert Trusted Person ───

  Widget _buildHighRiskAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 36,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          const Text(
            'High Risk Detected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'We recommend alerting a trusted person who can support you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onAlertTrustedPerson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                icon: const Icon(
                  Icons.contact_phone_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Alert Trusted Person',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Medium Risk: View Exercises ───

  Widget _buildMediumRiskExercises() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.self_improvement_rounded,
            size: 36,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          const Text(
            'Moderate Stress Detected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try some wellness exercises to help manage your stress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF92400E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.onViewExercises,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                icon: const Icon(Icons.spa_rounded, color: Colors.white),
                label: const Text(
                  'View Wellness Exercises',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
