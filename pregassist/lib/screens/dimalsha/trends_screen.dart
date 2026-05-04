import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendScreen extends StatelessWidget {
  final Map<String, dynamic> forecast;
  final List<dynamic> history;

  const TrendScreen({
    super.key,
    required this.forecast,
    required this.history,
  });

  Color getTrendColor(String trend) {
    if (trend == "increasing") return Colors.red;
    if (trend == "decreasing") return Colors.green;
    return Colors.orange;
  }

  String getTrendText(String trend) {
    if (trend == "increasing") return "Health risk is increasing over time";
    if (trend == "slightly_increasing") return "Health shows a slight increase over time";
    if (trend == "decreasing") return "Health condition is improving";
    return "No significant change detected";
  }

  IconData getTrendIcon(String trend) {
    if (trend == "increasing") return Icons.trending_up;
    if (trend == "decreasing") return Icons.trending_down;
    return Icons.trending_flat;
  }

  
  List<FlSpot> buildChartData() {
    List<FlSpot> spots = [];

    int start = history.length > 5 ? history.length - 5 : 0;

    for (int i = start; i < history.length; i++) {
      final item = history[i];
      double value = (item["confidence"] ?? 0).toDouble();
      spots.add(FlSpot((i - start).toDouble(), value));
    }

    return spots;
  }

  String _humaniseTrend(String raw) {
    switch (raw.toLowerCase()) {
      case "insufficient_data":
        return "Insufficient Data";
      case "increasing":
        return "Increasing";
      case "slightly_increasing":
        return "Slightly Increasing";
      case "decreasing":
        return "Decreasing";
      case "stable":
        return "Stable";
      default:
        return raw
            .replaceAll("_", " ")
            .split(" ")
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final trend = forecast["trend"] ?? "stable";
    final details = forecast["details"] ?? {};

    // at least 3 records for meaningful trend analysis
    final bool hasEnoughData = history.length >= 3 &&
        trend.toString().toLowerCase() != "insufficient_data";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text("Trends",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 90,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(child: Image.asset('assets/logo.png')),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

            
            if (!hasEnoughData) ...[
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      "Insufficient Data",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "At least 3 health records are needed to generate a meaningful trend analysis.\n\n"
                      "You currently have ${history.length} record${history.length == 1 ? '' : 's'}. "
                      "Complete more health checks to unlock trend insights.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B80FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF2B80FF), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "${3 - history.length} more record${(3 - history.length) == 1 ? '' : 's'} needed",
                            style: const TextStyle(
                              color: Color(0xFF2B80FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 
            if (hasEnoughData) ...[

            // 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: getTrendColor(trend).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(getTrendIcon(trend),
                      size: 40,
                      color: getTrendColor(trend)),

                  const SizedBox(height: 10),

                  Text(
                    _humaniseTrend(trend),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: getTrendColor(trend),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(getTrendText(trend)),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // AI INSIGHT BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trend == "increasing"
                          ? "Your recent readings show an upward trend. Please monitor closely."
                          : trend == "decreasing"
                              ? "Your health indicators are improving. Keep it up!"
                              : "Your health condition remains stable over time.",
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            // CHART TITLE
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Health Trend Over Time",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),

            const SizedBox(height: 5),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Based on your latest records",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            const SizedBox(height: 10),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "X: Time (recent records)   Y: Health Score",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 10),

            // LINE CHART
            SizedBox(
              height: 280,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Day ${value.toInt() + 1}",
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xFF1A0033),
                        tooltipRoundedRadius: 10,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              "Score: ${spot.y.toStringAsFixed(1)}",
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: buildChartData(),
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: const Color(0xFF7C3AED),
                              strokeWidth: 2.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Graph description
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Health Score is calculated using BP, Blood Sugar, Heart Rate, and Body Temperature.",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🔥 LEGEND
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.circle, size: 8, color: Color(0xFF7C3AED)),
                SizedBox(width: 6),
                Text("Health Score Trend Line", style: TextStyle(fontSize: 12)),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getTrendText(trend),
                style: const TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Note: The trend is calculated using overall pattern, not just the last value.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 15),

            // 🔥 PARAMETER DETAILS
            buildTile("Blood Pressure", details["blood_pressure"]),
            buildTile("Blood Sugar", details["blood_sugar"]),
            buildTile("Heart Rate", details["heart_rate"]),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                buildSummary(details),
                style: const TextStyle(fontSize: 13),
              ),
            ),

            ], 
          ],
        ),
      ),
      ),
    );
  }

  String buildSummary(Map details) {
    List<String> msgs = [];

    if (details["blood_pressure"] == "increasing") {
      msgs.add("Blood pressure is rising.");
    }

    if (details["blood_sugar"] == "increasing") {
      msgs.add("Blood sugar is increasing.");
    }

    if (details["heart_rate"] == "increasing") {
      msgs.add("Heart rate is elevated.");
    }

    if (msgs.isEmpty) {
      return "All health indicators are stable.";
    }

    return msgs.join(" ") + " Please monitor closely.";
  }

  Widget buildTile(String title, String? value) {
    Color color;
    IconData icon;

    if (value == "increasing") {
      color = Colors.red;
      icon = Icons.trending_up;
    } else if (value == "decreasing") {
      color = Colors.green;
      icon = Icons.trending_down;
    } else {
      color = Colors.orange;
      icon = Icons.trending_flat;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            (value ?? "-").toUpperCase(),
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