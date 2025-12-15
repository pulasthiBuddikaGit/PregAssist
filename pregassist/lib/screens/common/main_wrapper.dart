import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import '../nisalka/emergency_dashboard.dart'; 
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),         
    // const Physical()            
    const EmergencyDashboard(),   
    const ProfileScreen(),      
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- THE FIX IS HERE ---
      // This allows the gradient background to extend BEHIND the nav bar
      // so it shows through the rounded corners.
      extendBody: true, 

      body: _pages[_selectedIndex],
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12, 
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            // Ensure this is transparent or white depending on your preference, 
            // but usually white is standard for the bar itself.
            backgroundColor: Colors.white, 
            selectedItemColor: const Color.fromARGB(255, 59, 1, 134),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                activeIcon: GradientIcon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                activeIcon: GradientIcon(Icons.book),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                activeIcon: GradientIcon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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