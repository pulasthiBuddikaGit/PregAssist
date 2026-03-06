import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  final int riskLevel;
  const AlertsScreen({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Alerts")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          color: riskLevel == 2 ? Colors.red[50] : Colors.green[50],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_active, size: 60, color: riskLevel == 2 ? Colors.red : Colors.green),
              Text(riskLevel == 2 ? "Doctor Notified" : "Status: Normal", style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }


}