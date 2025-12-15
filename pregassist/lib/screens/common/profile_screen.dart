import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap everything in a Container to hold the Gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
            Color(0xFFDBEAFE),
          ],
          stops: [0.0, 0.5, 1.0], // Defines where the colors sit
        ),
      ),
      child: Scaffold(
        // 2. Make Scaffold transparent so gradient shows through
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
                bottom: Radius.circular(20),
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
            padding: const EdgeInsets.only(left: 10.0), 
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain, 
            ),
          ),
          
          // 2. UPDATED: Title with Color, Bold, and Size
          title: const Text(
            "My Profile",
            style: TextStyle(
              fontSize: 20,                // Bigger Size
              fontWeight: FontWeight.bold, // Bold
              // Changed to White so it is readable on the new Blue/Purple gradient
              color: Colors.white,    
            ),
          ),
          
          centerTitle: true,
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              
              // --- PROFILE PICTURE SECTION ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF637E),
                            Color(0xFFFF8904),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, size: 60, color: Color(0xFFFFFFFF)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF51A2FF),
                              Color(0xFF00D2F2),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // --- NAME & EMAIL ---
              const Text(
                "Katie",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Katie@example.com",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 30),
              
              // --- MENU OPTIONS ---
              _buildProfileOption(
                icon: Icons.person_outline, 
                title: "Edit Personal Details",
                onTap: () {},
              ),
              
              _buildProfileOption(
                icon: Icons.notifications_outlined, 
                title: "Notifications", 
                onTap: () {},
              ),
            
              // Logout Button
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // UPDATED: Replaced solid color with a Red Gradient
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDD2476), // Deep Pink/Red
                        Color(0xFFFB5938), // Bright Red/Orange
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white),
                ),
                title: const Text(
                  "Logout", 
                  style: TextStyle(
                    color: Colors.red, // Keep text red to match the warning vibe
                    fontWeight: FontWeight.bold
                  )
                ),
                onTap: () {
                  // Add logout logic here later
                  print("User logged out");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to make code cleaner
  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF51A2FF),
                Color(0xFF00D2F2),
              ],),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}