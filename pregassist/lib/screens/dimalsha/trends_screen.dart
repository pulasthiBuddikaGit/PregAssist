import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/vitals_api.dart';

class TrendsScreen extends StatefulWidget {
  final String motherId;
  const TrendsScreen({super.key, required this.motherId});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String period = "weekly";
  bool loading = true;
  String? errorMsg;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final data = await VitalsApi.getHistory(
        motherId: widget.motherId,
        period: period,
      );

      setState(() {
        history = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        loading = false;
      });
    }
  }

  List<FlSpot> buildSpots(String field) {
    final spots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      final value = history[i][field];
      if (value != null && value is num) {
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }

    return spots;
  }

  double getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    double min = spots.first.y;
    for (final spot in spots) {
      if (spot.y < min) min = spot.y;
    }
    return min - 5;
  }

  double getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    double max = spots.first.y;
    for (final spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max + 5;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.toInt().toString(),
      style: const TextStyle(fontSize: 10),
    );
  }

  Widget buildChart(String title, String field) {
    final spots = buildSpots(field);

    if (spots.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Center(child: Text("No data to display")),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: getMinY(spots),
                  maxY: getMaxY(spots),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: ((getMaxY(spots) - getMinY(spots)) / 4).clamp(1, double.infinity),
                        getTitlesWidget: leftTitleWidgets,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: bottomTitleWidgets,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "X-axis: record order   |   Y-axis: measured value",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trends"),
        actions: [
          DropdownButton<String>(
            value: period,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: "weekly", child: Text("Weekly")),
              DropdownMenuItem(value: "monthly", child: Text("Monthly")),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() => period = val);
              loadHistory();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : history.isEmpty
                  ? const Center(child: Text("No history data found"))
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListView(
                        children: [
                          buildChart("Systolic BP", "SystolicBP"),
                          buildChart("Diastolic BP", "DiastolicBP"),
                          buildChart("Blood Sugar (BS)", "BS"),
                          buildChart("Body Temperature", "BodyTemp"),
                          buildChart("Heart Rate", "HeartRate"),
                        ],
                      ),
                    ),
    );
  }
}