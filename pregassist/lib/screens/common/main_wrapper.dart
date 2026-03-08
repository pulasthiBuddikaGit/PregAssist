import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'dashboard_screen.dart';
import '../nisalka/emergency_dashboard.dart';
import './profile_screen.dart';
import '../Malikshi/chatbot_screen.dart';
import '../Malikshi/emotion_graph_screen.dart';
import '../Malikshi/score_screen.dart';
import '../Malikshi/suggestion_screen.dart';
import '../Malikshi/summary_screen.dart';
import '../Malikshi/trusted_person_screen.dart';

class MainWrapper extends StatefulWidget {
  final Widget? child;
  final int selectedIndex;

  const MainWrapper({
    super.key,
    this.child,
    this.selectedIndex = 0,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
<<<<<<< HEAD
=======
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const DashboardScreen(),
      const EmergencyDashboard(),
      const ProfileScreen(),
      // CTGSegmentScreen(data: widget.data),
    ];
  }

>>>>>>> main
  void _onItemTapped(int index) {
    if (index == widget.selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/app/mother/chat');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/app/mother/emergency');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/app/mother/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.child ?? const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: widget.selectedIndex,
            onTap: _onItemTapped,
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
                icon: Icon(Icons.dashboard),
                activeIcon: GradientIcon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_information),
                activeIcon: GradientIcon(Icons.medical_information),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.woman),
                activeIcon: GradientIcon(Icons.woman),
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
