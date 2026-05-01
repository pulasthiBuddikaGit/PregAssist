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
            // 🔴 Alert Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isHighRisk ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    doctorAlert
                        ? Icons.warning_rounded
                        : Icons.check_circle,
                    size: 60,
                    color: doctorAlert ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    doctorAlert
                        ? "Doctor Attention Required"
                        : "No Critical Alerts",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ⚠️ Warnings List
            if (warnings.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: warnings.length,
                  itemBuilder: (context, index) {
                    final w = warnings[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: w["severity"] == "high"
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(w["message"]),
                        subtitle: Text("Severity: ${w["severity"]}"),
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

            // 💡 Recommendation
            Container(
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