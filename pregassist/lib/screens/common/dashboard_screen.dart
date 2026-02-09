import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dimalsha/maternal_model.dart';
import '../dimalsha/ai_explanation_screen.dart';
import '../dimalsha/advice_screen.dart';
import '../dimalsha/alerts_screen.dart';

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

  Future<void> analyzeHealth() async {
    // 1. Validate Inputs
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
  errorMessage = "Please enter a valid maternal age.";//(10-60 years)
} else if (sbp == null) {
  errorMessage = "Systolic blood pressure is required.";
} else if (sbp < 60 || sbp > 240) { 
  errorMessage = "Please enter a realistic Systolic BP.";//(60-240 mmHg)
} else if (dbp == null) {
  errorMessage = "Diastolic blood pressure is required.";
} else if (dbp < 30 || dbp > 140) { 
  errorMessage = "Please enter a realistic Diastolic BP.";//(30-140 mmHg)
} else if (bs == null) {
  errorMessage = "Blood sugar value is required.";
} else if (bs < 1.0 || bs > 35.0) { 
  errorMessage = "Please enter a realistic Blood Sugar.";//(1.0-35.0 mmol/L)
} else if (temp == null) {
  errorMessage = "Body temperature is required.";
} else if (temp < 92 || temp > 108) { 
  errorMessage = "Please enter a realistic temperature.";//(92°F-108°F)
} else if (hr == null) {
  errorMessage = "Heart rate data not received. Please enter manually.";
} else if (hr < 30 || hr > 220) { 
  errorMessage = "Please enter a realistic heart rate."; // (30-220 bpm)
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
        Uri.parse('http://127.0.0.1:5000/predict'),
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

        if (result!.risk == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlertsScreen(riskLevel: result!.risk),
              ),
            );
        }
        _showResultPopup();
      } else {
        _showErrorDialog("Failed to analyze. Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Connection failed! Ensure the AI server is running.\nError: $e");
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
        title: const Text("Input Error", style: TextStyle(color: Colors.redAccent)),
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
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
              fontSize: 20,
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
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 120), 
          child: Column(
            children: [
              Container(
                height: 150, 
                width: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/maternal_icon.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.pinkAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Trimester Dropdown
              _buildTrimesterDropdown(),
              const SizedBox(height: 15),

              _buildInputCard("Age", controllers["Age"]!, Icons.person),
              const SizedBox(height: 15),
              _buildInputCard(
                "Systolic BP",
                controllers["SystolicBP"]!,
                Icons.favorite,
              ),
              const SizedBox(height: 15),
              _buildInputCard(
                "Diastolic BP",
                controllers["DiastolicBP"]!,
                Icons.favorite_border,
              ),
              const SizedBox(height: 15),
              _buildInputCard(
                "Blood Sugar (mmol/L)",
                controllers["BS"]!,
                Icons.water_drop,
              ),
              const SizedBox(height: 15),
              _buildInputCard(
                "Body Temp (°F)",
                controllers["BodyTemp"]!,
                Icons.thermostat,
              ),
              const SizedBox(height: 15),
              _buildInputCard(
                "Heart Rate",
                controllers["HeartRate"]!,
                Icons.monitor_heart,
              ),
              
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 5),
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
                  onPressed: analyzeHealth,
                  child: Text(
                    isLoading ? "Analyzing..." : "Analyze Health",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          // 1. Initial State (Inside box): Ash/Grey
          labelStyle: TextStyle(
            color: Colors.grey[500], // Ash Color
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          // 2. Floated State: Pink Color (Matching Analyze Button)
          floatingLabelStyle: const TextStyle(
            color: Colors.pinkAccent, 
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, size: 20, color: Colors.pinkAccent),
          prefixIconConstraints: const BoxConstraints(minWidth: 30),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.only(bottom: 4, top: 4), 
        ),
      ),
    );
  }

  Widget _buildTrimesterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<int>(
        value: selectedTrimester,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: "Trimester",
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: Colors.pinkAccent, 
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.pinkAccent),
          prefixIconConstraints: const BoxConstraints(minWidth: 30),
          contentPadding: const EdgeInsets.only(bottom: 4, top: 4),
          isDense: true,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
        items: [1, 2, 3].map((int val) {
          return DropdownMenuItem<int>(
            value: val,
            child: Text(
              "Trimester $val",
              style: const TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
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

  void _showResultPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            "Analysis Complete",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: result!.risk == 2 ? Colors.red[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                result!.risk == 2
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                color: result!.risk == 2 ? Colors.red : Colors.green,
                size: 50,
              ),
            ),
            SizedBox(height: 15),
            Text(
              result!.risk == 2
                  ? "High Risk Detected"
                  : (result!.risk == 1 ? "Mid Risk Detected" : "Low Risk"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Confidence: ${result!.confidence.toStringAsFixed(1)}%",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
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
            icon: Icon(Icons.health_and_safety, color: Colors.green),
            label: Text("View Advice", style: TextStyle(color: Colors.green)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdviceScreen(adviceList: result!.advice),
                ),
              );
            },
          ),

          TextButton(
            child: Text("Close", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
