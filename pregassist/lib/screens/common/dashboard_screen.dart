import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../dimalsha/maternal_model.dart';
import '../dimalsha/ai_explanation_screen.dart';
import '../dimalsha/advice_screen.dart';
import '../dimalsha/alerts_screen.dart';
import '../dimalsha/trends_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MaternalRiskResult? result;
  bool isLoading = false;
  int selectedTrimester = 1;

  final Map<String, TextEditingController> controllers = {
    "Age": TextEditingController(),
    "SystolicBP": TextEditingController(),
    "DiastolicBP": TextEditingController(),
    "BS": TextEditingController(),
    "BodyTemp": TextEditingController(),
    "HeartRate": TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveVitalsToHistory({
    required double age,
    required double sbp,
    required double dbp,
    required double bs,
    required double temp,
    required double hr,
  }) async {
    try {
      await http.post(
        Uri.parse('https://pregassist-backend.onrender.com/vitals/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "motherId": "mother1",
          "Age": age,
          "SystolicBP": sbp,
          "DiastolicBP": dbp,
          "BS": bs,
          "BodyTemp": temp,
          "HeartRate": hr,
          "trimester": selectedTrimester,
          "risk_level": result?.risk == 2
              ? "high"
              : result?.risk == 1
                  ? "mid"
                  : "low",
          "confidence": result?.confidence ?? 0.0
        }),
      );
    } catch (e) {
      debugPrint("Failed to save vitals history: $e");
    }
  }

  Future<void> analyzeHealth() async {
    String? errorMessage;

    double? parseInput(String key) {
      if (controllers[key]!.text.isEmpty) return null;
      return double.tryParse(controllers[key]!.text);
    }

    final age = parseInput("Age");
    final sbp = parseInput("SystolicBP");
    final dbp = parseInput("DiastolicBP");
    final bs = parseInput("BS");
    final temp = parseInput("BodyTemp");
    final hr = parseInput("HeartRate");

    if (age == null) {
      errorMessage = "Age is required.";
    } else if (age < 10 || age > 60) {
      errorMessage = "Please enter a valid maternal age.";
    } else if (sbp == null) {
      errorMessage = "Systolic blood pressure is required.";
    } else if (sbp < 60 || sbp > 240) {
      errorMessage = "Please enter a realistic Systolic BP.";
    } else if (dbp == null) {
      errorMessage = "Diastolic blood pressure is required.";
    } else if (dbp < 30 || dbp > 140) {
      errorMessage = "Please enter a realistic Diastolic BP.";
    } else if (bs == null) {
      errorMessage = "Blood sugar value is required.";
    } else if (bs < 1.0 || bs > 35.0) {
      errorMessage = "Please enter a realistic Blood Sugar.";
    } else if (temp == null) {
      errorMessage = "Body temperature is required.";
    } else if (temp < 33 || temp > 43) {
      errorMessage = "Please enter a realistic temperature.";
    } else if (hr == null) {
      errorMessage = "Heart rate data not received. Please enter manually.";
    } else if (hr < 30 || hr > 220) {
      errorMessage = "Please enter a realistic heart rate.";
    }

    if (errorMessage != null) {
      _showErrorDialog(errorMessage);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
       Uri.parse('https://pregassist-backend.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "trimester": selectedTrimester,
          "vitals": [age, sbp, dbp, bs, temp, hr]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          result = MaternalRiskResult.fromJson(data);
        });

        await saveVitalsToHistory(
          age: age!,
          sbp: sbp!,
          dbp: dbp!,
          bs: bs!,
          temp: temp!,
          hr: hr!,
        );

        _showResultPopup();
      } else {
        _showErrorDialog(
          "Failed to analyze. Server Error: ${response.statusCode}",
        );
      }
    } catch (e) {
      _showErrorDialog(
        "Connection failed! Ensure the AI server is running.\nError: $e",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Input Error",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showResultPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            "Analysis Complete",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result!.risk == 2 ? Colors.red[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                result!.risk == 2
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                color: result!.risk == 2 ? Colors.red : Colors.green,
                size: 54,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              result!.risk == 2
                  ? "High Risk Detected"
                  : (result!.risk == 1 ? "Mid Risk Detected" : "Low Risk"),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Confidence: ${result!.confidence.toStringAsFixed(1)}%",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          if (result!.risk == 2)
            TextButton.icon(
              icon: const Icon(Icons.warning, color: Colors.red),
              label: const Text(
                "View Alerts",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertsScreen(riskLevel: result!.risk),
                  ),
                );
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.analytics, color: Colors.pink),
            label: const Text(
              "Why am I at risk?",
              style: TextStyle(color: Colors.pink),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiExplanationScreen(
                    topFactor: result!.topContributor,
                    importance: result!.importance,
                  ),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.health_and_safety, color: Colors.green),
            label: const Text(
              "View Advice",
              style: TextStyle(color: Colors.green),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdviceScreen(
                    adviceList: result!.advice,
                  ),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.show_chart, color: Colors.blue),
            label: const Text(
              "View Trends",
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrendsScreen(
                    motherId: "mother1",
                  ),
                ),
              );
            },
          ),
          TextButton(
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F8).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD6E5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A3B47),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFFEA4C89),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFEA4C89),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, size: 21, color: Color(0xFFEA4C89)),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
        ),
      ),
    );
  }

  Widget _buildTrimesterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F8).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD6E5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonFormField<int>(
        value: selectedTrimester,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: "Trimester",
          labelStyle: TextStyle(
            color: Color(0xFFEA4C89),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: TextStyle(
            color: Color(0xFFEA4C89),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.calendar_today,
            size: 20,
            color: Color(0xFFEA4C89),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 34),
          contentPadding: EdgeInsets.only(top: 10, bottom: 10),
          isDense: true,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFEA4C89)),
        items: [1, 2, 3].map((int val) {
          return DropdownMenuItem<int>(
            value: val,
            child: Text(
              "Trimester $val",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A3B47),
              ),
            ),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() {
            selectedTrimester = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.pink.withOpacity(0.28),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Maternal Wellness",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Track your health with care and confidence",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: 220,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5C9A),
            Color(0xFFFF3D7F),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: isLoading ? null : analyzeHealth,
        child: Text(
          isLoading ? "Analyzing..." : "Analyze Health",
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            "Maternal Dashboard",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDEEF4), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 115, 20, 120),
          child: Column(
            children: [
              _buildHeaderBanner(),
              const SizedBox(height: 18),
              const Text(
                "Monitor your maternal health indicators",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildTrimesterDropdown(),
              const SizedBox(height: 16),
              _buildInputCard("Age", controllers["Age"]!, Icons.person),
              const SizedBox(height: 16),
              _buildInputCard(
                "Systolic BP",
                controllers["SystolicBP"]!,
                Icons.favorite,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                "Diastolic BP",
                controllers["DiastolicBP"]!,
                Icons.favorite_border,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                "Blood Sugar (mmol/L)",
                controllers["BS"]!,
                Icons.water_drop,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                "Body Temp (°C)",
                controllers["BodyTemp"]!,
                Icons.thermostat,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                "Heart Rate",
                controllers["HeartRate"]!,
                Icons.monitor_heart,
              ),
              const SizedBox(height: 30),
              Center(child: _buildAnalyzeButton()),
            ],
          ),
        ),
      ),
    );
  }
}