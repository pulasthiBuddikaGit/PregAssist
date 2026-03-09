import 'dart:convert';
import 'package:http/http.dart' as http;

class VitalsApi {
  static const String baseUrl = "https://pregassist-backend.onrender.com";

  static Future<List<Map<String, dynamic>>> getHistory({
    required String motherId,
    required String period, // "weekly" | "monthly"
  }) async {
    final url = Uri.parse("$baseUrl/vitals/history?motherId=$motherId&period=$period");
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to load history: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}