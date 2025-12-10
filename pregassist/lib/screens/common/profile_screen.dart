import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- PROFILE PICTURE SECTION ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.purple[100], // Background color
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
                    child: const Icon(Icons.person, size: 60, color: Colors.purple),
                    // If you have an image, use this instead:
                    // child: ClipOval(child: Image.asset('assets/me.jpg', fit: BoxFit.cover)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // --- NAME & EMAIL ---
            const Text(
              "Nisalka",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "nisalka@example.com",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 30),
            const Divider(),

            // --- MENU OPTIONS ---
            _buildProfileOption(
              icon: Icons.person_outline, 
              title: "Edit Personal Details",
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.history, 
              title: "Medical History", 
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.notifications_outlined, 
              title: "Notifications", 
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined, 
              title: "Settings", 
              onTap: () {},
            ),
            
            // Logout Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50], 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                // Add logout logic here later
                print("User logged out");
              },
            ),
          ],
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
          color: Colors.blue[50], 
          borderRadius: BorderRadius.circular(8)
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}