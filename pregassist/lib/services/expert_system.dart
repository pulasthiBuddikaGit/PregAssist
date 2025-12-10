import 'dart:io';

class MaternalHealthExpertSystem {
  MaternalHealthExpertSystem() {
    print("--- Maternal Health Expert System Initialized ---");
    print("Model: FORCED CLASSIFICATION (No 'Normal' Output)");
  }

  /// Input: Map of patient data
  /// Output: A list containing [Prediction, Reasoning]
  List<String> evaluatePatient(Map<String, dynamic> data) {
    // --- EXTRACT VARIABLES ---
    // Dart requires strict types, so we cast them
    int sbp = data['BP_Systolic'];
    int dbp = data['BP_Diastolic'];
    int hr = data['Heart_Rate'];
    int glucose = data['Blood_Glucose'];
    int week = data['GestationalWeek'];

    // Symptom Scores: 0=No, 1=Sometimes, 2=Almost Always
    int headacheScore = data['Headache'] ?? 0;
    int visionScore = data['VisualDisturbance'] ?? 0;
    int bleedingScore = data['HeavyBleeding'] ?? 0;
    int fluidScore = data['LeakingFluid'] ?? 0;
    int foulDischargeScore = data['FoulDischarge'] ?? 0;
    int abdPainScore = data['AbdominalPain'] ?? 0;

    // Initialize Risk Scores
    Map<String, int> scores = {
      'Preeclampsia': 0,
      'Hemorrhage': 0,
      'Sepsis': 0,
      'Preterm Labor': 0
    };

    // ===============================================================
    //  PHASE 1: CHECK FOR OBVIOUS SYMPTOMS (High Weight)
    // ===============================================================

    // Preeclampsia Signs
    if (sbp >= 130 || dbp >= 85) scores['Preeclampsia'] = (scores['Preeclampsia']! + 5);
    if (headacheScore > 0) scores['Preeclampsia'] = (scores['Preeclampsia']! + 3);
    if (visionScore > 0) scores['Preeclampsia'] = (scores['Preeclampsia']! + 4);
    if (week >= 20) scores['Preeclampsia'] = (scores['Preeclampsia']! + 1);

    // Hemorrhage Signs
    if (bleedingScore > 0) scores['Hemorrhage'] = (scores['Hemorrhage']! + 10);
    if (sbp < 100) scores['Hemorrhage'] = (scores['Hemorrhage']! + 4);
    if (hr > 100) scores['Hemorrhage'] = (scores['Hemorrhage']! + 3);

    // Sepsis Signs
    if (foulDischargeScore > 0) scores['Sepsis'] = (scores['Sepsis']! + 5);
    if (hr > 90) scores['Sepsis'] = (scores['Sepsis']! + 3);
    if (glucose > 120) scores['Sepsis'] = (scores['Sepsis']! + 2);
    if (abdPainScore > 0 && week < 37) scores['Sepsis'] = (scores['Sepsis']! + 2);

    // Preterm Labor Signs
    if (week < 37) scores['Preterm Labor'] = (scores['Preterm Labor']! + 2);
    if (fluidScore > 0) scores['Preterm Labor'] = (scores['Preterm Labor']! + 10);
    if (abdPainScore > 0) scores['Preterm Labor'] = (scores['Preterm Labor']! + 4);

    // ===============================================================
    //  PHASE 2: THE "CLOSEST MATCH" TIE-BREAKER
    // ===============================================================

    // Slight BP elevation leans Preeclampsia
    if (sbp > 120) scores['Preeclampsia'] = (scores['Preeclampsia']! + 2);
    if (dbp > 80) scores['Preeclampsia'] = (scores['Preeclampsia']! + 2);

    // Slight High HR leans Sepsis/Hemorrhage
    if (hr > 80) {
      scores['Sepsis'] = (scores['Sepsis']! + 1);
      scores['Hemorrhage'] = (scores['Hemorrhage']! + 1);
    }

    // Slight Low BP leans Hemorrhage
    if (sbp < 110) scores['Hemorrhage'] = (scores['Hemorrhage']! + 2);

    // Early pregnancy leans Preterm
    if (week < 34) scores['Preterm Labor'] = (scores['Preterm Labor']! + 1);

    // ===============================================================
    //  PHASE 3: DETERMINE WINNER
    // ===============================================================

    // Find the key with the highest value
    String predictedEmergency = scores.keys.first;
    int maxScore = scores[predictedEmergency]!;

    scores.forEach((key, value) {
      if (value > maxScore) {
        maxScore = value;
        predictedEmergency = key;
      }
    });

    String reasoning = "";
    if (maxScore == 0) {
      // Fallback
      if (week < 37) {
        predictedEmergency = "Preterm Labor";
        reasoning = "Baseline risk due to gestational age < 37 weeks.";
      } else {
        predictedEmergency = "Preeclampsia";
        reasoning = "Baseline risk due to term gestation.";
      }
    } else {
      // Construct reasoning
      if (predictedEmergency == "Preeclampsia") {
        reasoning = "Driven by BP $sbp/$dbp and neuro risk factors.";
      } else if (predictedEmergency == "Hemorrhage") {
        reasoning = "Driven by bleeding risk or lower BP ($sbp).";
      } else if (predictedEmergency == "Sepsis") {
        reasoning = "Driven by Heart Rate ($hr) or infection markers.";
      } else if (predictedEmergency == "Preterm Labor") {
        reasoning = "Driven by gestational week $week and uterine signs.";
      }
    }

    return [predictedEmergency, reasoning];
  }
}

