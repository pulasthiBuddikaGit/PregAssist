import 'package:flutter/material.dart';

class NisalkaDashboard extends StatelessWidget {
  const NisalkaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nisalka's Feature"),
        backgroundColor: Colors.purple[100], // distinct color to know it's yours
      ),
      body: const Center(
        child: Text("This is where Nisalka builds his features!"),
      ),
    );
  }
}