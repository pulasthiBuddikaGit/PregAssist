import 'package:flutter/material.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final String diagnosis;
  final String reasoning;

  const DiagnosisResultScreen({
    super.key, 
    required this.diagnosis, 
    required this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on the diagnosis string
    // "Normal" gets Green, everything else (Preeclampsia, Sepsis, etc.) gets Orange/Red
    Color statusColor;
    IconData statusIcon;

    if (diagnosis.contains("Normal") || diagnosis.contains("Low Risk")) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Diagnosis Results")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. BIG ICON
              Icon(statusIcon, size: 100, color: statusColor),
              const SizedBox(height: 20),

              // 2. DIAGNOSIS TITLE
              const Text(
                "PREDICTED RISK:",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 1.2
                ),
              ),
              const SizedBox(height: 8),
              Text(
                diagnosis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.bold,
                  color: statusColor
                ),
              ),
              const SizedBox(height: 40),

              // 3. REASONING BOX
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: statusColor),
                        const SizedBox(width: 8),
                        Text(
                          "Why this result?",
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: statusColor
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reasoning,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // 4. HOME BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text("Back to Home"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    // Navigate back to the very first screen (main wrapper or home)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}