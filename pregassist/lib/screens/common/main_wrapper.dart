import 'package:flutter/material.dart';


import 'home_screen.dart';
import '../nisalka/emergency_dashboard.dart';
import '../pulasthi/ctg_segment_screen.dart';
import '../../models/pulasthi/assessment_data.dart';
import './profile_screen.dart';

import 'home_screen.dart'; 
import '../nisalka/emergency_dashboard.dart'; 
import '../dimalsha/dashboard_screen.dart';
import 'profile_screen.dart';


class MainWrapper extends StatefulWidget {
  final AssessmentData data;
  const MainWrapper({super.key, required this.data});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;


  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const EmergencyDashboard(),
      const ProfileScreen(),
      // CTGSegmentScreen(data: widget.data),
    ];
  }

  final List<Widget> _pages = [
    const HomeScreen(),         
    // const Physical()            
    const EmergencyDashboard(),   
    const DashboardScreen(),
    const ProfileScreen(),      
  ];


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
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
            currentIndex: _selectedIndex,
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
                icon: Icon(Icons.medical_information),
                activeIcon: GradientIcon(Icons.medical_information),
                label: 'Training',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pregnant_woman),
                activeIcon: GradientIcon(Icons.pregnant_woman),
                label: 'Dashboard',
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
