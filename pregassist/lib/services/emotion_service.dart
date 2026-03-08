import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmotionResult {
  final String emotion;
  final double confidence;

  EmotionResult({required this.emotion, required this.confidence});
}

/// Returned when the gender check blocks the request (not a woman).
class GenderBlockedResult {
  final String gender;
  final double confidence;
  GenderBlockedResult({required this.gender, required this.confidence});
}

class EmotionService {
  // Use 10.0.2.2 for Android emulator, or your machine's IP for a physical device.
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// Normalize text-model labels → image-model labels for consistency.
  static String _normalize(String textEmotion) {
    switch (textEmotion.toLowerCase()) {
      case 'happiness':
      case 'love':
        return 'Happy';
      case 'anger':
        return 'Anger';
      case 'sadness':
      case 'worry':
        return 'Sad';
      case 'surprise':
        return 'Neutral';
      default:
        return 'Neutral';
    }
  }

  /// Call `/detect_text` endpoint.
  static Future<EmotionResult?> detectTextEmotion(String text) async {
    try {
      final response = await http.post(
            Uri.parse('$baseUrl/detect_text'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmotionResult(
          emotion: _normalize(data['emotion'] as String),
          confidence: (data['confidence'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('EmotionService: detectTextEmotion failed: $e');
    }
    return null;
  }

  /// Call `/detect` endpoint with a base64 JPEG image.
  /// Returns [EmotionResult] on success, [GenderBlockedResult] if not a woman,
  /// or null on failure.
  static Future<Object?> detectImageEmotion(String base64Image) async {
    try {
      final bytes = base64Decode(base64Image);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: 'snapshot.jpg'),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmotionResult(
          emotion: data['Emotion'] as String,
          confidence: (data['confidence'] as num).toDouble(),
        );
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return GenderBlockedResult(
          gender: data['gender'] as String? ?? 'Men',
          confidence: (data['gender_confidence'] as num? ?? 0).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('EmotionService: detectImageEmotion failed: $e');
    }
    return null;
  }

  /// Combine text + image results — picks the one with higher confidence.
  /// Pass only [EmotionResult] instances (not GenderBlockedResult).
  static EmotionResult? combine(EmotionResult? text, EmotionResult? image) {
    if (text == null && image == null) return null;
    if (text == null) return image;
    if (image == null) return text;
    return text.confidence >= image.confidence ? text : image;
  }
}
