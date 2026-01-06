import 'package:flutter/material.dart';

import 'package:android_intent_plus/android_intent.dart'; // Import this
import 'package:android_intent_plus/flag.dart';


class EmergencyDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;


    // Helper function to map titles to IDs
  String _getDrillId(String title) {
    if (title.toLowerCase().contains("hemorrhage")) return "hemorrhage";
    if (title.toLowerCase().contains("sepsis")) return "sepsis";
    if (title.toLowerCase().contains("preterm")) return "preterm";
    if (title.toLowerCase().contains("preeclampsia")) return "preeclampsia";
    return "default";
  }

  const EmergencyDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. Common Background Gradient
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF193CB8)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF193CB8),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        // UPDATED: Added bottom padding (margin) to the scroll view
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 90), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 2. DYNAMIC INFO BOX
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Blue/Purple Gradient
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B80FF),
                      Color(0xFFAC46FF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white, size: 40),
                    const SizedBox(height: 15),
                    Text(
                      "About $title",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 3. DYNAMIC TRAINING BUTTON (Image Background)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[300], 
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                    // Darken image so text is readable
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5), 
                      BlendMode.darken,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    // Inside onTap:
                    // Import is already at the top: import 'package:device_apps/device_apps.dart';

                      onTap: () async {
                      String drillId = _getDrillId(title); // Get the ID based on the screen title
                      print("🚀 Sending command to Unity: $drillId");

                      final intent = AndroidIntent(
                        action: 'android.intent.action.MAIN',
                        package: 'com.pregassist.ar',
                        componentName: 'com.unity3d.player.UnityPlayerGameActivity', // The correct name we found
                        category: 'android.intent.category.LAUNCHER',
                        
                        // --- UPDATED FLAGS HERE ---
                        // This combination forces Unity to close and restart fresh every time
                        flags: <int>[
                          Flag.FLAG_ACTIVITY_NEW_TASK,
                          Flag.FLAG_ACTIVITY_CLEAR_TASK 
                        ],
                        // --------------------------
                        
                        arguments: <String, dynamic>{
                          'drill_id': drillId,
                        },
                      );

                      await intent.launch();
                    },
                    // UPDATED: Changed Center to Row to include the icon
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$title Training",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 15), // Space between text and icon
                        
                        // Your Requested Icon Container
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
            ],
          ),
        ),
      ),
    );
  }
}