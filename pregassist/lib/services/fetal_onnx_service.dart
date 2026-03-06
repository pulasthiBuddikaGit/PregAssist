import 'dart:math';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class OnnxPrediction {
  final int label; // 1=Normal, 2=Suspect, 3=Pathological
  final List<double>? probabilities; // [p(normal), p(suspect), p(pathological)]
  final double? confidence; // probability of selected label

  const OnnxPrediction({
    required this.label,
    this.probabilities,
    this.confidence,
  });
}

class FetalOnnxService {
  FetalOnnxService._();
  static final FetalOnnxService instance = FetalOnnxService._();

  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;

  Future<void> init() async {
    if (_session != null) return;

    _session = await _ort.createSessionFromAsset(
      // Use your current ONNX filename here:
      'assets/models/fetal_model_manual_12c_nozipmap.onnx',
    );

    print('ONNX Inputs: ${_session!.inputNames}');
    print('ONNX Outputs: ${_session!.outputNames}');
  }

  /// Returns class 1/2/3.
  Future<int> predictClass(List<double> features12) async {
    final prediction = await predictDetailed(features12);
    return prediction.label;
  }

  /// Returns class + probabilities (if available) + confidence.
  Future<OnnxPrediction> predictDetailed(List<double> features12) async {
    if (features12.length != 12) {
      throw ArgumentError('Expected 12 features, got ${features12.length}');
    }

    await init();
    final session = _session!;
    final inputName = session.inputNames.first;

    final inputTensor = await OrtValue.fromList(features12, [1, 12]);
    final outputs = await session.run({inputName: inputTensor});
    inputTensor.dispose();

    try {
      // ✅ Your outputs are: [label, probabilities]
      // But older export used: [output_label, output_probability]
      // So we support BOTH.
      OrtValue? labelOrt = outputs['output_label'] ??
          outputs['label'] ??
          outputs[session.outputNames.first];

      if (labelOrt == null) {
        throw StateError(
          "Bad state: label output not found. Outputs: ${outputs.keys.toList()}",
        );
      }

      // label could be [1] or [[1]] or even string
      final labelDyn = await labelOrt.asList();

      int label;
      if (labelDyn.isNotEmpty && labelDyn.first is List) {
        label = (((labelDyn.first as List).first) as num).toInt();
      } else if (labelDyn.isNotEmpty && labelDyn.first is num) {
        label = (labelDyn.first as num).toInt();
      } else {
        label = int.parse(labelDyn.first.toString());
      }

      final probabilities = await _extractProbabilities(session, outputs);

      // If label is not 1/2/3, derive from probabilities (if present).
      if (label != 1 && label != 2 && label != 3) {
        if (probabilities == null || probabilities.isEmpty) {
          throw StateError(
            "Label wasn't 1/2/3 and probabilities output not found. Outputs: ${outputs.keys.toList()}",
          );
        }
        final bestIdx = probabilities.indexOf(probabilities.reduce(max));
        label = bestIdx + 1;
      }

      if (label != 1 && label != 2 && label != 3) {
        throw StateError("Unexpected predicted label: $label");
      }

      double? confidence;
      if (probabilities != null && probabilities.length >= 3) {
        confidence = probabilities[label - 1];
      }

      return OnnxPrediction(
        label: label,
        probabilities: probabilities,
        confidence: confidence,
      );
    } finally {
      // Dispose outputs
      for (final v in outputs.values) {
        v.dispose();
      }
    }
  }

  Future<void> dispose() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
    }
  }

  Future<List<double>?> _extractProbabilities(
    OrtSession session,
    Map<String, OrtValue?> outputs,
  ) async {
    OrtValue? probOrt = outputs['output_probability'] ??
        outputs['probabilities'] ??
        (session.outputNames.length > 1
            ? outputs[session.outputNames[1]]
            : null);

    if (probOrt == null) return null;

    final probDyn = await probOrt.asList();

    // probs could be [p1,p2,p3] or [[p1,p2,p3]]
    if (probDyn.isNotEmpty && probDyn.first is List) {
      return (probDyn.first as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList();
    }

    return probDyn.cast<num>().map((e) => e.toDouble()).toList();
  }
}
