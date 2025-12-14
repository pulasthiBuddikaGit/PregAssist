import 'package:flutter/material.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final String diagnosis;
  final String reasoning;

  const DiagnosisResultScreen({
    super.key,
    required this.diagnosis,
    required this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine status color and icon
    
    IconData statusIcon;
    bool isNormal = diagnosis.contains("Normal") || diagnosis.contains("Low Risk");
    if (isNormal) {
      statusIcon = Icons.check_circle;
    } else {
      statusIcon = Icons.warning_amber_rounded;
    }
    // --- LOGIC FOR THE NEW ACTION BOX (Updated for 4 Results) ---
    String actionText;
    String actionImage;
    VoidCallback actionTap;

    if (diagnosis.contains("Preterm Labor")) {
      // RESULT 1: Preterm Labor
      actionText = "AR Emergency Training for Pretrm Labor";
      actionImage = "assets/preterm_labour.png"; 
      actionTap = () { print("Navigate to Hospital Maps"); };

    } else if (diagnosis.contains("Preeclampsia")) {
      // RESULT 2: Preeclampsia
      actionText = "AR Emergency Training for Preeclampsia";
      actionImage = "assets/preeclampsia.png"; 
      actionTap = () { print("Navigate to BP Tool or Call"); };

    } else if (diagnosis.contains("Sepsis")) {
      // RESULT 3: Sepsis
      actionText = "AR Emergency Training for Sepsis";
      actionImage = "assets/sepsis.png"; 
      actionTap = () { print("Call Emergency"); };

    } else if (diagnosis.contains("Hemorrhage")) {
      // RESULT 4: Hemorrhage
      actionText = "AR Emergency Training for Hemorrhage";
      actionImage = "assets/hemorrhage.png"; 
      actionTap = () { print("Call Ambulance Now"); };

    } else {
      // Fallback (Normal / Low Risk)
      actionText = "View Wellness Plan";
      actionImage = "assets/food.jpg"; 
      actionTap = () { print("Navigate to Diet"); };
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
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(55, 255, 99, 125),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
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
                        diagnosis,
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
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFFFFFFFF)),
                          const SizedBox(width: 8),
                          const Text(
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
                          reasoning,
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
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(121, 1, 106, 226),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: actionTap,
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