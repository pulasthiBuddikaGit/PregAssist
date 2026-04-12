// import 'package:flutter/foundation.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// /// Service for interacting with Google Gemini AI API.
// /// Specialized in pregnancy mental health support.
// class GeminiService {
//   static const String _apiKey = 'AIzaSyDf7zQZTkNR24c1XkYsLATV0-an6poH7Ig';

//   late final GenerativeModel _model;
//   late final ChatSession _chat;

//   GeminiService() {
//     _model = GenerativeModel(
//       model: 'gemini-pro',
//       apiKey: _apiKey,
//       systemInstruction: Content.system(
//         'You are a compassionate maternal mental health assistant named මාතෘ. '
//         'You specialize in supporting pregnant women with their emotional and mental health during pregnancy. '
//         'You provide empathetic support, mental wellness guidance, and evidence-based advice specifically for pregnancy-related concerns. '
//         'You only respond to pregnancy-related mental health questions. '
//         'If asked about unrelated topics, gently redirect the conversation back to maternal mental health support. '
//         'Keep your responses warm, concise (2-3 sentences), and supportive. '
//         'Never use markdown formatting in your responses.',
//       ),
//     );

//     _chat = _model.startChat();
//   }

//   /// Send a message to the AI and get a response.
//   /// Returns null if there's an error.
//   Future<String?> sendMessage(String message) async {
//     try {
//       debugPrint('GeminiService: Sending message: $message');

//       final response = await _chat.sendMessage(Content.text(message));
//       final text = response.text?.trim();

//       if (text == null || text.isEmpty) {
//         debugPrint('GeminiService: Empty response from API');
//         return _getFallbackResponse();
//       }

//       debugPrint('GeminiService: Received response (${text.length} chars)');
//       return text;
//     } catch (e) {
//       debugPrint('GeminiService: Error sending message: $e');
//       return _getFallbackResponse();
//     }
//   }

//   String _getFallbackResponse() {
//     return "I'm here to support you. Could you tell me more about how you're feeling today? 💛";
//   }
// }
