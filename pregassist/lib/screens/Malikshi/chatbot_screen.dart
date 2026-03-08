import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/camera_service.dart';
import '../../services/emotion_service.dart';
import '../../services/llm_service.dart';
import '../../models/Malikshi/emotion_record.dart';

class Message {
  final int id;
  final String text;
  final String sender;
  final DateTime timestamp;
  String? emotion;
  double? confidence;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.emotion,
    this.confidence,
  });
}

class ChatbotScreen extends StatefulWidget {
  final Function(List<EmotionRecord>) onComplete;
  final VoidCallback? onBack;

  const ChatbotScreen({super.key, required this.onComplete, this.onBack});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Message> _messages = [];
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  int _messageCount = 0;

  // Camera state
  bool _cameraEnabled = true;
  bool _cameraInitializing = false;
  final CameraService _cameraService = CameraService();

  // AI state
  final LlmService _llmService = LlmService();

  // Emotion tracking
  final List<EmotionRecord> _emotionRecords = [];
  int _emotionIndex = 0;

  /// Capture snapshot and call image emotion API.
  Future<Object?> _captureAndDetectImage() async {
    if (!_cameraEnabled || !_cameraService.isInitialized) return null;
    try {
      final base64Image = await _cameraService.captureSnapshot();
      if (base64Image == null) return null;
      return await EmotionService.detectImageEmotion(base64Image);
    } catch (e) {
      debugPrint('ChatbotScreen: image emotion detection failed: $e');
      return null;
    }
  }

  void _showGenderBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE4E4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block, color: Color(0xFFDC2626), size: 36),
        ),
        title: const Text(
          'Access Restricted',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF991B1B),
          ),
        ),
        content: const Text(
          'This app is designed exclusively for women.\n\nYou cannot continue. Please go back.\n\nYou can decide to leave or try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF7F1D1D),
            height: 1.6,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              if (widget.onBack != null) {
                widget.onBack!();           // go back
              }
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Run text + image emotion detection in parallel, combine, and update message.
  Future<String?> _detectAndRecordEmotion(
    String text,
    int msgId,
    int msgIndex,
  ) async {
    final results = await Future.wait([
      EmotionService.detectTextEmotion(text),
      _captureAndDetectImage(),
    ]);

    // Check if gender was blocked
    final imageResult = results[1];
    if (imageResult is GenderBlockedResult) {
      if (mounted) _showGenderBlockedDialog();
      return null;
    }

    final combined = EmotionService.combine(
      results[0] as EmotionResult?,
      imageResult as EmotionResult?,
    );
    if (combined == null || !mounted) return null;

    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        _messages[idx].emotion = combined.emotion;
        _messages[idx].confidence = combined.confidence;
      }
    });

    _emotionRecords.add(
      EmotionRecord(
        messageIndex: msgIndex,
        emotionLabel: combined.emotion,
        confidence: combined.confidence / 100,
        timestamp: DateTime.now(),
        source: 'combined',
      ),
    );
    return combined.emotion;
  }

  @override
  void initState() {
    super.initState();
    _sendInitialMessage();
    _requestCameraPermission();
  }

  void _sendInitialMessage() {
    // Show a loading placeholder while the LLM generates the greeting
    setState(() {
      _messages.add(
        Message(
          id: 1,
          text: '...',
          sender: 'bot',
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _llmService.getInitialGreeting().then((greeting) {
      if (!mounted) return;
      setState(() {
        _messages[0] = Message(
          id: 1,
          text: greeting ??
              "Hello! 👋 I'm Mātrā, your pregnancy companion. How are you feeling today?",
          sender: 'bot',
          timestamp: DateTime.now(),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  // ─── Camera Methods ───

  Future<void> _requestCameraPermission() async {
    try {
      if (kIsWeb) {
        await _initializeCamera();
        return;
      }

      final status = await Permission.camera.request();
      if (!mounted) return;

      if (status.isGranted) {
        await _initializeCamera();
      } else {
        debugPrint('ChatbotScreen: Camera permission denied');
        if (mounted) {
          setState(() {
            _cameraEnabled = false;
          });
        }
      }
    } catch (e) {
      debugPrint('ChatbotScreen: Error requesting camera permission: $e');
      if (mounted) {
        setState(() {
          _cameraEnabled = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraInitializing) return;
    setState(() {
      _cameraInitializing = true;
    });

    try {
      final success = await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _cameraInitializing = false;
          _cameraEnabled = success;
        });
      }
    } catch (e) {
      debugPrint('ChatbotScreen: Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraInitializing = false;
          _cameraEnabled = false;
        });
      }
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _cameraService.dispose();
    } catch (e) {
      debugPrint('ChatbotScreen: Error stopping camera: $e');
    }
    if (mounted) {
      setState(() {
        _cameraEnabled = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameraInitializing) return;

    if (_cameraEnabled && _cameraService.isInitialized) {
      await _stopCamera();
    } else {
      setState(() {
        _cameraEnabled = true;
      });
      await _requestCameraPermission();
    }
  }

  // ─── Chat Methods ───

  String _emotionEmoji(String emotion) {
    switch (emotion) {
      case 'Happy':
        return '😊';
      case 'Sad':
        return '😢';
      case 'Anger':
        return '😠';
      case 'Fear':
        return '😨';
      default:
        return '😐';
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSend() async {
    if (_messageController.text.trim().isEmpty) return;

    final userText = _messageController.text.trim();
    _messageController.clear();

    final msgId = _messages.length + 1;
    final msgIndex = _emotionIndex++;

    setState(() {
      _messages.add(
        Message(
          id: msgId,
          text: userText,
          sender: 'user',
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
      _messageCount++;
    });
    _scrollToBottom();

    // Detect emotion from text + camera in parallel
    final detectedMood = await _detectAndRecordEmotion(userText, msgId, msgIndex);

    // Get LLM response (next empathetic question)
    _llmService.sendMessage(userText, mood: detectedMood).then((aiResponse) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          Message(
            id: _messages.length + 1,
            text:
                aiResponse ??
                "I'm here to support you. Could you tell me more about how you're feeling? 💛",
            sender: 'bot',
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  // ─── Build Methods ───

  @override
  Widget build(BuildContext context) {
    final bool cameraActive = _cameraEnabled && _cameraService.isInitialized;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(cameraActive),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
                  if (cameraActive) _buildCameraPreviewIndicator(),
                  if (_messageCount >= 3) _buildContinueButton(),
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool cameraActive) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Row(
            children: [
              if (widget.onBack != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'මාතෘ Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Mental Health Support',
                      style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                    ),
                  ],
                ),
              ),
              // Camera toggle icon
              GestureDetector(
                onTap: _toggleCamera,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cameraActive
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cameraActive
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: _cameraInitializing
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          cameraActive
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          color: Colors.white.withValues(
                            alpha: cameraActive ? 1.0 : 0.5,
                          ),
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreviewIndicator() {
    return Positioned(
      bottom: 12,
      left: 12,
      child: GestureDetector(
        onTap: _toggleCamera,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF3B82F6), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraService.controller != null)
                  CameraPreview(_cameraService.controller!),
                const Positioned(top: 4, right: 4, child: _PulsingDot()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => widget.onComplete(_emotionRecords),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'End Chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Message message) {
    final isUser = message.sender == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFF60A5FA),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 8),
                        if (message.emotion != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_emotionEmoji(message.emotion!)} ${message.emotion} ${message.confidence?.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white54,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildDot(),
                const SizedBox(width: 8),
                _buildDot(),
                const SizedBox(width: 8),
                _buildDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF60A5FA),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// ─── Pulsing Dot ───

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
