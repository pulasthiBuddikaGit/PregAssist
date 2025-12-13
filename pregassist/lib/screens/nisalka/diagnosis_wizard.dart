import 'package:flutter/material.dart';
import 'diagnosis_result_screen.dart';

// IMPORTANT: This import path matches your file structure
import '../../services/expert_system.dart'; 

class DiagnosisWizard extends StatefulWidget {
  const DiagnosisWizard({super.key});

  @override
  State<DiagnosisWizard> createState() => _DiagnosisWizardState();
}

class _DiagnosisWizardState extends State<DiagnosisWizard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Question List
  final List<Map<String, dynamic>> _questions = [
    {
      "title": "Headache",
      "question": "Have you been experiencing severe or persistent headaches recently?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
    {
      "title": "Visual Disturbances",
      "question": "Have you had any trouble with your vision (blurriness/flashes)?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
    {
      "title": "Heavy Bleeding",
      "question": "Have you noticed any heavy vaginal bleeding (soaking through pads)?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
    {
      "title": "Abdominal Pain",
      "question": "Are you feeling any severe pain in your stomach or pelvic area?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
    {
      "title": "Foul Discharge",
      "question": "Have you noticed any unusual or bad-smelling vaginal discharge?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
    {
      "title": "Leaking Fluid",
      "question": "Have you experienced any sudden or continuous leaking of watery fluid?",
      "options": ["Not at all", "Sometimes", "Frequently"],
    },
  ];

  late List<int> _selectedAnswers;

  @override
  void initState() {
    super.initState();
    // Initialize answers with -1 (meaning "not answered yet")
    _selectedAnswers = List.filled(_questions.length, -1);
  }

  void _nextPage() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishDiagnosis();
    }
  }

  void _finishDiagnosis() {
    // Check if all questions are answered
    if (_selectedAnswers.contains(-1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions before finishing."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // --- 1. HARDCODED VITALS ---
    Map<String, dynamic> patientData = {
      'BP_Systolic': 120,    
      'BP_Diastolic': 80,    
      'Heart_Rate': 75,      
      'Blood_Glucose': 90,   
      'GestationalWeek': 30, 
    };

    // --- 2. ADD USER ANSWERS TO DATA ---
    patientData['Headache'] = _selectedAnswers[0];
    patientData['VisualDisturbance'] = _selectedAnswers[1];
    patientData['HeavyBleeding'] = _selectedAnswers[2];
    patientData['AbdominalPain'] = _selectedAnswers[3];
    patientData['FoulDischarge'] = _selectedAnswers[4];
    patientData['LeakingFluid'] = _selectedAnswers[5];

    // --- 3. CALL THE EXPERT SYSTEM ---
    MaternalHealthExpertSystem expertSystem = MaternalHealthExpertSystem();
    
    // Get the result (List containing [Diagnosis, Reasoning])
    List<String> results = expertSystem.evaluatePatient(patientData);

    String diagnosis = results[0];
    String reasoning = results[1];

    // --- 4. NAVIGATE TO RESULTS ---
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DiagnosisResultScreen(
          diagnosis: diagnosis,
          reasoning: reasoning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap everything in a Container to hold the Gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3E5F5), // Light Purple/Lavender (Top)
            Colors.white,      // White (Bottom)
          ],
        ),
      ),
      child: Scaffold(
        // 2. Make Scaffold transparent so gradient shows through
        backgroundColor: Colors.transparent,
        
        appBar: AppBar(
          title: Text("Assessment (${_currentIndex + 1}/${_questions.length})"),
          // 3. Make AppBar transparent and remove shadow
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.white.withOpacity(0.5), // Semi-transparent white
              color: const Color.fromARGB(255, 108, 79, 113),
              minHeight: 6,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final questionData = _questions[index];
    final options = questionData['options'] as List<String>;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Symptom Title
          Text(
            questionData['title'],
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Color.fromARGB(255, 108, 79, 113), // Matches your theme color
              letterSpacing: 1.2
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          
          // Question Text
          Text(
            questionData['question'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Options Buttons (0, 1, 2)
          ...List.generate(3, (optionIndex) {
            bool isSelected = _selectedAnswers[index] == optionIndex;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedAnswers[index] = optionIndex;
                  });
                  // Auto-advance after a short delay
                  Future.delayed(const Duration(milliseconds: 250), _nextPage);
                },
                style: ElevatedButton.styleFrom(
                  // Use your custom purple for selected state
                  backgroundColor: isSelected ? const Color.fromARGB(255, 82, 13, 94) : Colors.white,
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  elevation: isSelected ? 4 : 1,
                  side: BorderSide(
                    color: isSelected ? const Color.fromARGB(255, 82, 13, 94) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  options[optionIndex],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}