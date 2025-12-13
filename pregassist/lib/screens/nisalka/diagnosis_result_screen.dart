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
    // 1. Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    bool isNormal = diagnosis.contains("Normal") || diagnosis.contains("Low Risk");

    if (isNormal) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.warning_amber_rounded;
    }

    // 2. Define the Gradient Colors based on the status
    // We use a light opacity version of the status color for the top, fading to white at bottom.
    Color gradientTop = statusColor.withOpacity(0.25);
    Color gradientBottom = Colors.white;
    // If it's high risk, maybe fade to a very light tint instead of pure white for more drama
    if (!isNormal) {
       gradientBottom = statusColor.withOpacity(0.05);
    }


    // 3. Wrap Scaffold in a Container with BoxDecoration
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientTop, gradientBottom],
          // Optional: Adjust stops to control where the gradient changes
          // stops: const [0.0, 0.7], 
        ),
      ),
      child: Scaffold(
        // 4. IMPORTANT: Make Scaffold and AppBar transparent so gradient shows
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Diagnosis Results"),
          backgroundColor: Colors.transparent,
          elevation: 0, // Remove shadow to make it blend seamlessly
          // Ensure back arrow is visible on lighter backgrounds
          iconTheme: IconThemeData(color: statusColor),
          titleTextStyle: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big Icon
                Icon(statusIcon, size: 100, color: statusColor),
                const SizedBox(height: 20),

                // Diagnosis Title
                const Text(
                  "PREDICTED RISK:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey, // Grey looks okay, or use statusColor.withOpacity(0.7)
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  diagnosis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 40),

                // Reasoning Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // Make the box background slightly whiter than the gradient so it pops out
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
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
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reasoning,
                        style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Back to Home"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor, // Button color matches status
                      foregroundColor: Colors.white, // Text color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}