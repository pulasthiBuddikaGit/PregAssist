import 'package:flutter/material.dart';

class ForecastScreen extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const ForecastScreen({super.key, required this.forecast});

  Color getTrendColor(String trend) {
    if (trend == "increasing") return Colors.red;
    if (trend == "slightly_increasing") return Colors.orange;
    return Colors.green;
  }

  String fixSeverity(String trend, String severity) {
    if (trend == "increasing") return "high";
    if (trend == "slightly_increasing") return "medium";
    return "low";
  }

  @override
  Widget build(BuildContext context) {
    final details = forecast['details'] ?? {};
    final trend = forecast['trend'] ?? "stable";
    final message = forecast['message'] ?? "";
    final severity = fixSeverity(trend, forecast['severity'] ?? "low");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FF),

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
          "Forecast Analysis",
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 TREND CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getTrendColor(trend).withOpacity(0.2),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [

                  const Text(
                    "Overall Trend",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    trend.replaceAll("_", " ").toUpperCase(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: getTrendColor(trend),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: getTrendColor(trend),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 MESSAGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 PARAMETER CARDS
            buildTile("Blood Pressure", details['blood_pressure'], Icons.favorite),
            buildTile("Blood Sugar", details['blood_sugar'], Icons.water_drop),
            buildTile("Heart Rate", details['heart_rate'], Icons.monitor_heart),

          ],
        ),
      ),
    );
  }

  Widget buildTile(String title, String? value, IconData icon) {
    Color color;

    if (value == "increasing") {
      color = Colors.red;
    } else if (value == "stable") {
      color = Colors.green;
    } else {
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15)),
                const Text(
                  "Trend indicator",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            (value ?? "-").replaceAll("_", " ").toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}