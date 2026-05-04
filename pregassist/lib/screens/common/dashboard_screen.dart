import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../dimalsha/maternal_model.dart';
import '../../utils/pdf_generator.dart';
import '../dimalsha/ai_explanation_screen.dart';
import '../dimalsha/advice_screen.dart';
import '../dimalsha/alerts_screen.dart';
import '../dimalsha/trends_screen.dart';
import '../dimalsha/forecast_screen.dart';
import '../dimalsha/history_screen.dart';
import '../../utils/critical_alert_state.dart';

class DashboardScreen extends StatefulWidget {
  final String motherId;

  const DashboardScreen({super.key, required this.motherId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showForm = false;
  bool _validated = false;
  final Map<String, String?> _fieldErrors = {};

  MaternalRiskResult? result;
  bool isLoading = false;
  List<dynamic> historyList = [];
  Map<String, dynamic>? lastResult;
  final ScrollController _formScrollController = ScrollController();

  void generateReport(dynamic item) async {
    try {
      await PdfGenerator.generateAndPrintReport(item as Map<String, dynamic>);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating report: $e")),
      );
    }
  }

  Future<void> loadHistory() async {
    try {
      final res = await MaternalService.getHistory(widget.motherId);

      setState(() {
        historyList = res;

        if (historyList.isNotEmpty) {
          //  most recent history
          lastResult = historyList.first;
        }
      });
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadHistory(); 
  }

  final Map<String, TextEditingController> controllers = {
    "Pregnancy Week": TextEditingController(), // 🔥 NEW
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
    _formScrollController.dispose();
    super.dispose();
  }

  void _clearForm() {
    for (final c in controllers.values) {
      c.clear();
    }
    setState(() {
      _validated = false;
      _fieldErrors.clear();
    });
  }

  // 🔥 WEEK → TRIMESTER
  int convertWeekToTrimester(int week) {
    if (week <= 13) return 1;
    else if (week <= 27) return 2;
    else return 3;
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.setString('user_data', jsonEncode(data));
  }

  String? _validateField(String key) {
    final text = controllers[key]!.text.trim();
    if (text.isEmpty) return "Please input a valid value";

    // Integer fields
    if (key == "Pregnancy Week") {
      final v = int.tryParse(text);
      if (v == null) return "Please input a valid value";
      if (v < 1 || v > 42) return "Must be between 1 and 42 weeks";
      return null;
    }
    if (key == "HeartRate") {
      final v = int.tryParse(text);
      if (v == null) return "Please input a valid value";
      if (v < 40 || v > 200) return "Must be between 40 and 200 BPM";
      return null;
    }

    // Decimal fields
    final v = double.tryParse(text);
    if (v == null) return "Please input a valid value";
    switch (key) {
      case "Age":
        if (v < 10 || v > 70) return "Must be between 10 and 70 years";
        break;
      case "SystolicBP":
        if (v < 50 || v > 250) return "Must be between 50 and 250 mmHg";
        break;
      case "DiastolicBP":
        if (v < 30 || v > 150) return "Must be between 30 and 150 mmHg";
        break;
      case "BS":
        if (v < 1 || v > 30) return "Must be between 1 and 30 mmol/L";
        break;
      case "BodyTemp":
        if (v < 30 || v > 45) return "Must be between 30 and 45 °C";
        break;
    }
    return null;
  }

  Future<void> analyzeHealth() async {
    //  validation
    final errors = <String, String?>{};
    for (final key in controllers.keys) {
      errors[key] = _validateField(key);
    }

    // cross-validation for Systolic & Diastolic BP
    final sbpVal = double.tryParse(controllers["SystolicBP"]!.text);
    final dbpVal = double.tryParse(controllers["DiastolicBP"]!.text);
    if (sbpVal != null && dbpVal != null && sbpVal <= dbpVal) {
      errors["SystolicBP"] = "Systolic pressure must be higher than diastolic pressure";
    }

    setState(() {
      _validated = true;
      _fieldErrors.clear();
      _fieldErrors.addAll(errors);
    });

    if (errors.values.any((e) => e != null)) return;

    double? parse(String key) => double.tryParse(controllers[key]!.text);

    final week = int.tryParse(controllers["Pregnancy Week"]!.text);
    final age = parse("Age");
    final sbp = parse("SystolicBP");
    final dbp = parse("DiastolicBP");
    final bs  = parse("BS");
    final temp= parse("BodyTemp");
    final hr  = parse("HeartRate");

    int trimester = convertWeekToTrimester(week!);

    setState(() => isLoading = true);

    try {

      await saveUserData({
        "motherId": widget.motherId,
        "Week": week,
        "Age": age,
        "SystolicBP": sbp,
        "DiastolicBP": dbp,
        "BS": bs,
        "BodyTemp": temp,
        "HeartRate": hr,
      });

      final prediction = await MaternalService.predict(
        motherId: widget.motherId,
        week: week,
        trimester: trimester,
        vitals: [age!, sbp!, dbp!, bs!, temp!, hr!], 
      );

      setState(() {
        result = prediction;
        historyList = prediction.history;

        lastResult = {
          "risk_level": prediction.risk,
          "confidence": prediction.confidence,
          "Week": week,
          "Age": age,
          "SystolicBP": sbp,
          "DiastolicBP": dbp,
          "BS": bs,
          "BodyTemp": temp,
          "HeartRate": hr,
          "createdAt": DateTime.now().toIso8601String(),
        };
      });

      // high-risk alerts trigger notification
      if (prediction.risk.toLowerCase().contains('high')) {
        criticalAlertState.value = true;
      }

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 5),
              Image.asset('assets/logo.png', height: 28, fit: BoxFit.contain),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Analysis Complete",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
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
              //  HEALTH SCORE
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

              
              Builder(builder: (_) {
                final riskLower = result!.risk.toLowerCase();
                final Color riskColor = riskLower.contains("high")
                    ? Colors.red
                    : riskLower.contains("mid") || riskLower.contains("moderate")
                        ? Colors.orange
                        : Colors.green;
                final String riskLabel = riskLower.contains("high")
                    ? "High Risk"
                    : riskLower.contains("mid") || riskLower.contains("moderate")
                        ? "Moderate Risk"
                        : "Low Risk";
                return Column(
                  children: [
                    const Text(
                      "Risk Level",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: riskColor.withOpacity(0.4), width: 1.5),
                      ),
                      child: Text(
                        riskLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 5),

              // CONFIDENCE
              Text(
                "AI Confidence: ${result!.confidence.toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 15),

              // FORECAST & FACTOR
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Detailed trend analysis available in Forecast section",
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // RECOMMENDATION
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
                  if ((result!.risk ?? "").toLowerCase() != "low risk")
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
                      builder: (_) => TrendScreen(
                        forecast: result!.forecast,
                        history: result!.history,
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

  Color getRiskColor(String risk) {
    final String riskLower = risk.toLowerCase();
    if (riskLower == "high risk") return Colors.red;
    if (riskLower == "mid risk") return Colors.orange;
    return Colors.green;
  }

  // WELCOME UI WITH CAROUSEL
  Widget _buildWelcomeUI() {
    return Column(
      key: const ValueKey("welcome_ui"),
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
          ),

          const SizedBox(height: 25),

          
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () => setState(() => showForm = true),
              child: const Text(
                "Take Health Test",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 25),

        
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Activity",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryScreen(
                              motherId: widget.motherId,
                            ),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                if (lastResult == null)
                  const Text("No recent analysis available")
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // RISK LABEL
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: getRiskColor(lastResult!["risk_level"].toString()).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lastResult!["risk_level"].toUpperCase(),
                          style: TextStyle(
                            color: getRiskColor(lastResult!["risk_level"].toString()),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // STATS
                      Row(
                        children: [
                          Expanded(child: _miniStat("Week", lastResult!["Week"].toString())),
                          Expanded(child: _miniStat("Score", lastResult!["confidence"].toString())),
                          Expanded(child: _miniStat("Confidence", "${lastResult!["confidence"]}%")),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniBox("BP",
                              "${lastResult!["SystolicBP"]}/${lastResult!["DiastolicBP"]}"),
                          _miniBox("Sugar", lastResult!["BS"].toString()),
                          _miniBox("Heart Rate", lastResult!["HeartRate"].toString()),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistoryScreen(
                                      motherId: widget.motherId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("History"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => generateReport(lastResult),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Report", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
              ],
            ),
          ),

          const SizedBox(height: 20),

          
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE7F6), Color(0xFFE3F2FD)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.deepPurple),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Stay hydrated and eat balanced meals for a healthier pregnancy.",
                  ),
                )
              ],
            ),
          ),
        ],
      );
  }

