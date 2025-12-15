import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap Scaffold in a Container to apply the Gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // The 3-color gradient theme
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
            Color(0xFFDBEAFE),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        // 2. Set Scaffold background to transparent so gradient shows through
        backgroundColor: Colors.transparent,
        
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
            "Home",
            style: TextStyle(
              fontSize: 20,                // Bigger Size
              fontWeight: FontWeight.bold, // Bold
              // Changed to White so it is readable on the new Blue/Purple gradient
              color: Colors.white,    
            ),
          ),
          
          centerTitle: true,
        ),
        
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              // Add your home screen widgets here
            ],
          ),
        ),
      ),
    );
  }
}