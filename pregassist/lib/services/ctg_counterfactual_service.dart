import 'dart:math';

import 'fetal_onnx_service.dart';

class CounterfactualAdjustment {
  final String featureKey;
  final String label;
  final String summaryPhrase;
  final String instruction;
  final int? fromCount;
  final int? toCount;
  final int? fromBpm;
  final int? toBpm;

  const CounterfactualAdjustment({
    required this.featureKey,
    required this.label,
    required this.summaryPhrase,
    required this.instruction,
    this.fromCount,
    this.toCount,
    this.fromBpm,
    this.toBpm,
  });
}

class CounterfactualSearchResult {
  final int currentClass;
  final int targetClass;
  final String summary;
  final String speechText;
  final List<CounterfactualAdjustment> adjustments;
  final List<double> suggestedFeatures12;
  final OnnxPrediction suggestedPrediction;

  const CounterfactualSearchResult({
    required this.currentClass,
    required this.targetClass,
    required this.summary,
    required this.speechText,
    required this.adjustments,
    required this.suggestedFeatures12,
    required this.suggestedPrediction,
  });
}

class CtgCounterfactualService {
  CtgCounterfactualService._();
  static final CtgCounterfactualService instance = CtgCounterfactualService._();

  static const List<String> _pathologicalOrder = <String>[
    'prolongued_decelerations',
    'severe_decelerations',
    'accelerations',
    'light_decelerations',
    'uterine_contractions',
    'baseline value',
  ];

  static const List<String> _suspectOrder = <String>[
    'accelerations',
    'light_decelerations',
    'uterine_contractions',
    'prolongued_decelerations',
    'severe_decelerations',
    'baseline value',
  ];

  Future<CounterfactualSearchResult?> search({
    required List<double> currentFeatures12,
    required int currentClass,
    required int segmentDurationMinutes,
  }) async {
    if (currentFeatures12.length != 12) {
      throw ArgumentError(
        'Expected 12 features, got ${currentFeatures12.length}',
      );
    }

    final targetClass = _targetClassFor(currentClass);
    if (targetClass == null) return null;

    final durationSeconds = segmentDurationMinutes * 60.0;
    final currentState = _SearchState.fromFeatures(
      currentFeatures12,
      durationSeconds: durationSeconds,
    );
    final orderedKeys = _orderedKeysFor(currentClass);
    _Candidate? best;

    for (final key in orderedKeys) {
      for (final value in _candidateValuesFor(
        key,
        currentState,
        isPairSearch: false,
      )) {
        final nextState = currentState.withFeature(key, value);
        final candidate = await _evaluateCandidate(
          baseState: currentState,
          nextState: nextState,
          changedKeys: <String>[key],
          targetClass: targetClass,
          featureOrder: orderedKeys,
          durationSeconds: durationSeconds,
        );
        best = _chooseBetter(best, candidate);
      }
    }

    if (best != null) {
      return _buildResult(
        candidate: best,
        currentState: currentState,
        currentClass: currentClass,
        targetClass: targetClass,
        segmentDurationMinutes: segmentDurationMinutes,
      );
    }

    for (var i = 0; i < orderedKeys.length; i++) {
      for (var j = i + 1; j < orderedKeys.length; j++) {
        final firstKey = orderedKeys[i];
        final secondKey = orderedKeys[j];
        final firstValues = _candidateValuesFor(
          firstKey,
          currentState,
          isPairSearch: true,
        );
        final secondValues = _candidateValuesFor(
          secondKey,
          currentState,
          isPairSearch: true,
        );

        for (final firstValue in firstValues) {
          for (final secondValue in secondValues) {
            final nextState = currentState
                .withFeature(firstKey, firstValue)
                .withFeature(secondKey, secondValue);
            final candidate = await _evaluateCandidate(
              baseState: currentState,
              nextState: nextState,
              changedKeys: <String>[firstKey, secondKey],
              targetClass: targetClass,
              featureOrder: orderedKeys,
              durationSeconds: durationSeconds,
            );
            best = _chooseBetter(best, candidate);
          }
        }
      }
    }

    if (best == null) return null;

    return _buildResult(
      candidate: best,
      currentState: currentState,
      currentClass: currentClass,
      targetClass: targetClass,
      segmentDurationMinutes: segmentDurationMinutes,
    );
  }

