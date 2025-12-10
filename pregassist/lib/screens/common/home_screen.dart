import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PregAssist Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to PregAssist", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            
            // Button to go to Nisalka's work
            ElevatedButton(
              onPressed: () {
                // This string matches the route in main.dart
                Navigator.pushNamed(context, '/nisalka');
              },
              child: const Text("Go to Nisalka's Screens"),
            ),
            
            // Add buttons for other teammates here
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigator.pushNamed(context, '/teammate1');
              },
              child: const Text("Go to Teammate 1"),
            ),
          ],
        ),
      ),
    );
  }
}