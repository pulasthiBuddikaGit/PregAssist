import 'package:flutter/material.dart';

class NisalkaDashboard extends StatelessWidget {
  const NisalkaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nisalka's Feature"),
        backgroundColor: Colors.purple[100], 
      ),
      // Removed 'const' because the button action is not constant
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
          children: [
            const Text(
              "This is where Nisalka builds his features!",
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 20), // Adds space between text and button
            
            ElevatedButton.icon(
              icon: const Icon(Icons.medical_services), // Adds a nice icon
              label: const Text("Go to Diagnosis"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // This triggers the route defined in main.dart
                // The Bottom Navigation Bar will disappear on the new screen
                Navigator.pushNamed(context, '/EmergencyDiagnosis');
              },
            ),
          ],
        ),
      ),
    );
  }
}