  int? _targetClassFor(int currentClass) {
    switch (currentClass) {
      case 3:
        return 2;
      case 2:
        return 1;
      default:
        return null;
    }
  }

  List<String> _orderedKeysFor(int currentClass) {
    if (currentClass == 3) return _pathologicalOrder;
    return _suspectOrder;
  }

  List<int> _candidateValuesFor(
    String key,
    _SearchState state, {
    required bool isPairSearch,
  }) {
    final limit = isPairSearch ? 4 : 7;
    switch (key) {
      case 'accelerations':
        return _increasingCounts(state.accelerations, limit);
      case 'uterine_contractions':
        return _decreasingCounts(state.uterineContractions, limit);
      case 'light_decelerations':
        return _decreasingCounts(state.lightDecelerations, limit);
      case 'severe_decelerations':
        return _decreasingCounts(state.severeDecelerations, limit);
      case 'prolongued_decelerations':
        return _decreasingCounts(state.prolongedDecelerations, limit);
      case 'baseline value':
        return _baselineCandidates(state.baseline, state.lowest, state.highest);
      default:
        return const <int>[];
    }
  }

  List<int> _increasingCounts(int current, int limit) {
    final values = <int>[];
    for (var delta = 1; delta <= limit; delta++) {
      values.add(current + delta);
    }
    return values;
  }

  List<int> _decreasingCounts(int current, int limit) {
    final values = <int>[];
    for (var delta = 1; delta <= limit; delta++) {
      final next = current - delta;
      if (next >= 0) values.add(next);
    }
    if (current > 0 && !values.contains(0)) {
      values.add(0);
    }
    return values;
  }

  List<int> _baselineCandidates(int baseline, int lowest, int highest) {
    final minBaseline = max(50, lowest + 1);
    final maxBaseline = min(200, highest - 1);
    if (minBaseline > maxBaseline) return const <int>[];

    final target = baseline < 120
        ? 120
        : baseline > 160
            ? 150
            : 140;

    final values = <int>[];
    for (var delta = 1; delta <= 20; delta++) {
      final lower = baseline - delta;
      final higher = baseline + delta;

      if (baseline > target && lower >= minBaseline) {
        values.add(lower);
      }
      if (baseline < target && higher <= maxBaseline) {
        values.add(higher);
      }
    }

    if (baseline != target && target >= minBaseline && target <= maxBaseline) {
      values.add(target);
    }

    return values.toSet().toList();
  }

  Future<_Candidate?> _evaluateCandidate({
    required _SearchState baseState,
    required _SearchState nextState,
    required List<String> changedKeys,
    required int targetClass,
    required List<String> featureOrder,
    required double durationSeconds,
  }) async {
    if (baseState == nextState) return null;

    final nextFeatures = nextState.toFeatures(durationSeconds: durationSeconds);
    final prediction = await FetalOnnxService.instance.predictDetailed(
      nextFeatures,
    );
    if (prediction.label != targetClass) return null;

    return _Candidate(
      state: nextState,
      changedKeys: changedKeys,
      prediction: prediction,
      score: _scoreCandidate(baseState, nextState, changedKeys, featureOrder),
    );
  }

  double _scoreCandidate(
    _SearchState baseState,
    _SearchState nextState,
    List<String> changedKeys,
    List<String> featureOrder,
  ) {
    var magnitude = 0.0;
    for (final key in changedKeys) {
      final from = baseState.valueFor(key);
      final to = nextState.valueFor(key);
      final diff = (to - from).abs();
      if (key == 'baseline value') {
        magnitude += diff / 5.0;
      } else {
        magnitude += diff.toDouble();
      }
    }

    var orderPenalty = 0.0;
    for (final key in changedKeys) {
      final index = featureOrder.indexOf(key);
      if (index >= 0) {
        orderPenalty += index / 10.0;
      }
    }

    return (changedKeys.length * 1000) + magnitude + orderPenalty;
  }

  _Candidate? _chooseBetter(_Candidate? current, _Candidate? candidate) {
    if (candidate == null) return current;
    if (current == null) return candidate;
    return candidate.score < current.score ? candidate : current;
  }

