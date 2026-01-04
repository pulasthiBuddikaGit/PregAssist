import 'package:flutter/material.dart';

class AssessmentData {
  int? segmentDuration;
  int? baselineFHR;
  int? lowestFHR;
  int? highestFHR;
  int accelerations;
  int contractions;
  int mildDecelerations;
  int severeDecelerations;
  int prolongedDecelerations;
  PredictionResult? prediction;

  AssessmentData({
    this.segmentDuration,
    this.baselineFHR,
    this.lowestFHR,
    this.highestFHR,
    this.accelerations = 0,
    this.contractions = 0,
    this.mildDecelerations = 0,
    this.severeDecelerations = 0,
    this.prolongedDecelerations = 0,
    this.prediction,
  });
}

enum Classification { normal, suspect, pathological }

class PredictionResult {
  final Classification classification;
  final List<String> reasons;

  PredictionResult({
    required this.classification,
    required this.reasons,
  });

  String get label {
    switch (classification) {
      case Classification.normal:
        return 'Normal (Class 1)';
      case Classification.suspect:
        return 'Suspect (Class 2)';
      case Classification.pathological:
        return 'Pathological (Class 3)';
    }
  }

  Color get backgroundColor {
    switch (classification) {
      case Classification.normal:
        return const Color(0xFFF0FDF4);
      case Classification.suspect:
        return const Color(0xFFFFFBEB);
      case Classification.pathological:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (classification) {
      case Classification.normal:
        return const Color(0xFFBBF7D0);
      case Classification.suspect:
        return const Color(0xFFFDE68A);
      case Classification.pathological:
        return const Color(0xFFFECACA);
    }
  }

  Color get textColor {
    switch (classification) {
      case Classification.normal:
        return const Color(0xFF15803D);
      case Classification.suspect:
        return const Color(0xFFB45309);
      case Classification.pathological:
        return const Color(0xFFB91C1C);
    }
  }

  Color get iconColor {
    switch (classification) {
      case Classification.normal:
        return const Color(0xFF16A34A);
      case Classification.suspect:
        return const Color(0xFFD97706);
      case Classification.pathological:
        return const Color(0xFFDC2626);
    }
  }

  IconData get icon {
    switch (classification) {
      case Classification.normal:
        return Icons.check_circle;
      case Classification.suspect:
        return Icons.warning;
      case Classification.pathological:
        return Icons.error;
    }
  }
}
