import 'fetal_onnx_service.dart';

enum SelectivePredictionMode {
  confident,
  borderline,
  reviewNeeded,
}

class CtgSelectivePredictionResult {
  final SelectivePredictionMode mode;
  final int primaryClass;
  final int? secondaryClass;
  final double topProbability;
  final double secondProbability;
  final double margin;
  final String reason;

  const CtgSelectivePredictionResult({
    required this.mode,
    required this.primaryClass,
    required this.secondaryClass,
    required this.topProbability,
    required this.secondProbability,
    required this.margin,
    required this.reason,
  });

  bool get isConfident => mode == SelectivePredictionMode.confident;
  bool get isBorderline => mode == SelectivePredictionMode.borderline;
  bool get isReviewNeeded => mode == SelectivePredictionMode.reviewNeeded;

  String get modeLabel {
    switch (mode) {
      case SelectivePredictionMode.confident:
        return 'Confident';
      case SelectivePredictionMode.borderline:
        return 'Borderline';
      case SelectivePredictionMode.reviewNeeded:
        return 'Review Needed';
    }
  }
}

class CtgSelectivePredictionService {
  CtgSelectivePredictionService._();
  static final CtgSelectivePredictionService instance =
      CtgSelectivePredictionService._();

  static const double confidentProbabilityThreshold = 0.75;
  static const double confidentMarginThreshold = 0.25;
  static const double minimumReviewProbabilityThreshold = 0.50;
  static const double minimumReviewMarginThreshold = 0.10;
  static const double borderlineMarginThreshold = 0.25;

  CtgSelectivePredictionResult evaluate(OnnxPrediction prediction) {
    final probabilities = prediction.probabilities;
    if (probabilities == null || probabilities.length < 3) {
      return CtgSelectivePredictionResult(
        mode: SelectivePredictionMode.confident,
        primaryClass: prediction.label,
        secondaryClass: null,
        topProbability: prediction.confidence ?? 0,
        secondProbability: 0,
        margin: prediction.confidence ?? 0,
        reason:
            'Probability details were unavailable, so the raw ONNX class is shown.',
      );
    }

    final ranked = <_ClassProbability>[
      _ClassProbability(1, probabilities[0]),
      _ClassProbability(2, probabilities[1]),
      _ClassProbability(3, probabilities[2]),
    ]..sort((a, b) => b.probability.compareTo(a.probability));

    final top = ranked[0];
    final second = ranked[1];
    final margin = top.probability - second.probability;

    if (top.probability < minimumReviewProbabilityThreshold ||
        margin < minimumReviewMarginThreshold) {
      return CtgSelectivePredictionResult(
        mode: SelectivePredictionMode.reviewNeeded,
        primaryClass: top.classId,
        secondaryClass: second.classId,
        topProbability: top.probability,
        secondProbability: second.probability,
        margin: margin,
        reason:
            'Model uncertainty is high because the strongest probability or class separation is low.',
      );
    }

    if (top.probability >= confidentProbabilityThreshold &&
        margin >= confidentMarginThreshold) {
      return CtgSelectivePredictionResult(
        mode: SelectivePredictionMode.confident,
        primaryClass: top.classId,
        secondaryClass: null,
        topProbability: top.probability,
        secondProbability: second.probability,
        margin: margin,
        reason:
            'The top class probability is high and clearly separated from the next class.',
      );
    }

    if (margin < borderlineMarginThreshold) {
      return CtgSelectivePredictionResult(
        mode: SelectivePredictionMode.borderline,
        primaryClass: top.classId,
        secondaryClass: second.classId,
        topProbability: top.probability,
        secondProbability: second.probability,
        margin: margin,
        reason:
            'The top two class probabilities are close, so this result should be treated as borderline.',
      );
    }

    return CtgSelectivePredictionResult(
      mode: SelectivePredictionMode.confident,
      primaryClass: top.classId,
      secondaryClass: null,
      topProbability: top.probability,
      secondProbability: second.probability,
      margin: margin,
      reason:
          'The top class is sufficiently separated from the next most likely class.',
    );
  }
}

class _ClassProbability {
  final int classId;
  final double probability;

  const _ClassProbability(this.classId, this.probability);
}