// ==========================================
// INTERACTIVE MODE HELPER FUNCTIONS
// ==========================================

int askSymptom(String questionText) {
  print("\n$questionText");
  print("  1. Not at all");
  print("  2. Sometimes");
  print("  3. Almost always");
  while (true) {
    stdout.write("  Select (1-3): ");
    String? choice = stdin.readLineSync();
    if (choice == '1') return 0;
    if (choice == '2') return 1;
    if (choice == '3') return 2;
    print("  Please type 1, 2, or 3.");
  }
}

int askNumber(String prompt) {
  while (true) {
    stdout.write("$prompt: ");
    String? input = stdin.readLineSync();
    if (input != null && int.tryParse(input) != null) {
      return int.parse(input);
    }
    print("  Invalid number. Please try again.");
  }
}

Map<String, dynamic>? getUserInput() {
  print("\n==================================");
  print("--- ENTER CURRENT STATUS ---");

  try {
    int sbp = askNumber("BP_Systolic (e.g., 120)");
    int dbp = askNumber("BP_Diastolic (e.g., 80)");
    int hr = askNumber("Heart_Rate (e.g., 75)");
    int gl = askNumber("Blood_Glucose (e.g., 90)");
    int week = askNumber("GestationalWeek (e.g., 30)");

    print("\n--- CHECK FOR PRECURSORS ---");
    int headache = askSymptom("Headache frequency?");
    int vision = askSymptom("Visual Disturbances?");
    int bleeding = askSymptom("Vaginal Bleeding?");
    int abdPain = askSymptom("Abdominal/Pelvic Pain?");
    int foulDischarge = askSymptom("Foul Discharge?");
    int fluid = askSymptom("Leaking Fluid?");

    return {
      'BP_Systolic': sbp,
      'BP_Diastolic': dbp,
      'Heart_Rate': hr,
      'Blood_Glucose': gl,
      'GestationalWeek': week,
      'Headache': headache,
      'VisualDisturbance': vision,
      'HeavyBleeding': bleeding,
      'AbdominalPain': abdPain,
      'FoulDischarge': foulDischarge,
      'LeakingFluid': fluid
    };
  } catch (e) {
    print("Error getting input.");
    return null;
  }
}

// --- MAIN PROGRAM ---
void main() {
  MaternalHealthExpertSystem doctorAI = MaternalHealthExpertSystem();

  while (true) {
    print("\n**************************************");
    print("  MATERNAL RISK PREDICTION SYSTEM  ");
    print("  (Dart Version - Strict 4-Class)  ");
    print("**************************************");

    Map<String, dynamic>? patientData = getUserInput();

    if (patientData != null) {
      List<String> result = doctorAI.evaluatePatient(patientData);
      String diagnosis = result[0];
      String reasoning = result[1];

      print("\n>>> PREDICTION REPORT <<<");
      print("PREDICTED CLASS: $diagnosis");
      print("REASONING:       $reasoning");
    }

    stdout.write("\nPredict another patient? (y/n): ");
    String? cont = stdin.readLineSync();
    if (cont?.toLowerCase() != 'y') {
      break;
    }
  }
}