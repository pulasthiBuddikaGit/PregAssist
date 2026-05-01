import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AiExplanationScreen extends StatelessWidget {
  final String topFactor;
  final Map<String, double> importance;

  const AiExplanationScreen({Key? key, required this.topFactor, required this.importance})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedEntries = importance.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    final displayEntries = sortedEntries.take(5).toList();
    
    // Calculate total importance for normalization
    final totalImportance = displayEntries.fold(0.0, (sum, entry) => sum + entry.value.abs());

    // Mapping for full names
    String getFullName(String key) {
      switch (key) {
        case 'BS': return 'Blood Sugar';
        case 'SystolicBP': return 'Systolic BP';
        case 'DiastolicBP': return 'Diastolic BP';
        case 'BodyTemp': return 'Body Temperature';
        case 'HeartRate': return 'Heart Rate';
        default: return key;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          "Risk Analysis",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: [Color(0xFFFDEEF4), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Text("Top Contributing Factor", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    SizedBox(height: 5),
                    Text(
                      topFactor,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              Text("Factor Importance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 15),

              Expanded(
                flex: 3, 
                child: RotatedBox(
                  quarterTurns: 1, 
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10, 20, 20, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100, // Normalized to 100%
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: EdgeInsets.all(8),
                            tooltipMargin: 8,
                            // Rotate tooltip back so text isn't sideways
                            rotateAngle: -90, 
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                               String factorName = getFullName(displayEntries[group.x.toInt()].key);
                               return BarTooltipItem(
                                 '$factorName\n',
                                 TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                 children: [TextSpan(text: '${rod.toY.toStringAsFixed(1)}%', style: TextStyle(color: Colors.yellowAccent))],
                               );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 100, // Increased from 40 to 100 to fit long names
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() >= 0 && value.toInt() < displayEntries.length) {
                                   String key = displayEntries[value.toInt()].key;
                                   // Rotate text -90 so it reads horizontally in the vertical graph
                                   return RotatedBox(
                                     quarterTurns: 3,
                                     child: Text(
                                       getFullName(key),
                                       style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                     ),
                                   );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Hide values on axis to save space, we have the list below
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: displayEntries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final val = entry.value.value;
                          final percentage = (val.abs() / totalImportance) * 100;
                          
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: percentage,
                                gradient: LinearGradient(
                                  colors: val > 0 
                                    ? [Colors.redAccent, Colors.orangeAccent] 
                                    : [Colors.green, Colors.tealAccent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 20,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 10),
              
              Expanded(
                flex: 2, 
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text("Detailed Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 10),
                    
                    // Percentage List
                    ...displayEntries.map((entry) {
                      final val = entry.value;
                      final percent = (val.abs() / totalImportance) * 100;
                      final name = getFullName(entry.key);
                      final isRisk = entry.value > 0;
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4, height: 40,
                              decoration: BoxDecoration(
                                color: isRisk ? Colors.orangeAccent : Colors.greenAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent / 100, 
                                      backgroundColor: Colors.grey[100],
                                      valueColor: AlwaysStoppedAnimation(isRisk ? Colors.redAccent : Colors.green),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "${percent.toStringAsFixed(1)}%",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isRisk ? Colors.red : Colors.green),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    SizedBox(height: 10),
                    Center(child: Text("Red = Risk Contributor | Green = Protective Factor", style: TextStyle(color: Colors.grey[600], fontSize: 12))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
