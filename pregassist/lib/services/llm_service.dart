import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Free-tier Groq API service using Llama 3.3 70B model.
/// Specialized for pregnancy emotional assessment through guided questions.
///
/// Get your free API key at: https://console.groq.com
class LlmService {
  // ── Config ─────────────────────────────────────────────────────────────────
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile'; // stable free model

  static const String _systemPrompt =
      'You are Mātrā, a warm and compassionate AI companion dedicated to supporting pregnant women\'s emotional wellbeing. '
      'Your role is to gently assess the emotional state of a pregnant woman through natural caring conversation. '
      'Ask ONE meaningful emotional question per turn. '
      'Rotate through these themes: current mood, anxiety about birth or baby health, joy and love for baby, body image, support from family or partner, sleep and energy, fears about motherhood, stress this week, gratitude. '
      'question must be simple not going to be 2 line more'
      'Rules: '
      '1. Ask only one question per response. '
      '2. Keep responses to 2 to 3 warm supportive sentences maximum. '
      '3. Acknowledge the user\'s previous message with empathy before asking the next question. '
      '4. Never use markdown bullet points asterisks or special formatting. '
      '5. Never give medical advice or diagnose anything. '
      '6. If the user seems distressed respond with extra compassion and gently suggest speaking with their healthcare provider. '
      '7. Do NOT repeat the same question twice in one session.';

  // ── Conversation history (only real user↔assistant turns) ──────────────────
  final List<Map<String, String>> _history = [];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the opening greeting from the LLM.
  /// Does NOT add a fake user message to history.
  Future<String?> getInitialGreeting() async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      // Seed with an assistant prompt so the LLM produces the opening line
      {
        'role': 'user',
        'content':
            'Please start the session with a warm greeting and ask me how I am feeling today.',
      },
    ];

    try {
      final reply = await _callApi(messages);
      if (reply != null) {
        // Add to history as the first assistant turn so context is maintained
        _history.add({'role': 'assistant', 'content': reply});
      }
      return reply;
    } catch (e) {
      debugPrint('LlmService.getInitialGreeting error: $e');
      return _fallback();
    }
  }

  /// Send a user message and get the next empathetic question/response.
  Future<String?> sendMessage(String userMessage, {String? mood}) async {
    String finalUserContent = userMessage;
    if (mood != null && mood.isNotEmpty) {
      finalUserContent = '[Captured Mood: $mood] $userMessage';
    }

    _history.add({'role': 'user', 'content': finalUserContent});

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];

    try {
      final reply = await _callApi(messages);
      if (reply != null) {
        _history.add({'role': 'assistant', 'content': reply});
      } else {
        // Remove the user turn we added so history stays consistent
        _history.removeLast();
      }
      return reply ?? _fallback();
    } catch (e) {
      debugPrint('LlmService.sendMessage error: $e');
      _history.removeLast();
      return _fallback();
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<String?> _callApi(List<Map<String, String>> messages) async {
    final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': 160,
            'temperature': 0.75,
          }),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint('LlmService: HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = (data['choices'][0]['message']['content'] as String).trim();
      // Strip <think>…</think> tags emitted by some reasoning models
      final cleaned = raw
          .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
          .trim();
      debugPrint('LlmService: reply → $cleaned');
      return cleaned.isEmpty ? null : cleaned;
    } else {
      debugPrint('LlmService: error body → ${response.body}');
      return null;
    }
  }

  String _fallback() => "I'm here for you. How are you feeling right now? 💛";
}
