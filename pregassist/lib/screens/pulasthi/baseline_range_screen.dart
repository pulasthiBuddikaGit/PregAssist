import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/pulasthi/assessment_data.dart';
import 'events_result_screen.dart';

class BaselineRangeScreen extends StatefulWidget {
  final AssessmentData data;

  const BaselineRangeScreen({super.key, required this.data});

  @override
  State<BaselineRangeScreen> createState() => _BaselineRangeScreenState();
}

class _BaselineRangeScreenState extends State<BaselineRangeScreen> {
  final TextEditingController _baselineController = TextEditingController();
  final TextEditingController _lowestController = TextEditingController();
  final TextEditingController _highestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data.baselineFHR != null) {
      _baselineController.text = widget.data.baselineFHR.toString();
    }
    if (widget.data.lowestFHR != null) {
      _lowestController.text = widget.data.lowestFHR.toString();
    }
    if (widget.data.highestFHR != null) {
      _highestController.text = widget.data.highestFHR.toString();
    }
  }

  @override
  void dispose() {
    _baselineController.dispose();
    _lowestController.dispose();
    _highestController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final baseline = int.tryParse(_baselineController.text);
    final lowest = int.tryParse(_lowestController.text);
    final highest = int.tryParse(_highestController.text);

    if (baseline == null || lowest == null || highest == null) return false;
    if (baseline < 50 || baseline > 200) return false;
    if (lowest < 50 || lowest > 200) return false;
    if (highest < 50 || highest > 200) return false;
    if (lowest >= baseline || highest <= baseline) return false;

    return true;
  }

  String? _getErrorMessage() {
    final baseline = int.tryParse(_baselineController.text);
    final lowest = int.tryParse(_lowestController.text);
    final highest = int.tryParse(_highestController.text);

    if (baseline == null || lowest == null || highest == null) return null;

    if (lowest >= baseline) return 'Lowest FHR must be less than baseline';
    if (highest <= baseline) return 'Highest FHR must be greater than baseline';

    return null;
  }

  void _handleNext() {
    if (!_isValid) return;

    widget.data.baselineFHR = int.parse(_baselineController.text);
    widget.data.lowestFHR = int.parse(_lowestController.text);
    widget.data.highestFHR = int.parse(_highestController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventsResultScreen(data: widget.data),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2B80FF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _getErrorMessage();

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

          // ✅ Removed back button from header. Keep only logo like other screens.
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
                constraints: const BoxConstraints(maxWidth: 560),
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
                        "Step 2 of 3 – Baseline & Range",
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
                          value: 2 / 3,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF2B80FF)),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        "Baseline and Range",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Enter baseline, lowest, and highest fetal heart rates (50–200 bpm).",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _baselineController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          label: "Baseline FHR (bpm)",
                          hint: "e.g. 140",
                          icon: Icons.favorite,
                          suffix: Tooltip(
                            message:
                                "Average heart rate over 5–10 minutes (excluding accelerations/decelerations).",
                            child: const Icon(Icons.info_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _lowestController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          label: "Lowest FHR (bpm)",
                          hint: "e.g. 110",
                          icon: Icons.trending_down,
                          suffix: Tooltip(
                            message:
                                "Minimum FHR observed in this segment (excluding brief decelerations).",
                            child: const Icon(Icons.info_outline, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _highestController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                          label: "Highest FHR (bpm)",
                          hint: "e.g. 165",
                          icon: Icons.trending_up,
                          suffix: Tooltip(
                            message:
                                "Maximum FHR observed in this segment (excluding brief accelerations).",
                            child: const Icon(Icons.info_outline, size: 18),
                          ),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            border: Border.all(color: const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

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
                                "Back",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isValid ? _handleNext : null,
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
                                "Next: Events",
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
}
