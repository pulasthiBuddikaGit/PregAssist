import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/pulasthi/assessment_data.dart';
import 'baseline_range_screen.dart';

class CTGSegmentScreen extends StatefulWidget {
  final AssessmentData? data;

  const CTGSegmentScreen({super.key, this.data});

  @override
  State<CTGSegmentScreen> createState() => _CTGSegmentScreenState();
}

class _CTGSegmentScreenState extends State<CTGSegmentScreen> {
  final TextEditingController _durationController = TextEditingController();

  late AssessmentData _data;

  @override
  void initState() {
    super.initState();

    // Use shared instance if provided (so data stays consistent across steps)
    _data = widget.data ?? AssessmentData();

    if (_data.segmentDuration != null) {
      _durationController.text = _data.segmentDuration.toString();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final duration = int.tryParse(_durationController.text);
    return duration != null && duration >= 1 && duration <= 120;
  }

  void _handleChipClick(int value) {
    setState(() {
      _durationController.text = value.toString();
      _data.segmentDuration = value;
    });
  }

  void _handleNext() {
    if (!_isValid) return;

    _data.segmentDuration = int.parse(_durationController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BaselineRangeScreen(data: _data),
      ),
    );
  }

  void _goBackToDoctorPanel() {
    Navigator.pushNamedAndRemoveUntil(context, '/app/doctor', (route) => false);
  }

  InputDecoration _inputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
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
    return Container(
      // Same background gradient as other screens
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

          // Back button + Logo like your other screens
          leadingWidth: 110,
          leading: Row(
            children: [
              const SizedBox(width: 4),
              IconButton(
                onPressed: _goBackToDoctorPanel,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
            ],
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
                        "Step 1 of 3 – CTG Segment",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Simple progress indicator (responsive)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 1 / 3,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF2B80FF)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        "CTG Segment Duration",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Enter segment duration in minutes (1–120). Recommended: 10–30 minutes.",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {
                            _data.segmentDuration = int.tryParse(value);
                          });
                        },
                        decoration: _inputDecoration(
                          label: "Segment duration (minutes)",
                          icon: Icons.timer,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [10, 20, 30].map((value) {
                          final isSelected = _durationController.text == value.toString();
                          return ChoiceChip(
                            label: Text("$value min"),
                            selected: isSelected,
                            onSelected: (_) => _handleChipClick(value),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF374151),
                            ),
                            selectedColor: const Color(0xFF2B80FF),
                            backgroundColor: Colors.white.withOpacity(0.9),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF2B80FF) : const Color(0xFFD1D5DB),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      if (!_isValid && _durationController.text.isNotEmpty)
                        const Text(
                          "Please enter a valid duration between 1 and 120.",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),

                      const SizedBox(height: 18),

                      SizedBox(
                        height: 52,
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
                            elevation: 0,
                          ),
                          child: const Text(
                            "Next: Baseline & Range",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
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