  CounterfactualSearchResult _buildResult({
    required _Candidate candidate,
    required _SearchState currentState,
    required int currentClass,
    required int targetClass,
    required int segmentDurationMinutes,
  }) {
    final adjustments = candidate.changedKeys
        .map(
          (key) => _buildAdjustment(
            key: key,
            currentState: currentState,
            nextState: candidate.state,
            segmentDurationMinutes: segmentDurationMinutes,
          ),
        )
        .toList();

    final summary = _buildSummary(
      currentClass: currentClass,
      targetClass: targetClass,
      adjustments: adjustments,
    );
    final detailText = adjustments.map((item) => item.instruction).join(' ');

    return CounterfactualSearchResult(
      currentClass: currentClass,
      targetClass: targetClass,
      summary: summary,
      speechText: '$summary $detailText',
      adjustments: adjustments,
      suggestedFeatures12: candidate.state.toFeatures(
        durationSeconds: segmentDurationMinutes * 60.0,
      ),
      suggestedPrediction: candidate.prediction,
    );
  }

  CounterfactualAdjustment _buildAdjustment({
    required String key,
    required _SearchState currentState,
    required _SearchState nextState,
    required int segmentDurationMinutes,
  }) {
    final from = currentState.valueFor(key);
    final to = nextState.valueFor(key);

    switch (key) {
      case 'accelerations':
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Accelerations',
          summaryPhrase: 'accelerations were slightly higher',
          instruction:
              'Increase accelerations from $from to $to counts in this '
              '$segmentDurationMinutes-minute segment.',
          fromCount: from,
          toCount: to,
        );
      case 'uterine_contractions':
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Uterine contractions',
          summaryPhrase: 'uterine contractions were lower',
          instruction:
              'Reduce uterine contractions from $from to $to counts in this '
              '$segmentDurationMinutes-minute segment.',
          fromCount: from,
          toCount: to,
        );
      case 'light_decelerations':
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Light decelerations',
          summaryPhrase: 'light decelerations were lower',
          instruction:
              'Reduce light decelerations from $from to $to counts in this '
              '$segmentDurationMinutes-minute segment.',
          fromCount: from,
          toCount: to,
        );
      case 'severe_decelerations':
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Severe decelerations',
          summaryPhrase: 'severe decelerations were lower',
          instruction:
              'Reduce severe decelerations from $from to $to counts in this '
              '$segmentDurationMinutes-minute segment.',
          fromCount: from,
          toCount: to,
        );
      case 'prolongued_decelerations':
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Prolonged decelerations',
          summaryPhrase: 'prolonged decelerations were lower',
          instruction:
              'Reduce prolonged decelerations from $from to $to counts in this '
              '$segmentDurationMinutes-minute segment.',
          fromCount: from,
          toCount: to,
        );
      case 'baseline value':
        final direction = to > from ? 'Increase' : 'Reduce';
        return CounterfactualAdjustment(
          featureKey: key,
          label: 'Baseline FHR',
          summaryPhrase: 'baseline FHR moved closer to the reassuring range',
          instruction: '$direction baseline FHR from $from bpm to $to bpm.',
          fromBpm: from,
          toBpm: to,
        );
      default:
        return CounterfactualAdjustment(
          featureKey: key,
          label: key,
          summaryPhrase: '$key changed',
          instruction: '$key changed from $from to $to.',
        );
    }
  }

  String _buildSummary({
    required int currentClass,
    required int targetClass,
    required List<CounterfactualAdjustment> adjustments,
  }) {
    final phrases = adjustments.map((item) => item.summaryPhrase).toList();
    final conditionText = _joinPhrases(phrases);
    return 'If $conditionText, the AI classification could change from '
        '${_classLabel(currentClass)} to ${_classLabel(targetClass)}.';
  }

  String _joinPhrases(List<String> phrases) {
    if (phrases.isEmpty) return 'some nearby values changed';
    if (phrases.length == 1) return phrases.first;
    if (phrases.length == 2) return '${phrases[0]} and ${phrases[1]}';

    final lead = phrases.sublist(0, phrases.length - 1).join(', ');
    return '$lead, and ${phrases.last}';
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
}

class _Candidate {
  final _SearchState state;
  final List<String> changedKeys;
  final OnnxPrediction prediction;
  final double score;

  const _Candidate({
    required this.state,
    required this.changedKeys,
    required this.prediction,
    required this.score,
  });
}

class _SearchState {
  final int baseline;
  final int lowest;
  final int highest;
  final int accelerations;
  final int uterineContractions;
  final int lightDecelerations;
  final int severeDecelerations;
  final int prolongedDecelerations;

