import 'package:flutter/material.dart';

import './diagnosis_wizard.dart';

class EmergencyDashboard extends StatelessWidget {
  const EmergencyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap everything in a Container to hold the Gradient
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
          stops: [0.0, 0.5, 1.0], // Defines where the colors sit
        ),
      ),
      child: Scaffold(
        // 2. Make Scaffold transparent so gradient shows through
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        
        appBar: AppBar(
          // --- UPDATED: AppBar Gradient & Rounded Bottom ---
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              // The Gradient for the AppBar
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                   Color(0xFF2B80FF),
                   Color(0xFFAC46FF),
                ],
              ),
              // Rounded Corners (Bottom only)
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
          ),
          // Set shape to transparent/null so flexibleSpace takes over clipping if needed
          // or just rely on the Container's borderRadius above.
          // Note: backgroundColor must be transparent.
          backgroundColor: Colors.transparent,
          elevation: 0, 

          // --- EXISTING PROPERTIES BELOW ---
          
          // 1. UPDATED: Increase this value to make the logo area wider/bigger
          leadingWidth: 70, 

          // UPDATED: Adjusted logo container
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0), 
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain, 
            ),
          ),
          
          // 2. UPDATED: Title with Color, Bold, and Size
          title: const Text(
            "Emergency Training",
            style: TextStyle(
              fontSize: 20,                // Bigger Size
              fontWeight: FontWeight.bold, // Bold
              // Changed to White so it is readable on the new Blue/Purple gradient
              color: Colors.white,    
            ),
          ),
          
          centerTitle: true,
        ),
        
        // Removed 'const' because the button action is not constant
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
            children: [
              const Text(
                "Emergencies",
                style: TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 20), // Adds space between text and button
              
              ElevatedButton.icon(
                icon: const Icon(Icons.medical_services),
                label: const Text("Go to Diagnosis"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiagnosisWizard(),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}