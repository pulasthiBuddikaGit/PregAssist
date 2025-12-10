import 'package:flutter/material.dart';

// 1. Import the Wrapper (The Container for your tabs)
import 'screens/common/main_wrapper.dart';

// 2. Import "Deep" screens (Pages that hide the navbar)
import 'screens/nisalka/diagnosis_screen.dart';
// import 'screens/Teammate1/some_other_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PregAssist',
      theme: ThemeData(primarySwatch: Colors.blue),
      
      // A. THE ENTRY POINT
      // Instead of HomeScreen, we load the Wrapper which holds the Navbar
      initialRoute: '/', 

      // B. THE ROUTE TABLE
      routes: {
        // The Root: Loads the Bottom Nav Bar setup
        '/': (context) => const MainWrapper(),

        // Deep Screen: When you go here, the Bottom Bar disappears
        '/diagnosis': (context) => const DiagnosisScreen(),
        
        // Add other standalone screens here
        // '/login': (context) => const LoginScreen(),
      },
    );
  }
}