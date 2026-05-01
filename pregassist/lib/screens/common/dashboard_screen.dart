import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../dimalsha/maternal_model.dart';
import '../dimalsha/ai_explanation_screen.dart';
import '../dimalsha/advice_screen.dart';
import '../dimalsha/alerts_screen.dart';
import '../dimalsha/trends_screen.dart';
import '../dimalsha/forecast_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String motherId;

  const DashboardScreen({super.key, required this.motherId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool showForm = false;

  MaternalRiskResult? result;
  bool isLoading = false;

  final Map<String, TextEditingController> controllers = {
    "Month": TextEditingController(), // 🔥 NEW
    "Age": TextEditingController(),
    "SystolicBP": TextEditingController(),
    "DiastolicBP": TextEditingController(),
    "BS": TextEditingController(),
    "BodyTemp": TextEditingController(),
    "HeartRate": TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // 🔥 MONTH → TRIMESTER
  int convertMonthToTrimester(int month) {
    if (month <= 3) return 1;
    else if (month <= 6) return 2;
    else return 3;
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.setString('user_data', jsonEncode(data));
  }

  Future<void> analyzeHealth() async {

    double? parse(String key) => double.tryParse(controllers[key]!.text);

    final month = int.tryParse(controllers["Month"]!.text);
    final age = parse("Age");
    final sbp = parse("SystolicBP");
    final dbp = parse("DiastolicBP");
    final bs  = parse("BS");
    final temp= parse("BodyTemp");
    final hr  = parse("HeartRate");

    if ([month, age, sbp, dbp, bs, temp, hr].contains(null)) {
      _showError("Please fill all fields correctly");
      return;
    }

    int trimester = convertMonthToTrimester(month!);

    setState(() => isLoading = true);

    try {

      await saveUserData({
        "motherId": widget.motherId,
        "Month": month,
        "Age": age,
        "SystolicBP": sbp,
        "DiastolicBP": dbp,
        "BS": bs,
        "BodyTemp": temp,
        "HeartRate": hr,
      });

      final prediction = await MaternalService.predict(
        motherId: widget.motherId,
        trimester: trimester,
        vitals: [age!, sbp!, dbp!, bs!, temp!, hr!],
      );

      setState(() => result = prediction);
      _showResultPopup();

    } catch (e) {
      _showError("Backend connection failed\n$e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
      ),
    );
  }

  void _showResultPopup() {
    if (result == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40), // Balance the close button
              const Expanded(
                child: Text(
                  "Analysis Complete",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 GAUGE FOR HEALTH SCORE
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: result!.healthScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      color: result!.healthScore >= 70
                          ? Colors.green
                          : (result!.healthScore >= 40 ? Colors.orange : Colors.red),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${result!.healthScore.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Score",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // 🔹 RISK
              Text(
                "Risk Level: ${result!.risk}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: result!.risk == "High" ? Colors.red : (result!.risk == "Moderate" ? Colors.orange : Colors.green),
                ),
              ),

              const SizedBox(height: 5),

              // 🔹 CONFIDENCE
              Text(
                "AI Confidence: ${result!.confidence.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 15),

              // 🔥 FORECAST & FACTOR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Trend: ${result!.forecast['trend'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Top Factor: ${result!.topFactor}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // 🔥 RECOMMENDATION
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recommendation:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(result!.recommendation),
              ),
              
              const SizedBox(height: 20),
              
              //  ACTION BUTTONS
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (result!.doctorAlert)
                    _buildIconAction(Icons.warning_amber_rounded, "Alerts", Colors.red, () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AlertsScreen(
                          riskLevel: result!.risk,
                          warnings: result!.warnings,
                          doctorAlert: result!.doctorAlert,
                          recommendation: result!.recommendation,
                        ),
                      ));
                    }),
                  _buildIconAction(Icons.psychology, "Why Risk?", Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AiExplanationScreen(
                        topFactor: result!.topFactor,
                        importance: result!.importance,
                      ),
                    ));
                  }),
                  _buildIconAction(Icons.lightbulb_outline, "Advice", Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AdviceScreen(
                        adviceList: result!.advice,
                      ),
                    ));
                  }),
                  _buildIconAction(Icons.trending_up, "Trends", Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TrendsScreen(
                        motherId: widget.motherId,
                      ),
                    ));
                  }),
                  _buildIconAction(Icons.online_prediction, "Forecast", Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForecastScreen(
                          forecast: result!.forecast,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 22,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATED WELCOME UI WITH CAROUSEL
  Widget _buildWelcomeUI() {
    return SingleChildScrollView(
      child: Column(
        children: [

          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: [
              "assets/mom_1.png",
              "assets/mom_2.png",
              "assets/mom_3.png",
            ].map((path) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(path, fit: BoxFit.cover, width: double.infinity),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          const Text(
            "Hello Mom 💜",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B80FF),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Caring for you and your baby\nwith intelligent and personalized health insights.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),

          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B80FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () => setState(() => showForm = true),
              child: const Text(
                "Take Health Test",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF51A2FF), Color(0xFF00D2F2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF51A2FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  "Your Health Status",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "No recent data available",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => showForm = false),
            ),
          ),

          _buildInput("Month"), 
          _buildInput("Age"),
          _buildInput("SystolicBP"),
          _buildInput("DiastolicBP"),
          _buildInput("BS"),
          _buildInput("BodyTemp"),
          _buildInput("HeartRate"),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF2B80FF),
            ),
            onPressed: isLoading ? null : analyzeHealth,
            child: Text(
              isLoading ? "Analyzing..." : "Analyze",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: key,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
            Color(0xFFDBEAFE),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          title: const Text(
            "Maternal Dashboard",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showForm ? _buildFormUI() : _buildWelcomeUI(),
          ),
        ),
      ),
    );
  }
}