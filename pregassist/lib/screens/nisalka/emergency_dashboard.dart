import 'package:flutter/material.dart';
import './diagnosis_wizard.dart';
import './emergency_detail_screen.dart';

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
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        
        appBar: AppBar(
          // --- AppBar Gradient & Rounded Bottom ---
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

          // --- LOGO & TITLE ---
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 85),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. BIG DIAGNOSIS BUTTON
              Container(
                width: double.infinity,
                height: 90, // Big box size
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  // Pink/Orange Gradient (Urgent look)
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiagnosisWizard(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.medical_services_outlined, size: 25, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "GO TO DIAGNOSIS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193CB8),
                  decoration: TextDecoration.underline, // <--- Adds the underline
                  decorationColor: Color(0xFF193CB8),   // Optional: Matches underline color to text
                ),
              ),
              const SizedBox(height: 15),

              // 3. THE 4 BOXES (Updated with FULL DESCRIPTIONS)
              Column(
                children: [
                  Row(
                    children: [
                      // --- BOX 1: PRETERM LABOR ---
                      Expanded(child: _buildTrainingBox(
                        context, 
                        "Preterm Labor", 
                        Icons.child_friendly, 
                        "assets/preterm_labour.png",
                        "Preterm labor occurs when regular contractions result in the opening of your cervix after week 20 and before week 37. Immediate medical attention is required.\n\nSYMPTOMS:\n• Regular contractions (every 10 mins)\n• Constant, dull lower back pain\n• Pelvic pressure or water breaking\n\nACTIONS:\n• Lie on the Left Side immediately\n• Drink water to stop dehydration\n• Transfer to hospital"
                      )),
                      const SizedBox(width: 15),
                      
                      // --- BOX 2: PREECLAMPSIA ---
                      Expanded(child: _buildTrainingBox(
                        context,
                        "Preeclampsia", 
                        Icons.speed, 
                        "assets/preeclampsia.png",
                        "Preeclampsia is a serious condition marked by dangerously high blood pressure and organ damage. Urgent medical care is needed to prevent fatal seizures (Eclampsia).\n\nSYMPTOMS:\n• Blood Pressure > 140/90 mmHg\n• Severe headache that won't go away\n• Blurred vision or seeing flashing spots\n\nACTIONS:\n• Minimize noise and light (prevent seizures)\n• Lie on the Left Side\n• Urgent transfer for delivery"
                      )), 
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // --- BOX 3: SEPSIS ---
                      Expanded(child: _buildTrainingBox(
                        context,
                        "Sepsis", 
                        Icons.thermostat, 
                        "assets/sepsis.png",
                        "Maternal Sepsis is a life-threatening immune response to an infection that damages body tissues. Rapid antibiotic treatment and hospitalization are critical.\n\nSYMPTOMS:\n• Fever (>38°C) or very low temp (<36°C)\n• Fast heart rate (>100 bpm)\n• Confusion, slurred speech, or shivering\n\nACTIONS:\n• Administer Oxygen\n• Start Antibiotics within 1 hour\n• Maintain fluids and monitor vitals"
                      )),
                      const SizedBox(width: 15),
                      
                      // --- BOX 4: HEMORRHAGE ---
                      Expanded(child: _buildTrainingBox(
                        context,
                        "Hemorrhage", 
                        Icons.water_drop, 
                        "assets/hemorrhage.png",
                        "Postpartum Hemorrhage is severe bleeding of more than 500ml after birth, often caused by the uterus failing to contract. Immediate intervention is vital to prevent shock.\n\nSYMPTOMS:\n• Soaking more than 1 pad in 15 minutes\n• Uterus feels soft or 'boggy' (not hard)\n• Pale skin and fast heart rate\n\nACTIONS:\n• Call 1990 immediately\n• Perform firm Uterine Massage\n• Elevate legs to maintain blood flow"
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 4. HISTORY TITLE
              const Text(
                "Diagnosis History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF193CB8),
                  decoration: TextDecoration.underline, // <--- Adds the underline
                  decorationColor: Color(0xFF193CB8),   // Optional: Matches underline color to text
                  
                ),
              ),
              const SizedBox(height: 15),

              // 5. HISTORY BOXES (One by One)
              _buildHistoryBox("Diagnosis: Hemorrhage", "Yesterday"),
              const SizedBox(height: 10),
              _buildHistoryBox("Diagnosis: Preterm Labor", "Last Week"),
              const SizedBox(height: 10),
              _buildHistoryBox("Diagnosis: Sepsis", "2 Weeks Ago"),
              
              const SizedBox(height: 40), // Extra bottom space
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER 1: Training Box ---
  Widget _buildTrainingBox(BuildContext context, String title, IconData icon, String imagePath, String description) {
    return Container(
      height: 110, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF51A2FF), Color(0xFF00D2F2)],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () { 
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyDetailScreen(
                    title: title,
                    imagePath: imagePath,
                    description: description,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0, 1))],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER 2: History Box ---
  Widget _buildHistoryBox(String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 240, 249, 251),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color.fromARGB(62, 222, 222, 222), 
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF193CB8),
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color.fromARGB(255, 88, 88, 88)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color.fromARGB(255, 0, 0, 0), size: 15),
      ),
    );
  }
}