import 'package:flutter/material.dart';
import '../../models/pulasthi/assessment_data.dart';
import '../../services/ctg_shadow_explainability_service.dart';
import '../../services/fetal_onnx_service.dart';
import 'ctg_segment_screen.dart';

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
  OnnxPrediction? _onnxPrediction;
  ShadowExplainabilityResult? _shadowExplanation;
  String? _explanationError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accelerations = widget.data.accelerations;
    _contractions = widget.data.contractions;
    _mildDecelerations = widget.data.mildDecelerations;
    _severeDecelerations = widget.data.severeDecelerations;
    _prolongedDecelerations = widget.data.prolongedDecelerations;
  }

  bool get _hasShadowMismatch {
    if (_onnxPrediction == null || _shadowExplanation == null) return false;
    return _onnxPrediction!.label != _shadowExplanation!.onnxClass;
  }

  /// Convert class id -> your UI object
  PredictionResult _predictionFromClass(int cls) {
    switch (cls) {
      case 1:
        return PredictionResult(
          classification: Classification.normal,
          reasons: const [
            'The ONNX ML model predicted Normal fetal health (Class 1).',
          ],
        );
      case 2:
        return PredictionResult(
          classification: Classification.suspect,
          reasons: const [
            'The ONNX ML model predicted Suspect fetal health (Class 2).',
          ],
        );
      case 3:
        return PredictionResult(
          classification: Classification.pathological,
          reasons: const [
            'The ONNX ML model predicted Pathological fetal health (Class 3).',
          ],
        );
      default:
        return PredictionResult(
          classification: Classification.suspect,
          reasons: ['Unexpected model output class: $cls'],
        );
    }
  }

  /// Build the EXACT 12 model features (same order as manual_12c_features.json)
  List<double> _buildFeatures12() {
    final baseline = widget.data.baselineFHR!;
    final lowest = widget.data.lowestFHR!;
    final highest = widget.data.highestFHR!;
    final durationMin = widget.data.segmentDuration!;

    final durationSec = durationMin * 60.0;

    final accelerations = _accelerations / durationSec;
    final uterineContractions = _contractions / durationSec;
    final lightDecels = _mildDecelerations / durationSec;
    final severeDecels = _severeDecelerations / durationSec;
    final prolongedDecels = _prolongedDecelerations / durationSec;

    final width = (highest - lowest).toDouble();

    return <double>[
      baseline.toDouble(), // baseline value
      accelerations, // accelerations (per second)
      uterineContractions, // uterine_contractions (per second)
      lightDecels, // light_decelerations (per second)
      severeDecels, // severe_decelerations (per second)
      prolongedDecels, // prolongued_decelerations (per second)
      lowest.toDouble(), // histogram_min
      highest.toDouble(), // histogram_max
      width, // histogram_width
      baseline.toDouble(), // histogram_mean (training trick)
      baseline.toDouble(), // histogram_mode (training trick)
      baseline.toDouble(), // histogram_median (training trick)
    ];
  }

  Future<void> _handlePredict() async {
    // Safety checks (baseline/lowest/highest should exist from prior steps)
    if (widget.data.baselineFHR == null ||
        widget.data.lowestFHR == null ||
        widget.data.highestFHR == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missing baseline/lowest/highest values.')),
      );
      return;
    }

    final width = widget.data.highestFHR! - widget.data.lowestFHR!;
    if (width <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Highest FHR must be greater than Lowest FHR.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
      _onnxPrediction = null;
      _shadowExplanation = null;
      _explanationError = null;
    });

    try {
      // Save stepper values into AssessmentData (optional but good practice)
      widget.data.accelerations = _accelerations;
      widget.data.contractions = _contractions;
      widget.data.mildDecelerations = _mildDecelerations;
      widget.data.severeDecelerations = _severeDecelerations;
      widget.data.prolongedDecelerations = _prolongedDecelerations;

      final features = _buildFeatures12();

      print('duration=${widget.data.segmentDuration}');
      print(
          'baseline=${widget.data.baselineFHR}, lowest=${widget.data.lowestFHR}, highest=${widget.data.highestFHR}');
      print(
          'counts: acc=$_accelerations uc=$_contractions mild=$_mildDecelerations severe=$_severeDecelerations prol=$_prolongedDecelerations');
      print('features12=${_buildFeatures12()}');

      // Main prediction from ONNX model.
      final onnxPrediction =
          await FetalOnnxService.instance.predictDetailed(features);

      // Explanation path from shadow tree (approximation model).
      ShadowExplainabilityResult? explanation;
      String? explanationError;
      try {
        explanation =
            await CtgShadowExplainabilityService.instance.explain(features);
      } catch (e) {
        explanationError = '$e';
      }

      setState(() {
        _prediction = _predictionFromClass(onnxPrediction.label);
        _onnxPrediction = onnxPrediction;
        _shadowExplanation = explanation;
        _explanationError = explanationError;
        widget.data.prediction = _prediction;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  // âœ… UPDATED: Reset + navigate directly to CTGSegmentScreen
  void _handleReset() {
    // reset shared data
    widget.data.segmentDuration = null;
    widget.data.baselineFHR = null;
    widget.data.lowestFHR = null;
    widget.data.highestFHR = null;

    widget.data.accelerations = 0;
    widget.data.contractions = 0;
    widget.data.mildDecelerations = 0;
    widget.data.severeDecelerations = 0;
    widget.data.prolongedDecelerations = 0;
    widget.data.prediction = null;
    _onnxPrediction = null;
    _shadowExplanation = null;
    _explanationError = null;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => CTGSegmentScreen(data: widget.data)),
      (route) => false,
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
                  'This result is produced by the offline ML model using the entered CTG parameters.',
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
                      _buildParameterRow(
                          'Baseline FHR:', '${widget.data.baselineFHR} bpm'),
                      _buildParameterRow(
                        'FHR Range:',
                        '${widget.data.lowestFHR}â€“${widget.data.highestFHR} bpm',
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
                if (_shadowExplanation != null) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Why the AI predicted this',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._shadowExplanation!.keyFactors.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '- ',
                            style:
                                TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Decision summary',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shadowExplanation!.decisionSummary,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Technical decision path',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ..._shadowExplanation!.pathRules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${rule.featureLabel}: ${_formatRuleValue(rule, rule.value)} ${rule.comparisonSymbol} ${_formatRuleValue(rule, rule.threshold)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _formatRuleValue(ShadowDecisionRule rule, double value) {
    final decimals = rule.unit == '/sec' ? 4 : 1;
    final number = value.toStringAsFixed(decimals);
    return rule.unit.isEmpty ? number : '$number${rule.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        "Step 3 of 3 â€“ Events & Result",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 3 / 3,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF2B80FF)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Events in this segment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        child: Column(
                          children: [
                            _buildStepperInput(
                              value: _accelerations,
                              onChanged: (v) =>
                                  setState(() => _accelerations = v),
                              label: 'Number of accelerations',
                              helperText:
                                  'Episodes where FHR rises â‰¥15 bpm for â‰¥15 seconds.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _contractions,
                              onChanged: (v) =>
                                  setState(() => _contractions = v),
                              label: 'Number of uterine contractions',
                              helperText:
                                  'Count peaks in the uterine contraction trace.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _mildDecelerations,
                              onChanged: (v) =>
                                  setState(() => _mildDecelerations = v),
                              label: 'Number of mild decelerations',
                              helperText: 'Shallow, short FHR drops.',
                              tooltip:
                                  'Drop <30 bpm below baseline and <60 s duration.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _severeDecelerations,
                              onChanged: (v) =>
                                  setState(() => _severeDecelerations = v),
                              label: 'Number of severe decelerations',
                              helperText: 'Deeper or longer FHR drops.',
                              tooltip:
                                  'Drop â‰¥30 bpm below baseline or â‰¥60 s duration.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _prolongedDecelerations,
                              onChanged: (v) =>
                                  setState(() => _prolongedDecelerations = v),
                              label: 'Number of prolonged decelerations',
                              helperText:
                                  'Decelerations lasting â‰¥2â€“3 minutes.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async => await _handlePredict(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B80FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  // 'Predict fetal status (ONNX + Explanation)',
                                  'Predict fetal status',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      if (_prediction != null) ...[
                        const SizedBox(height: 16),
                        _buildPredictionResult(),
                      ],
                      const SizedBox(height: 16),

                      // Back | Reset | Save (Reset navigates to CTGSegmentScreen)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2B80FF),
                                side:
                                    const BorderSide(color: Color(0xFF2B80FF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _prediction != null ? _handleReset : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side:
                                    const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _prediction != null ? _handleSave : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B80FF),
                                disabledBackgroundColor:
                                    const Color(0xFFE5E7EB),
                                foregroundColor: Colors.white,
                                disabledForegroundColor:
                                    const Color(0xFF9CA3AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (tooltip != null)
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline,
                    size: 16, color: Colors.black45),
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
                      fontSize: 22, fontWeight: FontWeight.bold),
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
        Text(helperText,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
    final onnx = _onnxPrediction;
    final explanation = _shadowExplanation;
    final classLabel = _prediction!.label.split(' (').first;

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
              Expanded(
                child: Text(
                  _prediction!.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _prediction!.textColor,
                  ),
                ),
              ),
            ],
          ),
          if (onnx?.confidence != null) ...[
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(onnx!.confidence! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
          if (onnx?.probabilities != null &&
              onnx!.probabilities!.length >= 3) ...[
            const SizedBox(height: 8),
            Text(
              'Normal ${(onnx.probabilities![0] * 100).toStringAsFixed(1)}%  |  '
              'Suspect ${(onnx.probabilities![1] * 100).toStringAsFixed(1)}%  |  '
              'Pathological ${(onnx.probabilities![2] * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Why the AI predicted $classLabel',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(explanation?.keyFactors.isNotEmpty ?? false
                  ? explanation!.keyFactors
                  : _prediction!.reasons)
              .map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '- ',
                    style: TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (explanation != null) ...[
            const SizedBox(height: 4),
            const Text(
              'Decision summary',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              explanation.decisionSummary,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
          if (_hasShadowMismatch) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Explanation is an approximation of the AI model; prediction is based on the main model.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_explanationError != null) ...[
            const SizedBox(height: 10),
            Text(
              'Explanation unavailable: $_explanationError',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Note: The explanation is generated offline using a simplified interpretable model that approximates the main AI model.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
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
