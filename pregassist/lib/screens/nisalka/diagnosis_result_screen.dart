import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final String diagnosis;
  final String reasoning;

  const DiagnosisResultScreen({
    super.key,
    required this.diagnosis,
    required this.reasoning,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  // --- NEW: Save current diagnosis to SharedPreferences ---
  Future<void> _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('diagnosis_history');
    List<Map<String, String>> historyList = [];

    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      historyList = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    // Format current date (e.g., "2026-05-01")
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Add new entry to the top of the list
    historyList.insert(0, {
      'title': "Diagnosis: ${widget.diagnosis}",
      'date': dateStr,
    });

    // Optional: Keep only the latest 10 entries so it doesn't get infinitely long
    if (historyList.length > 10) {
      historyList = historyList.sublist(0, 10);
    }

    await prefs.setString('diagnosis_history', jsonEncode(historyList));
  }

  // --- THE HELPER FUNCTION ---
  Future<void> _launchAR(String drillId) async {
    print("🚀 Launching AR for: $drillId");
    
    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: 'com.pregassist.ar', 
      componentName: 'com.unity3d.player.UnityPlayerGameActivity', 
      
      category: 'android.intent.category.LAUNCHER',
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
        Flag.FLAG_ACTIVITY_CLEAR_TASK
      ],
      arguments: <String, dynamic>{
        'drill_id': drillId,
      },
    );

    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine status color and icon using widget.diagnosis
    IconData statusIcon;
    bool isNormal = widget.diagnosis.contains("Normal") || widget.diagnosis.contains("Low Risk");
    if (isNormal) {
      statusIcon = Icons.check_circle;
    } else {
      statusIcon = Icons.warning_amber_rounded;
    }

    // --- LOGIC FOR THE NEW ACTION BOX (Updated to call AR) ---
    String actionText;
    String actionImage;
    VoidCallback actionTap;

    if (widget.diagnosis.contains("Preterm Labor")) {
      actionText = "AR Training: Preterm Labor";
      actionImage = "assets/preterm_labour.png"; 
      actionTap = () => _launchAR("preterm"); 

    } else if (widget.diagnosis.contains("Preeclampsia")) {
      actionText = "AR Training: Preeclampsia";
      actionImage = "assets/preeclampsia.png"; 
      actionTap = () => _launchAR("preeclampsia");

    } else if (widget.diagnosis.contains("Sepsis")) {
      actionText = "AR Training: Sepsis";
      actionImage = "assets/sepsis.png"; 
      actionTap = () => _launchAR("sepsis");

    } else if (widget.diagnosis.contains("Hemorrhage")) {
      actionText = "AR Training: Hemorrhage";
      actionImage = "assets/hemorrhage.png"; 
      actionTap = () => _launchAR("hemorrhage");

    } else {
      actionText = "View Wellness Plan";
      actionImage = "assets/food.jpg"; 
      actionTap = () { print("Navigate to Diet/Wellness Page"); };
    }


    // 2. Define the Main Background Gradient Colors
    Color gradientTop = const Color(0xFFEFF6FF);
    Color gradientMiddle = const Color(0xFFFAF5FF);
    Color gradientBottom = const Color(0xFFDBEAFE);

    // 3. Wrap Scaffold in a Container
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientTop, gradientMiddle, gradientBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Diagnosis Results"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF000000)),
          titleTextStyle: const TextStyle(
            color: Color.fromARGB(255, 26, 0, 128),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // --- MAIN INFO BOX ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF637E), // Pink-ish
                        Color(0xFFFF8904), // Orange-ish
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(55, 255, 99, 125),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(statusIcon, size: 50, color: const Color(0xFFFFFFFF)),
                      const SizedBox(height: 12),
                      const Text(
                        "PREDICTED RISK:",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.diagnosis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 15),
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFFFFFFFF)),
                          SizedBox(width: 8),
                          Text(
                            "Why this result?",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.reasoning,
                          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- NEW ACTION BOX (Dynamic based on 4 Results) ---
                Container(
                  height: 100, 
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[300], // Fallback color if image fails
                    image: DecorationImage(
                      image: AssetImage(actionImage), 
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), 
                        BlendMode.darken
                      ),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(121, 1, 106, 226),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: actionTap, // <--- THIS NOW CALLS THE AR FUNCTION
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "RECOMMENDED ACTION",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    actionText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.arrow_forward, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 120),

                // --- HOME BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home),
                    label: const Text("Back to Home"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: const Color(0xFF193CB8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}