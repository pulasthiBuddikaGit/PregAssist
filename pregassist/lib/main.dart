import 'package:flutter/material.dart';
// Import the common home screen
import 'screens/common/home_screen.dart';
// Import your specific screens
import 'screens/nisalka/nisalka_dashboard.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // This is the entry route (like index.js/App.js logic)
      initialRoute: '/', 
      
      // THE ROUTING TABLE
      routes: {
        // When the app asks for '/', show the HomeScreen
        '/': (context) => const HomeScreen(),
        
        // When the app asks for '/nisalka', show your page
        '/nisalka': (context) => const NisalkaDashboard(),
        
        // Add other teammates here later:
        // '/teammate1': (context) => const TeammatePage(),
      },
    );
  }
}