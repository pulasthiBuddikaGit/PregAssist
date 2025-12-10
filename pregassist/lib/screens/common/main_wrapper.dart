import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the common home
import '../Nisalka/nisalka_dashboard.dart'; 
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // LIST OF PAGES: The order here must match the order of icons in the BottomNavBar
  final List<Widget> _pages = [
    const HomeScreen(),         // Index 0: Home
    // const Physical()            Index 1: Physical health
    const NisalkaDashboard(),   // Index 2: Emergencies
    const ProfileScreen(),      // Index 3: profile 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body switches based on the selected index
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple, // App theme color
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person),
          //   label: 'Physical',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book), // Or whatever icon fits your feature
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          
        ],
      ),
    );
  }
}