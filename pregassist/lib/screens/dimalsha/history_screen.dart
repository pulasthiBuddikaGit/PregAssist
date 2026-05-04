import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/pdf_generator.dart';
import 'maternal_model.dart';

class HistoryScreen extends StatefulWidget {
  final String motherId;

  const HistoryScreen({super.key, required this.motherId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse("${MaternalService.baseUrl}/history/${widget.motherId}"),
      );

      if (response.statusCode == 200) {
        setState(() {
          history = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  Color getRiskColor(String risk) {
    if (risk == "high risk") return Colors.red;
    if (risk == "mid risk") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B80FF),
                Color(0xFFAC46FF),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text(
              "History",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
               
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search records...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text("No history available"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];

                            return buildCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showDetailsPopup(BuildContext context, dynamic item) {
    final Color riskColor = getRiskColor(item["risk_level"].toString());
    final double confidence = (item["confidence"] as num).toDouble();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/logo.png', height: 26, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Health Record Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Date
                    Text(
                      item["createdAt"].toString().substring(0, 16).replaceFirst("T", "  "),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Confidence gauge + Risk badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: confidence / 100,
                                strokeWidth: 9,
                                backgroundColor: Colors.grey.shade200,
                                color: confidence >= 70
                                    ? Colors.green
                                    : confidence >= 40
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      confidence.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Score",
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Risk badge
                        Column(
                          children: [
                            const Text("Risk Level", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: riskColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                item["risk_level"].toString().toUpperCase(),
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Vital metric grid
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _detailCard(Icons.calendar_month, "Pregnancy Week",
                            item["Week"].toString(), const Color(0xFF2B80FF)),
                        _detailCard(Icons.cake_outlined, "Age",
                            "${item["Age"]} yrs", Colors.orange),
                        _detailCard(Icons.favorite_border, "Systolic BP",
                            "${item["SystolicBP"]} mmHg", Colors.red),
                        _detailCard(Icons.arrow_downward, "Diastolic BP",
                            "${item["DiastolicBP"]} mmHg", Colors.deepOrange),
                        _detailCard(Icons.water_drop_outlined, "Blood Sugar",
                            "${item["BS"]} mmol/L", Colors.teal),
                        _detailCard(Icons.thermostat, "Body Temp",
                            "${item["BodyTemp"]} °C", Colors.amber.shade800),
                        _detailCard(Icons.monitor_heart_outlined, "Heart Rate",
                            "${item["HeartRate"]} BPM", Colors.pink),
                        _detailCard(Icons.bar_chart, "Confidence",
                            "${confidence.toStringAsFixed(1)}%", Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard(IconData icon, String label, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget buildCard(dynamic item) {
    Color riskColor = getRiskColor(item["risk_level"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item["risk_level"].toUpperCase(),
                  style:
                      TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                item["createdAt"].toString().substring(0, 16),
                style: const TextStyle(color: Colors.grey),
              )
            ],
          ),

          const SizedBox(height: 12),

          // main data part
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildTop("Pregnancy Week", item["Week"].toString()),
              buildTop("Score", item["confidence"].toStringAsFixed(0)),
              buildTop(
                  "Confidence", "${item["confidence"].toStringAsFixed(1)}%"),
            ],
          ),

          const SizedBox(height: 15),

          // vital inputs boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildVitalBox(
                  "BP", "${item["SystolicBP"]}/${item["DiastolicBP"]}"),
              buildVitalBox("Sugar", item["BS"].toString()),
              buildVitalBox("Heart Rate", item["HeartRate"].toString()),
            ],
          ),

          const SizedBox(height: 15),

          // buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetailsPopup(context, item),
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text("View Details"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await PdfGenerator.generateAndPrintReport(
                          item as Map<String, dynamic>);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error generating report: $e")),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildTop(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget buildVitalBox(String title, String value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
