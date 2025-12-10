import 'package:flutter/material.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nisalka's Diagnosis"),
        backgroundColor: Colors.purple[100], // distinct color to know it's yours
      ),
      body: const Center(
        child: Text("This is where Nisalka builds his features!"),
      ),
    );
  }
}