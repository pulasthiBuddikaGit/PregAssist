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
      'xai-D1tgKZQ7O7X7tixQGai31Nu8dIcV840oosFpKAp2RsyKUc5ea31WbqGlfLtyV3Iv4LB33O7UKgJaDQfv';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile'; // stable free model

  static const String _systemPrompt =
      'You are Mathru, a warm and compassionate AI companion who emotionally supports pregnant women. '
      'Your purpose is to gently understand the emotional wellbeing of the user through natural caring conversation. '
      'Speak like a supportive friend who listens carefully and responds with empathy. '
      'Conversation behavior: '
      'Always acknowledge the user\'s previous message with empathy before asking the next question. '
      'Ask only ONE simple emotional question per response. '
      'Keep responses short: 2 to 3 warm sentences maximum. '
      'Rotate naturally between these emotional themes without repeating them in the same session: '
      'current mood, anxiety about birth, baby health concerns, joy and love for the baby, body image changes during pregnancy, '
      'support from partner or family, sleep and energy levels, fears about becoming a mother, stress experienced this week, and gratitude moments. '
      'Question rules: '
      'The question must be short and simple (one sentence only). '
      'Avoid long or complex questions. '
      'Safety rules: '
      'Never give medical advice, diagnosis, or treatment. '
      'If the user sounds very distressed, respond with extra compassion and gently suggest talking with a healthcare provider or trusted person. '
      'Tone: Warm, calm, caring, and reassuring. Avoid sounding robotic or clinical. '
      'Formatting rules: Do not use bullet points, markdown, symbols, or special formatting. Write naturally like a caring conversation. '
      'Goal: Create a safe emotional space where pregnant women feel heard, supported, and comfortable sharing their feelings.';

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
    final response = await http
        .post(
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
