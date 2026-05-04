import 'dart:convert';
import 'package:http/http.dart' as http;

class MaternalRiskResult {
  final String risk;
  final double confidence;
  final String topFactor;
  final double healthScore;
  final Map<String, double> importance;
  final List<Map<String, dynamic>> warnings;
  final Map<String, dynamic> forecast;
  final String recommendation;
  final bool doctorAlert;
  final List<String> advice;
  final List<dynamic> history;

  MaternalRiskResult({
    required this.risk,
    required this.confidence,
    required this.topFactor,
    required this.healthScore,
    required this.importance,
    required this.warnings,
    required this.forecast,
    required this.recommendation,
    required this.doctorAlert,
    required this.advice,
    required this.history,
  });

  factory MaternalRiskResult.fromJson(Map<String, dynamic> json) {
    return MaternalRiskResult(
      risk: json['risk_level'] ?? 'unknown',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      topFactor: json['top_factor'] ?? 'N/A',
      healthScore: (json['health_score'] as num? ?? 0).toDouble(),
      importance: Map<String, double>.from(
        (json['importance'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      warnings: List<Map<String, dynamic>>.from(
        (json['warnings'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
      forecast: Map<String, dynamic>.from(json['forecast'] ?? {}),
      recommendation: json['recommendation'] ?? '',
      doctorAlert: json['doctor_alert'] ?? false,
      advice: List<String>.from(json['advice'] ?? []),
      history: json['history'] ?? [],
    );
  }
}

class MaternalService {
  static const String baseUrl = 'https://pregassist-backend-production.up.railway.app';

  static Future<MaternalRiskResult> predict({
    required String motherId,
    required int week,
    required int trimester,
    required List<double> vitals,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'motherId': motherId,
        'week': week,
        'trimester': trimester,
        'vitals': vitals,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return MaternalRiskResult.fromJson(data);
    } else {
      throw Exception(
        'Prediction failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<dynamic>> getHistory(String motherId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/history/$motherId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load history");
    }
  }

  static Future<List<dynamic>> getDoctorCriticalAlerts() async {
    final res = await http.get(
      Uri.parse("$baseUrl/alerts/critical"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load critical alerts");
    }
  }
}