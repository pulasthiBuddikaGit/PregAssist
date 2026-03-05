import 'dart:convert';

import 'package:flutter/services.dart';

class ShadowDecisionRule {
  final String featureKey;
  final String featureLabel;
  final String unit;
  final double value;
  final double threshold;
  final bool isLessOrEqual;
  final String doctorText;

  const ShadowDecisionRule({
    required this.featureKey,
    required this.featureLabel,
    required this.unit,
    required this.value,
    required this.threshold,
    required this.isLessOrEqual,
    required this.doctorText,
  });

  String get comparisonSymbol => isLessOrEqual ? '<=' : '>';
}

class ShadowExplainabilityResult {
  final int shadowClass; // 0=Normal, 1=Suspect, 2=Pathological
  final int onnxClass; // 1=Normal, 2=Suspect, 3=Pathological
  final List<double> classCounts;
  final List<ShadowDecisionRule> pathRules;
  final List<String> keyFactors;
  final String decisionSummary;

  const ShadowExplainabilityResult({
    required this.shadowClass,
    required this.onnxClass,
    required this.classCounts,
    required this.pathRules,
    required this.keyFactors,
    required this.decisionSummary,
  });
}

class _FeatureDescriptor {
  final String label;
  final String unit;
  final int priority;
  final bool hideInDoctorUi;

  const _FeatureDescriptor({
    required this.label,
    required this.unit,
    required this.priority,
    this.hideInDoctorUi = false,
  });
}

class CtgShadowExplainabilityService {
  CtgShadowExplainabilityService._();
  static final CtgShadowExplainabilityService instance =
      CtgShadowExplainabilityService._();

  static const String _assetPath =
      'assets/explainability/shadow_tree_manual12_depth6_balanced_v2.json';

  static const List<String> _featureByIndex = <String>[
    'baseline value',
    'accelerations',
    'uterine_contractions',
    'light_decelerations',
    'severe_decelerations',
    'prolongued_decelerations',
    'histogram_min',
    'histogram_max',
    'histogram_width',
    'histogram_mean',
    'histogram_mode',
    'histogram_median',
  ];

  static const Map<String, _FeatureDescriptor> _features =
      <String, _FeatureDescriptor>{
    'baseline value': _FeatureDescriptor(
      label: 'Baseline fetal heart rate',
      unit: 'bpm',
      priority: 1,
    ),
    'accelerations': _FeatureDescriptor(
      label: 'Accelerations rate',
      unit: '/sec',
      priority: 1,
    ),
    'uterine_contractions': _FeatureDescriptor(
      label: 'Uterine contractions rate',
      unit: '/sec',
      priority: 1,
    ),
    'light_decelerations': _FeatureDescriptor(
      label: 'Light decelerations rate',
      unit: '/sec',
      priority: 2,
    ),
    'severe_decelerations': _FeatureDescriptor(
      label: 'Severe decelerations rate',
      unit: '/sec',
      priority: 1,
    ),
    'prolongued_decelerations': _FeatureDescriptor(
      label: 'Prolonged decelerations rate',
      unit: '/sec',
      priority: 1,
    ),
    'histogram_min': _FeatureDescriptor(
      label: 'Lowest fetal heart rate',
      unit: 'bpm',
      priority: 3,
    ),
    'histogram_max': _FeatureDescriptor(
      label: 'Highest fetal heart rate',
      unit: 'bpm',
      priority: 3,
    ),
    'histogram_width': _FeatureDescriptor(
      label: 'FHR range / variability',
      unit: 'bpm',
      priority: 2,
    ),
    'histogram_mean': _FeatureDescriptor(
      label: 'Histogram mean',
      unit: 'bpm',
      priority: 9,
      hideInDoctorUi: true,
    ),
    'histogram_mode': _FeatureDescriptor(
      label: 'Histogram mode',
      unit: 'bpm',
      priority: 9,
      hideInDoctorUi: true,
    ),
    'histogram_median': _FeatureDescriptor(
      label: 'Histogram median',
      unit: 'bpm',
      priority: 9,
      hideInDoctorUi: true,
    ),
  };

