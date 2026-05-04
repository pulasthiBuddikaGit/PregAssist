import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  final String riskLevel;
  final List<Map<String, dynamic>> warnings;
  final bool doctorAlert;
  final String recommendation;

  const AlertsScreen({
    super.key,
    required this.riskLevel,
    required this.warnings,
    required this.doctorAlert,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final isHighRisk = riskLevel.toLowerCase() == "high risk";

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text(
          "Emergency Alerts",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 90,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
            Expanded(
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Alert Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHighRisk
                        ? [Colors.red.shade400, Colors.red.shade800]
                        : (doctorAlert
                            ? [Colors.orange.shade400, Colors.orange.shade800]
                            : [Colors.green.shade400, Colors.green.shade700]),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isHighRisk ? Colors.red : Colors.green)
                          .withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ]),
              child: Column(
                children: [
                  Icon(
                    isHighRisk
                        ? Icons.error_outline
                        : (doctorAlert
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline),
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHighRisk
                        ? "High Risk Detected!"
                        : (doctorAlert
                            ? "Doctor Attention Required"
                            : "No Critical Alerts"),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (isHighRisk) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Notification sent to doctor.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (doctorAlert) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Doctor attention recommended.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Warnings List
            if (warnings.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: warnings.length,
                  itemBuilder: (context, index) {
                    final w = warnings[index];
                    final isHighSeverity = w["severity"] == "high";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: isHighSeverity
                                  ? Colors.red.shade200
                                  : Colors.orange.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isHighSeverity
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: isHighSeverity ? Colors.red : Colors.orange,
                          ),
                        ),
                        title: Text(
                          w["message"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Severity: ${w["severity"].toString().toUpperCase()}",
                          style: TextStyle(
                            color: isHighSeverity
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text(
                "No warnings detected.",
                style: TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 20),

            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Recommendation",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
