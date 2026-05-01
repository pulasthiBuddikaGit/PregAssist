import 'package:flutter/material.dart';

class ForecastScreen extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastScreen({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {

    final details = forecast['details'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Forecast Analysis")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 OVERALL TREND
            Card(
              child: ListTile(
                title: Text("Overall Trend"),
                subtitle: Text(forecast['trend']),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 MESSAGE
            Text(forecast['message'] ?? ""),

            const SizedBox(height: 20),

            // 🔥 PARAMETER DETAILS
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Blood Pressure"),
                    trailing: Text(details['blood_pressure'] ?? "-"),
                  ),
                  ListTile(
                    title: Text("Blood Sugar"),
                    trailing: Text(details['blood_sugar'] ?? "-"),
                  ),
                  ListTile(
                    title: Text("Heart Rate"),
                    trailing: Text(details['heart_rate'] ?? "-"),
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