  Map<String, dynamic>? _root;

  Future<void> init() async {
    if (_root != null) return;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid shadow tree JSON structure.');
    }
    _root = decoded;
  }

  Future<ShadowExplainabilityResult> explain(
    List<double> features12, {
    int maxReasons = 4,
  }) async {
    if (features12.length != 12) {
      throw ArgumentError('Expected 12 features, got ${features12.length}');
    }

    await init();
    Map<String, dynamic> node = _root!;
    final pathRules = <ShadowDecisionRule>[];

    while (node['is_leaf'] != true) {
      final featureIndex = (node['feature_index'] as num?)?.toInt();
      if (featureIndex == null ||
          featureIndex < 0 ||
          featureIndex >= features12.length) {
        throw StateError(
            'Invalid feature index in shadow tree node: $featureIndex');
      }

      final threshold = (node['threshold'] as num?)?.toDouble();
      if (threshold == null) {
        throw StateError('Threshold missing in shadow tree node.');
      }

      final featureKey = _resolveFeatureKey(node, featureIndex);
      final value = features12[featureIndex];
      final isLessOrEqual = value <= threshold;
      final desc = _descriptor(featureKey);

      pathRules.add(
        ShadowDecisionRule(
          featureKey: featureKey,
          featureLabel: desc.label,
          unit: desc.unit,
          value: value,
          threshold: threshold,
          isLessOrEqual: isLessOrEqual,
          doctorText: _doctorReason(
            featureKey: featureKey,
            featureLabel: desc.label,
            unit: desc.unit,
            value: value,
            threshold: threshold,
            isLessOrEqual: isLessOrEqual,
          ),
        ),
      );

      final next = node[isLessOrEqual ? 'left' : 'right'];
      if (next is! Map<String, dynamic>) {
        throw StateError('Invalid child node while traversing shadow tree.');
      }
      node = next;
    }

    final shadowClass = (node['pred_class'] as num?)?.toInt();
    if (shadowClass == null || shadowClass < 0 || shadowClass > 2) {
      throw StateError('Invalid shadow class: $shadowClass');
    }

    final classCounts = _parseClassCounts(node['class_counts']);
    final onnxClass = shadowClass + 1;
    final keyFactors = _pickKeyFactors(pathRules, maxReasons: maxReasons);
    final decisionSummary = _summaryForClass(onnxClass);

    return ShadowExplainabilityResult(
      shadowClass: shadowClass,
      onnxClass: onnxClass,
      classCounts: classCounts,
      pathRules: pathRules,
      keyFactors: keyFactors,
      decisionSummary: decisionSummary,
    );
  }

  String _resolveFeatureKey(Map<String, dynamic> node, int featureIndex) {
    final featureName = node['feature_name'];
    if (featureName is String && featureName.trim().isNotEmpty) {
      return featureName.trim();
    }
    return _featureByIndex[featureIndex];
  }

  _FeatureDescriptor _descriptor(String featureKey) {
    return _features[featureKey] ??
        _FeatureDescriptor(
          label: featureKey,
          unit: '',
          priority: 8,
        );
  }

  List<double> _parseClassCounts(dynamic raw) {
    if (raw is! List) return const <double>[];
    return raw.whereType<num>().map((e) => e.toDouble()).toList();
  }

  List<String> _pickKeyFactors(
    List<ShadowDecisionRule> rules, {
    required int maxReasons,
  }) {
    final sorted = rules.asMap().entries.toList()
      ..sort((a, b) {
        final ap = _descriptor(a.value.featureKey).priority;
        final bp = _descriptor(b.value.featureKey).priority;
        if (ap != bp) return ap.compareTo(bp);
        return a.key.compareTo(b.key);
      });

    final selected = <String>[];
    final usedFeatures = <String>{};

    for (final entry in sorted) {
      final rule = entry.value;
      final desc = _descriptor(rule.featureKey);
      if (desc.hideInDoctorUi) continue;
      if (!usedFeatures.add(rule.featureKey)) continue;

      selected.add(rule.doctorText);
      if (selected.length >= maxReasons) break;
    }

    if (selected.isEmpty) {
      for (final rule in rules.take(maxReasons)) {
        selected.add(rule.doctorText);
      }
    }

    return selected;
  }

  String _doctorReason({
    required String featureKey,
    required String featureLabel,
    required String unit,
    required double value,
    required double threshold,
    required bool isLessOrEqual,
  }) {
    final valueText = _formatWithUnit(value, unit);
    final thresholdText = _formatWithUnit(threshold, unit);

    switch (featureKey) {
      case 'accelerations':
        return isLessOrEqual
            ? 'Accelerations are low ($valueText, threshold <= $thresholdText).'
            : 'Accelerations are present/increased ($valueText, threshold > $thresholdText).';
      case 'uterine_contractions':
        return isLessOrEqual
            ? 'Uterine contractions rate is lower ($valueText, threshold <= $thresholdText).'
            : 'Uterine contractions rate is high ($valueText, threshold > $thresholdText).';
      case 'prolongued_decelerations':
        return isLessOrEqual
            ? 'Prolonged decelerations are limited ($valueText, threshold <= $thresholdText).'
            : 'Prolonged decelerations are present/increased ($valueText, threshold > $thresholdText).';
      case 'severe_decelerations':
        return isLessOrEqual
            ? 'Severe decelerations are limited ($valueText, threshold <= $thresholdText).'
            : 'Severe decelerations are increased ($valueText, threshold > $thresholdText).';
      case 'light_decelerations':
        return isLessOrEqual
            ? 'Light decelerations are lower ($valueText, threshold <= $thresholdText).'
            : 'Light decelerations are increased ($valueText, threshold > $thresholdText).';
      case 'baseline value':
        return isLessOrEqual
            ? 'Baseline fetal heart rate is lower ($valueText, threshold <= $thresholdText).'
            : 'Baseline fetal heart rate is higher ($valueText, threshold > $thresholdText).';
      case 'histogram_width':
        return isLessOrEqual
            ? 'FHR variability range is narrower ($valueText, threshold <= $thresholdText).'
            : 'FHR variability range is wider ($valueText, threshold > $thresholdText).';
      case 'histogram_min':
        return isLessOrEqual
            ? 'Lowest fetal heart rate is lower ($valueText, threshold <= $thresholdText).'
            : 'Lowest fetal heart rate is higher ($valueText, threshold > $thresholdText).';
      case 'histogram_max':
        return isLessOrEqual
            ? 'Highest fetal heart rate is lower ($valueText, threshold <= $thresholdText).'
            : 'Highest fetal heart rate is higher ($valueText, threshold > $thresholdText).';
      default:
        return isLessOrEqual
            ? '$featureLabel is lower ($valueText, threshold <= $thresholdText).'
            : '$featureLabel is higher ($valueText, threshold > $thresholdText).';
    }
  }

  String _formatWithUnit(double value, String unit) {
    final decimals = unit == '/sec' ? 4 : 1;
    final numText = value.toStringAsFixed(decimals);
    if (unit.isEmpty) return numText;
    return '$numText$unit';
  }

  String _summaryForClass(int onnxClass) {
    switch (onnxClass) {
      case 1:
        return 'This pattern is consistent with a reassuring CTG profile.';
      case 2:
        return 'This pattern shows mixed findings and may require closer monitoring.';
      case 3:
        return 'This pattern indicates reduced fetal reactivity and increased deceleration activity, consistent with a higher-risk CTG pattern.';
      default:
        return 'This explanation is based on a simplified offline model.';
    }
  }
}
