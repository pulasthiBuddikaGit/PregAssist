import 'dart:math';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

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

  /// Returns class 1/2/3
  Future<int> predictClass(List<double> features12) async {
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
      OrtValue? labelOrt =
          outputs['output_label'] ?? outputs['label'] ?? outputs[session.outputNames.first];

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

      // If label is not 1/2/3, compute from probabilities if available
      if (label != 1 && label != 2 && label != 3) {
        OrtValue? probOrt = outputs['output_probability'] ??
            outputs['probabilities'] ??
            (session.outputNames.length > 1 ? outputs[session.outputNames[1]] : null);

        if (probOrt == null) {
          throw StateError(
            "Label wasn't 1/2/3 and probabilities output not found. Outputs: ${outputs.keys.toList()}",
          );
        }

        final probDyn = await probOrt.asList();
        List<double> probs;

        // probs could be [p1,p2,p3] or [[p1,p2,p3]]
        if (probDyn.isNotEmpty && probDyn.first is List) {
          probs = (probDyn.first as List).cast<num>().map((e) => e.toDouble()).toList();
        } else {
          probs = probDyn.cast<num>().map((e) => e.toDouble()).toList();
        }

        final bestIdx = probs.indexOf(probs.reduce(max));
        label = bestIdx + 1;
      }

      if (label != 1 && label != 2 && label != 3) {
        throw StateError("Unexpected predicted label: $label");
      }

      return label;
    } finally {
      // Dispose outputs
      for (final v in outputs.values) {
        v?.dispose();
      }
    }
  }

  Future<void> dispose() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
    }
  }
}