  const _SearchState({
    required this.baseline,
    required this.lowest,
    required this.highest,
    required this.accelerations,
    required this.uterineContractions,
    required this.lightDecelerations,
    required this.severeDecelerations,
    required this.prolongedDecelerations,
  });

  factory _SearchState.fromFeatures(
    List<double> features12, {
    required double durationSeconds,
  }) {
    return _SearchState(
      baseline: features12[0].round(),
      lowest: features12[6].round(),
      highest: features12[7].round(),
      accelerations: (features12[1] * durationSeconds).round(),
      uterineContractions: (features12[2] * durationSeconds).round(),
      lightDecelerations: (features12[3] * durationSeconds).round(),
      severeDecelerations: (features12[4] * durationSeconds).round(),
      prolongedDecelerations: (features12[5] * durationSeconds).round(),
    );
  }

  _SearchState withFeature(String key, int value) {
    switch (key) {
      case 'baseline value':
        return _SearchState(
          baseline: value,
          lowest: lowest,
          highest: highest,
          accelerations: accelerations,
          uterineContractions: uterineContractions,
          lightDecelerations: lightDecelerations,
          severeDecelerations: severeDecelerations,
          prolongedDecelerations: prolongedDecelerations,
        );
      case 'accelerations':
        return _SearchState(
          baseline: baseline,
          lowest: lowest,
          highest: highest,
          accelerations: value,
          uterineContractions: uterineContractions,
          lightDecelerations: lightDecelerations,
          severeDecelerations: severeDecelerations,
          prolongedDecelerations: prolongedDecelerations,
        );
      case 'uterine_contractions':
        return _SearchState(
          baseline: baseline,
          lowest: lowest,
          highest: highest,
          accelerations: accelerations,
          uterineContractions: value,
          lightDecelerations: lightDecelerations,
          severeDecelerations: severeDecelerations,
          prolongedDecelerations: prolongedDecelerations,
        );
      case 'light_decelerations':
        return _SearchState(
          baseline: baseline,
          lowest: lowest,
          highest: highest,
          accelerations: accelerations,
          uterineContractions: uterineContractions,
          lightDecelerations: value,
          severeDecelerations: severeDecelerations,
          prolongedDecelerations: prolongedDecelerations,
        );
      case 'severe_decelerations':
        return _SearchState(
          baseline: baseline,
          lowest: lowest,
          highest: highest,
          accelerations: accelerations,
          uterineContractions: uterineContractions,
          lightDecelerations: lightDecelerations,
          severeDecelerations: value,
          prolongedDecelerations: prolongedDecelerations,
        );
      case 'prolongued_decelerations':
        return _SearchState(
          baseline: baseline,
          lowest: lowest,
          highest: highest,
          accelerations: accelerations,
          uterineContractions: uterineContractions,
          lightDecelerations: lightDecelerations,
          severeDecelerations: severeDecelerations,
          prolongedDecelerations: value,
        );
      default:
        return this;
    }
  }

  int valueFor(String key) {
    switch (key) {
      case 'baseline value':
        return baseline;
      case 'accelerations':
        return accelerations;
      case 'uterine_contractions':
        return uterineContractions;
      case 'light_decelerations':
        return lightDecelerations;
      case 'severe_decelerations':
        return severeDecelerations;
      case 'prolongued_decelerations':
        return prolongedDecelerations;
      default:
        return 0;
    }
  }

  List<double> toFeatures({required double durationSeconds}) {
    final width = (highest - lowest).toDouble();
    final baselineValue = baseline.toDouble();

    return <double>[
      baselineValue,
      accelerations / durationSeconds,
      uterineContractions / durationSeconds,
      lightDecelerations / durationSeconds,
      severeDecelerations / durationSeconds,
      prolongedDecelerations / durationSeconds,
      lowest.toDouble(),
      highest.toDouble(),
      width,
      baselineValue,
      baselineValue,
      baselineValue,
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SearchState &&
        other.baseline == baseline &&
        other.lowest == lowest &&
        other.highest == highest &&
        other.accelerations == accelerations &&
        other.uterineContractions == uterineContractions &&
        other.lightDecelerations == lightDecelerations &&
        other.severeDecelerations == severeDecelerations &&
        other.prolongedDecelerations == prolongedDecelerations;
  }

  @override
  int get hashCode => Object.hash(
        baseline,
        lowest,
        highest,
        accelerations,
        uterineContractions,
        lightDecelerations,
        severeDecelerations,
        prolongedDecelerations,
      );
}