  Widget _miniStat(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _miniBox(String title, String value) {
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

  Widget _buildFormUI() {
    return Column(
      key: const ValueKey("form_ui"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2B80FF)),
                  onPressed: () => setState(() => showForm = false),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Enter Your Health Details",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2B80FF)),
                      ),
                      Text(
                        "Provide accurate values for better prediction",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF2B80FF)),
                  tooltip: "Clear fields",
                  onPressed: _clearForm,
                ),
              ],
            ),
            const SizedBox(height: 25),

            _buildSectionTitle("Basic Info", Icons.person_outline),
            _buildPremiumInput("Pregnancy Week", "Weeks", Icons.calendar_month, "e.g. 24"),
            _buildPremiumInput("Age", "Years", Icons.cake, "e.g. 28"),

            const SizedBox(height: 20),

            _buildSectionTitle("Blood Pressure", Icons.favorite_border),
            _buildPremiumInput("SystolicBP", "mmHg", Icons.arrow_upward, "e.g. 120"),
            _buildPremiumInput("DiastolicBP", "mmHg", Icons.arrow_downward, "e.g. 80"),

            const SizedBox(height: 20),

            _buildSectionTitle("Health Metrics", Icons.health_and_safety_outlined),
            _buildPremiumInput("BS", "mmol/L", Icons.water_drop_outlined, "e.g. 5.0"),
            _buildPremiumInput("BodyTemp", "°C", Icons.thermostat, "e.g. 37.0"),
            _buildPremiumInput("HeartRate", "BPM", Icons.monitor_heart_outlined, "e.g. 85"),

            const SizedBox(height: 30),

            // Analyze Button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B80FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : analyzeHealth,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Analyze Health Risk",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInput(String key, String unit, IconData icon, String hint) {
    final hasError = _validated && (_fieldErrors[key] != null);
    final String label = key == "BS"
        ? "Blood Sugar"
        : key == "BodyTemp"
            ? "Body Temperature"
            : key == "SystolicBP"
                ? "Systolic BP"
                : key == "DiastolicBP"
                    ? "Diastolic BP"
                    : key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: hasError ? 4 : 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: hasError
                ? Border.all(color: Colors.red.shade400, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: hasError
                    ? Colors.red.withOpacity(0.10)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: TextField(
            controller: controllers[key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_validated) {
                setState(() => _fieldErrors[key] = _validateField(key));
              }
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: hasError ? Colors.red.shade400 : const Color(0xFF2B80FF)),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: hasError ? Colors.red.shade400 : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              labelText: label,
              labelStyle: TextStyle(color: hasError ? Colors.red.shade400 : null),
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade400 : const Color(0xFF2B80FF),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: hasError ? Colors.red.shade50 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 13, color: Colors.red.shade500),
                const SizedBox(width: 4),
                Text(
                  _fieldErrors[key]!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
              ],
            ),
          ),
      ],
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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: showForm ? _buildFormUI() : _buildWelcomeUI(),
            ),
          ),
        ),
      ),
    );
  }
}