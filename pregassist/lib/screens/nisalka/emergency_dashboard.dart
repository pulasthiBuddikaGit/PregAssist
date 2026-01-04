import 'package:flutter/material.dart';

class EmergencyDashboard extends StatelessWidget {
  const EmergencyDashboard({super.key});

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
          stops: [0.0, 0.5, 1.0], 
        ),
      ),
      child: Scaffold(
        // 2. Make Scaffold transparent so gradient shows through
        backgroundColor: Colors.transparent,
        
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                   Color(0xFF2B80FF),
                   Color(0xFFAC46FF),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0, 

          leadingWidth: 70, 
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0), 
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain, 
            ),
          ),
          
          title: const Text(
            "Emergency Training",
            style: TextStyle(
              fontSize: 20,              
              fontWeight: FontWeight.bold, 
              color: Colors.white,    
            ),
          ),
          centerTitle: true,
        ),
        
        // --- NEW SCROLLABLE BODY ---
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. BIG DIAGNOSIS BUTTON
              Container(
                width: double.infinity,
                height: 140, // Big box size
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // Pink/Orange Gradient for high visibility
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF637E), // Pink
                      Color(0xFFFF8904), // Orange
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                       Navigator.pushNamed(context, '/EmergencyDiagnosis');
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.medical_services_outlined, size: 40, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "GO TO DIAGNOSIS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. EMERGENCY TRAININGS TITLE
              const Text(
                "Emergency Trainings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193CB8),
                ),
              ),
              const SizedBox(height: 15),

              // 3. THE 4 BOXES (2 Top, 2 Below)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTrainingBox("Preterm Labor", Icons.baby_changing_station)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTrainingBox("Preeclampsia", Icons.speed)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTrainingBox("Sepsis", Icons.thermostat)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTrainingBox("Hemorrhage", Icons.water_drop)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 4. HISTORY TITLE
              const Text(
                "History",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193CB8),
                ),
              ),
              const SizedBox(height: 15),

              // 5. HISTORY DROP BOXES (One by One)
              _buildHistoryBox("Diagnosis: Normal", "Yesterday"),
              const SizedBox(height: 10),
              _buildHistoryBox("Diagnosis: Preterm Labor", "Last Week"),
              const SizedBox(height: 10),
              _buildHistoryBox("Diagnosis: Normal", "2 Weeks Ago"),
              
              // Extra space at bottom so navigation bar doesn't cover content
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET 1: Training Box (Square Cube) ---
  Widget _buildTrainingBox(String title, IconData icon) {
    return Container(
      height: 130, // Makes it square-ish
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Blue/Purple Gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B80FF),
            Color(0xFFAC46FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () { print("Tapped $title"); },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 35, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET 2: History Drop Box (Wide Strip) ---
  Widget _buildHistoryBox(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(4), // Padding for the border/container
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        // Blue/Purple Gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF51A2FF),
            Color(0xFF00D2F2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white24, // Semi-transparent white circle
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      ),
    );
  }
}