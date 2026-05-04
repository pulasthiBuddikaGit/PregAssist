import 'package:flutter/material.dart';

class AiExplanationScreen extends StatelessWidget {
  final String topFactor;
  final Map<String, double> importance;

  const AiExplanationScreen({
    Key? key,
    required this.topFactor,
    required this.importance,
  }) : super(key: key);

  String getFullName(String key) {
    switch (key) {
      case 'BS':
        return 'Blood Sugar';
      case 'SystolicBP':
        return 'Systolic BP';
      case 'DiastolicBP':
        return 'Diastolic BP';
      case 'BodyTemp':
        return 'Body Temperature';
      case 'HeartRate':
        return 'Heart Rate';
      default:
        return key;
    }
  }

  String getExplanation(String key, bool isRisk) {
    switch (key) {
      case 'BS':
        return isRisk
            ? "High blood sugar is increasing your risk."
            : "Blood sugar is stable.";
      case 'SystolicBP':
      case 'DiastolicBP':
        return isRisk
            ? "Blood pressure is contributing to risk."
            : "Blood pressure is under control.";
      case 'HeartRate':
        return isRisk
            ? "Heart rate is higher than normal."
            : "Heart rate is stable.";
      default:
        return isRisk
            ? "This factor contributes to risk."
            : "This factor is normal.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = importance.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final displayEntries = sortedEntries.take(5).toList();
    final totalImportance =
        displayEntries.fold(0.0, (sum, e) => sum + e.value.abs());

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text("Risk Analysis",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 90,
        leading: Row(
          children: [
            IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Image.asset('assets/logo.png'),
            ),
          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEEF4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // 🔥 TOP FACTOR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text("Top Contributing Factor"),
                    const SizedBox(height: 5),
                    Text(
                      getFullName(topFactor),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // 🔥 AI EXPLANATION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology,
                        color: Colors.deepPurple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${getFullName(topFactor)} has the highest impact on your current risk level.",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text("Feature Contribution",
                  style:
                      TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              // 🔥 HORIZONTAL BARS
              Expanded(
                child: ListView(
                  children: displayEntries.map((entry) {
                    final val = entry.value;
                    final percent =
                        (val.abs() / totalImportance) * 100;
                    final isRisk = val > 0;

                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  getFullName(entry.key),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                "${percent.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRisk ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: percent / 100,
                            color: isRisk
                                ? Colors.red
                                : Colors.green,
                            backgroundColor:
                                Colors.grey.shade200,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            getExplanation(
                                entry.key, isRisk),
                            style: const TextStyle(
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  "Red = Risk | Green = Protective",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}