import 'package:flutter/material.dart';
import '../../models/pulasthi/assessment_data.dart';

class EventsResultScreen extends StatefulWidget {
  final AssessmentData data;

  const EventsResultScreen({super.key, required this.data});

  @override
  State<EventsResultScreen> createState() => _EventsResultScreenState();
}

class _EventsResultScreenState extends State<EventsResultScreen> {
  late int _accelerations;
  late int _contractions;
  late int _mildDecelerations;
  late int _severeDecelerations;
  late int _prolongedDecelerations;

  PredictionResult? _prediction;

  @override
  void initState() {
    super.initState();
    _accelerations = widget.data.accelerations;
    _contractions = widget.data.contractions;
    _mildDecelerations = widget.data.mildDecelerations;
    _severeDecelerations = widget.data.severeDecelerations;
    _prolongedDecelerations = widget.data.prolongedDecelerations;
  }

  void _handlePredict() {
    Classification classification = Classification.normal;
    final List<String> reasons = [];

    // Check baseline FHR
    final baselineFHR = widget.data.baselineFHR!;
    if (baselineFHR >= 110 && baselineFHR <= 160) {
      reasons.add('Baseline FHR is within the normal range (110–160 bpm).');
    } else if (baselineFHR > 160 && baselineFHR <= 180) {
      reasons.add('Baseline FHR is mildly elevated (160–180 bpm).');
      classification = Classification.suspect;
    } else if (baselineFHR > 180) {
      reasons.add('Baseline FHR is significantly elevated (above 180 bpm).');
      classification = Classification.pathological;
    } else if (baselineFHR < 110) {
      reasons.add('Baseline FHR is below the normal range (below 110 bpm).');
      classification = classification == Classification.pathological
          ? Classification.pathological
          : Classification.suspect;
    }

    // Check severe and prolonged decelerations
    final totalSevere = _severeDecelerations + _prolongedDecelerations;
    if (totalSevere == 0) {
      reasons.add('No severe or prolonged decelerations detected.');
    } else if (totalSevere <= 2) {
      reasons.add('$totalSevere severe or prolonged deceleration(s) detected.');
      if (classification == Classification.normal) {
        classification = Classification.suspect;
      }
    } else {
      reasons.add('Multiple severe or prolonged decelerations detected ($totalSevere).');
      classification = Classification.pathological;
    }

    // Check accelerations
    final expectedAccelerations = (widget.data.segmentDuration! / 10).floor();
    if (_accelerations >= expectedAccelerations) {
      reasons.add(
        'Good number of accelerations ($_accelerations) indicating fetal reactivity.',
      );
    } else if (_accelerations == 0 && classification != Classification.pathological) {
      reasons.add('No accelerations detected, which may indicate reduced fetal reactivity.');
      if (classification == Classification.normal) {
        classification = Classification.suspect;
      }
    }

    // Check contractions
    if (_contractions <= 5) {
      reasons.add('Low to moderate number of contractions, consistent with a stable pattern.');
    }

    setState(() {
      _prediction = PredictionResult(
        classification: classification,
        reasons: reasons,
      );
    });
  }

  void _handleSave() {
    widget.data.accelerations = _accelerations;
    widget.data.contractions = _contractions;
    widget.data.mildDecelerations = _mildDecelerations;
    widget.data.severeDecelerations = _severeDecelerations;
    widget.data.prolongedDecelerations = _prolongedDecelerations;
    widget.data.prediction = _prediction;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Saved'),
        content: const Text('The CTG assessment has been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDetailedExplanation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Detailed Explanation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This prediction is based on established CTG interpretation guidelines and the following parameters:',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildParameterRow('Baseline FHR:', '${widget.data.baselineFHR} bpm'),
                      _buildParameterRow(
                        'FHR Range:',
                        '${widget.data.lowestFHR}–${widget.data.highestFHR} bpm',
                      ),
                      _buildParameterRow('Accelerations:', '$_accelerations'),
                      _buildParameterRow(
                        'Decelerations:',
                        '$_mildDecelerations mild, $_severeDecelerations severe, $_prolongedDecelerations prolonged',
                      ),
                      _buildParameterRow('Contractions:', '$_contractions'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Normal CTG typically shows a baseline FHR of 110–160 bpm, presence of accelerations, no or minimal decelerations, and stable variability.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Suspect or pathological patterns may indicate the need for further assessment, continuous monitoring, or intervention. Always correlate CTG findings with clinical context and other maternal-fetal assessments.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B80FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Same background gradient as your other redesigned screens
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
            Color(0xFFDBEAFE),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // ✅ No back icon on header (as requested)
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B80FF),
                  Color(0xFFAC46FF),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          title: const Text(
            "New CTG Assessment",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Step 3 of 3 – Events & Result",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Progress
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 3 / 3,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF2B80FF)),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Events in this segment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      _sectionCard(
                        child: Column(
                          children: [
                            _buildStepperInput(
                              value: _accelerations,
                              onChanged: (value) => setState(() => _accelerations = value),
                              label: 'Number of accelerations',
                              helperText: 'Episodes where FHR rises ≥15 bpm for ≥15 seconds.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _contractions,
                              onChanged: (value) => setState(() => _contractions = value),
                              label: 'Number of uterine contractions',
                              helperText: 'Count peaks in the uterine contraction trace.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _mildDecelerations,
                              onChanged: (value) => setState(() => _mildDecelerations = value),
                              label: 'Number of mild decelerations',
                              helperText: 'Shallow, short FHR drops.',
                              tooltip: 'Drop <30 bpm below baseline and <60 s duration.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _severeDecelerations,
                              onChanged: (value) => setState(() => _severeDecelerations = value),
                              label: 'Number of severe decelerations',
                              helperText: 'Deeper or longer FHR drops.',
                              tooltip:
                                  'Drop ≥30 bpm below baseline or ≥60 s duration (but <2–3 min).',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _prolongedDecelerations,
                              onChanged: (value) =>
                                  setState(() => _prolongedDecelerations = value),
                              label: 'Number of prolonged decelerations',
                              helperText: 'Decelerations lasting ≥2–3 minutes.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handlePredict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B80FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Predict fetal status',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      if (_prediction != null) ...[
                        const SizedBox(height: 16),
                        _buildPredictionResult(),
                      ],

                      const SizedBox(height: 16),

                      // Keep back button on form (as requested)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2B80FF),
                                side: const BorderSide(color: Color(0xFF2B80FF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _prediction != null ? _handleSave : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B80FF),
                                disabledBackgroundColor: const Color(0xFFE5E7EB),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: const Color(0xFF9CA3AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save assessment',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _buildStepperInput({
    required int value,
    required ValueChanged<int> onChanged,
    required String label,
    required String helperText,
    String? tooltip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (tooltip != null)
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline, size: 16, color: Colors.black45),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _circleIconButton(
              icon: Icons.remove,
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _circleIconButton(
              icon: Icons.add,
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        color: Colors.white.withOpacity(0.9),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: const Color(0xFF374151),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPredictionResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _prediction!.backgroundColor,
        border: Border.all(color: _prediction!.borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediction result',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_prediction!.icon, color: _prediction!.iconColor, size: 32),
              const SizedBox(width: 12),
              Text(
                _prediction!.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _prediction!.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Why this result?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._prediction!.reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.black45, fontSize: 14)),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _showDetailedExplanation,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2B80FF),
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'View detailed explanation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
