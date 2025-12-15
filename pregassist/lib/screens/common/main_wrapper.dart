import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the common home
import '../nisalka/emergency_dashboard.dart'; 
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
    const EmergencyDashboard(),   // Index 2: Emergencies
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
        selectedItemColor: Color.fromARGB(255, 59, 1, 134),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            activeIcon: GradientIcon(Icons.home), // <--- Added Gradient Here
            label: 'Home',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person),
          //   label: 'Physical',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            activeIcon: GradientIcon(Icons.book), // <--- Added Gradient Here
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: GradientIcon(Icons.person), // <--- Added Gradient Here
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- Helper Class for Gradient Icons ---
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const GradientIcon(this.icon, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B80FF),
            Color(0xFFAC46FF),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size),
    );
  }
}