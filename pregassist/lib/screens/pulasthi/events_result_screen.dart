import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/pulasthi/assessment_data.dart';
import '../../services/ctg_counterfactual_service.dart';
import '../../services/ctg_shadow_explainability_service.dart';
import '../../services/ctg_selective_prediction_service.dart';
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
  CtgSelectivePredictionResult? _selectivePrediction;
  ShadowExplainabilityResult? _shadowExplanation;
  CounterfactualSearchResult? _counterfactual;
  String? _explanationError;
  String? _counterfactualError;
  bool _isLoading = false;
  bool _isCounterfactualLoading = false;
  bool _isExplanationSpeaking = false;
  bool _isCounterfactualSpeaking = false;
  late final FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _accelerations = widget.data.accelerations;
    _contractions = widget.data.contractions;
    _mildDecelerations = widget.data.mildDecelerations;
    _severeDecelerations = widget.data.severeDecelerations;
    _prolongedDecelerations = widget.data.prolongedDecelerations;
    _flutterTts = FlutterTts();
    _flutterTts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _isExplanationSpeaking = false;
        _isCounterfactualSpeaking = false;
      });
    });
    _flutterTts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _isExplanationSpeaking = false;
        _isCounterfactualSpeaking = false;
      });
    });
    _flutterTts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() {
        _isExplanationSpeaking = false;
        _isCounterfactualSpeaking = false;
      });
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
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
      _selectivePrediction = null;
      _shadowExplanation = null;
      _explanationError = null;
      _resetCounterfactualState();
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
      final selectivePrediction =
          CtgSelectivePredictionService.instance.evaluate(onnxPrediction);

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
        _selectivePrediction = selectivePrediction;
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

  // Reset + navigate directly to CTGSegmentScreen
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
    _selectivePrediction = null;
    _shadowExplanation = null;
    _explanationError = null;
    _resetCounterfactualState();

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
                if (_selectivePrediction != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _modeChipBackground(),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_selectiveModeText()}. ${_selectivePrediction!.reason}',
                      style: TextStyle(
                        color: _modeChipTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                        '${widget.data.lowestFHR}-${widget.data.highestFHR} bpm',
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
                  Text(
                    (_selectivePrediction?.isBorderline ?? false) ||
                            (_selectivePrediction?.isReviewNeeded ?? false)
                        ? 'Most likely class explanation: ${_mostLikelyClassText()}'
                        : 'Why the AI predicted this',
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

  void _resetCounterfactualState() {
    _counterfactual = null;
    _counterfactualError = null;
    _isCounterfactualLoading = false;
    _isExplanationSpeaking = false;
    _isCounterfactualSpeaking = false;
    _flutterTts.stop();
  }

  Future<void> _stopSpeech() async {
    await _flutterTts.stop();
    if (!mounted) return;
    setState(() {
      _isExplanationSpeaking = false;
      _isCounterfactualSpeaking = false;
    });
  }

  String _explanationSpeechText() {
    final selective = _selectivePrediction;
    final classLabel = _displayPredictionLabel().replaceAll(' / ', ' or ');
    final reasons = _shadowExplanation?.keyFactors ??
        _prediction?.reasons ??
        const <String>[];
    final cleanedReasons = reasons
        .map(_speechFriendlyReason)
        .where((reason) => reason.trim().isNotEmpty)
        .toList();

    final parts = <String>[
      if (selective?.isReviewNeeded ?? false)
        'The AI recommends clinical review because model uncertainty is high.'
      else
        'The AI predicted $classLabel fetal status.',
      if (selective != null) selective.reason,
      if ((selective?.isBorderline ?? false) ||
          (selective?.isReviewNeeded ?? false))
        'The clinical explanation is for the most likely class, ${_mostLikelyClassText()}.',
      if (cleanedReasons.isNotEmpty) 'Key reasons: ${cleanedReasons.join(' ')}',
      if ((_shadowExplanation?.decisionSummary ?? '').isNotEmpty)
        'Decision summary: ${_shadowExplanation!.decisionSummary}',
    ];

    return parts.join(' ');
  }

  String _speechFriendlyReason(String reason) {
    var cleaned = reason.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    cleaned = cleaned.replaceAll('present/increased', 'high');
    cleaned = cleaned.replaceAll('limited', 'low');
    cleaned = cleaned.replaceAll('lower', 'low');
    cleaned = cleaned.replaceAll('higher', 'high');
    cleaned = cleaned.replaceAll('wider', 'high');
    cleaned = cleaned.replaceAll('narrower', 'low');
    cleaned = cleaned.replaceAll('increased', 'high');
    cleaned = cleaned.replaceAll('present', 'high');
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return '';
    if (!cleaned.endsWith('.')) {
      cleaned = '$cleaned.';
    }
    return cleaned;
  }

  Future<void> _toggleExplanationSpeech() async {
    if (_prediction == null) return;

    try {
      if (_isExplanationSpeaking) {
        await _stopSpeech();
        return;
      }

      final speechText = _explanationSpeechText();
      await _flutterTts.stop();
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isExplanationSpeaking = true;
          _isCounterfactualSpeaking = false;
        });
      }

      await _flutterTts.speak(speechText);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExplanationSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speaker unavailable: $e')),
      );
    }
  }

  Future<void> _prepareCounterfactual() async {
    if (_onnxPrediction == null || widget.data.segmentDuration == null) {
      return;
    }
    if (_selectivePrediction?.isReviewNeeded ?? false) {
      setState(() {
        _counterfactual = null;
        _counterfactualError =
            'Counterfactual suggestions are unavailable when the model marks the result as Review Needed. Please review the CTG clinically first.';
      });
      return;
    }
    if (_counterfactual != null) {
      return;
    }
    if (_isCounterfactualLoading) {
      return;
    }

    setState(() {
      _isCounterfactualLoading = true;
      _counterfactualError = null;
    });

    try {
      final result = await CtgCounterfactualService.instance.search(
        currentFeatures12: _buildFeatures12(),
        currentClass: _onnxPrediction!.label,
        segmentDurationMinutes: widget.data.segmentDuration!,
      );

      if (!mounted) return;

      setState(() {
        _counterfactual = result;
        if (result == null) {
          _counterfactualError = _onnxPrediction!.label == 1
              ? 'This CTG is already in the best class. No step-up counterfactual is needed.'
              : 'No nearby change was found that moves the ONNX model to the next better class.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _counterfactualError = 'Counterfactual search failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isCounterfactualLoading = false);
      }
    }
  }

  Future<void> _toggleCounterfactualSpeech() async {
    final result = _counterfactual;
    if (result == null) return;

    try {
      if (_isCounterfactualSpeaking) {
        await _stopSpeech();
        return;
      }

      await _flutterTts.stop();
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isExplanationSpeaking = false;
          _isCounterfactualSpeaking = true;
        });
      }

      await _flutterTts.speak(result.speechText);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCounterfactualSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speaker unavailable: $e')),
      );
    }
  }

  void _showCounterfactuals() {
    final future = _prepareCounterfactual();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: FutureBuilder<void>(
            future: future,
            builder: (context, snapshot) => SingleChildScrollView(
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
                    'Counterfactuals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This search tests small nearby changes in baseline and event counts, then re-runs the main ONNX model to see whether the class improves.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  if (_selectivePrediction?.isBorderline ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This result is borderline, so counterfactuals are based on the most likely class: ${_mostLikelyClassText()}.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_isCounterfactualLoading && _counterfactual == null) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_counterfactual != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _counterfactual!.summary,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _toggleCounterfactualSpeech,
                                tooltip: _isCounterfactualSpeaking
                                    ? 'Stop audio'
                                    : 'Listen',
                                icon: Icon(
                                  _isCounterfactualSpeaking
                                      ? Icons.stop_circle_outlined
                                      : Icons.volume_up_outlined,
                                  color: const Color(0xFF2B80FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Target class: ${_classLabel(_counterfactual!.currentClass)} -> ${_classLabel(_counterfactual!.targetClass)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Suggested value changes',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._counterfactual!.adjustments.map(
                      (adjustment) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          adjustment.instruction,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Suggested class confidence: ${((_counterfactual!.suggestedPrediction.confidence ?? 0) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _counterfactualError ??
                            'Counterfactual suggestions are unavailable.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(_stopSpeech);
  }

  String _classLabel(int cls) {
    switch (cls) {
      case 1:
        return 'Normal';
      case 2:
        return 'Suspect';
      case 3:
        return 'Pathological';
      default:
        return 'Unknown';
    }
  }

  String _displayPredictionLabel() {
    final selective = _selectivePrediction;
    if (selective == null || selective.isConfident) {
      return _prediction?.label ?? 'Unknown';
    }
    if (selective.isReviewNeeded) {
      return 'Review Needed';
    }
    final secondary = selective.secondaryClass;
    if (secondary == null) return _classLabel(selective.primaryClass);
    return '${_classLabel(selective.primaryClass)} / ${_classLabel(secondary)}';
  }

  String _selectiveModeText() {
    final selective = _selectivePrediction;
    if (selective == null) return 'Mode: Raw ONNX';
    return 'Mode: ${selective.modeLabel}';
  }

  String _mostLikelyClassText() {
    final selective = _selectivePrediction;
    final cls = selective?.primaryClass ?? _onnxPrediction?.label;
    if (cls == null) return 'Unknown';
    return _classLabel(cls);
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  Color _predictionCardBackground() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFFEFF6FF);
    if (selective?.isBorderline ?? false) return const Color(0xFFFFFBEB);
    return _prediction!.backgroundColor;
  }

  Color _predictionCardBorder() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFFBFDBFE);
    if (selective?.isBorderline ?? false) return const Color(0xFFFDE68A);
    return _prediction!.borderColor;
  }

  Color _predictionTextColor() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFF1E40AF);
    if (selective?.isBorderline ?? false) return const Color(0xFFB45309);
    return _prediction!.textColor;
  }

  Color _predictionIconColor() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFF2563EB);
    if (selective?.isBorderline ?? false) return const Color(0xFFD97706);
    return _prediction!.iconColor;
  }

  IconData _predictionIcon() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return Icons.manage_search;
    if (selective?.isBorderline ?? false) return Icons.warning_amber_rounded;
    return _prediction!.icon;
  }

  Color _modeChipBackground() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFFDBEAFE);
    if (selective?.isBorderline ?? false) return const Color(0xFFFEF3C7);
    return const Color(0xFFDCFCE7);
  }

  Color _modeChipTextColor() {
    final selective = _selectivePrediction;
    if (selective?.isReviewNeeded ?? false) return const Color(0xFF1E40AF);
    if (selective?.isBorderline ?? false) return const Color(0xFF92400E);
    return const Color(0xFF166534);
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

  Widget _buildBulletText(String text) {
    return Padding(
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
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                        "Step 3 of 3 - Events & Result",
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
                                  'Count clear accelerations where the fetal heart rate rises by at least 15 bpm for at least 15 seconds.',
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
                                  'Drop less than 30 bpm below baseline and shorter than 60 seconds.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _severeDecelerations,
                              onChanged: (v) =>
                                  setState(() => _severeDecelerations = v),
                              label: 'Number of severe decelerations',
                              helperText: 'Deeper or longer FHR drops.',
                              tooltip:
                                  'Drop of at least 30 bpm below baseline or duration of at least 60 seconds.',
                            ),
                            const SizedBox(height: 16),
                            _buildStepperInput(
                              value: _prolongedDecelerations,
                              onChanged: (v) =>
                                  setState(() => _prolongedDecelerations = v),
                              label: 'Number of prolonged decelerations',
                              helperText:
                                  'Count prolonged decelerations lasting 2 to 3 minutes or longer.',
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
    final selective = _selectivePrediction;
    final classLabel = _mostLikelyClassText();
    final displayLabel = _displayPredictionLabel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _predictionCardBackground(),
        border: Border.all(color: _predictionCardBorder()),
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
              Icon(_predictionIcon(), color: _predictionIconColor(), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _predictionTextColor(),
                  ),
                ),
              ),
              if (selective != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _modeChipBackground(),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selective.modeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _modeChipTextColor(),
                    ),
                  ),
                ),
            ],
          ),
          if (selective != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_selectiveModeText()}  |  Top probability: ${_formatPercent(selective.topProbability)}  |  Margin: ${_formatPercent(selective.margin)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (!selective.isConfident) ...[
              const SizedBox(height: 6),
              Text(
                selective.isReviewNeeded
                    ? 'Reason: ${selective.reason}'
                    : '${selective.reason} Most likely class: ${_classLabel(selective.primaryClass)}.',
                style: TextStyle(
                  fontSize: 13,
                  color: selective.isReviewNeeded
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selective.secondaryClass != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Closest classes: ${_classLabel(selective.primaryClass)} ${_formatPercent(selective.topProbability)} vs ${_classLabel(selective.secondaryClass!)} ${_formatPercent(selective.secondProbability)}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ] else if (onnx?.confidence != null) ...[
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (selective?.isReviewNeeded ?? false)
                      ? 'Why review is needed'
                      : (selective?.isBorderline ?? false)
                          ? 'Why this is borderline'
                          : 'Why the AI predicted $classLabel',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleExplanationSpeech,
                tooltip: _isExplanationSpeaking
                    ? 'Stop audio'
                    : 'Listen to explanation',
                icon: Icon(
                  _isExplanationSpeaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_outlined,
                  color: const Color(0xFF2B80FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selective?.isReviewNeeded ?? false) ...[
            _buildBulletText(selective!.reason),
            _buildBulletText(
              'The closest classes are ${_classLabel(selective.primaryClass)} and ${_classLabel(selective.secondaryClass ?? selective.primaryClass)}.',
            ),
          ] else if (selective?.isBorderline ?? false) ...[
            _buildBulletText(selective!.reason),
            _buildBulletText(
              'The explanation below describes the most likely class: ${_classLabel(selective.primaryClass)}.',
            ),
          ],
          if (((selective?.isBorderline ?? false) ||
                  (selective?.isReviewNeeded ?? false)) &&
              explanation != null) ...[
            const SizedBox(height: 4),
            Text(
              'Most likely class clinical factors: ${_mostLikelyClassText()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
          if (selective?.isReviewNeeded ?? false) ...[
            const SizedBox(height: 10),
            const Text(
              'Counterfactuals are disabled for Review Needed results because the model uncertainty is high.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
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
              TextButton(
                onPressed: (selective?.isReviewNeeded ?? false)
                    ? null
                    : _showCounterfactuals,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2B80FF),
                  disabledForegroundColor: Colors.black38,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Counterfactuals',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
