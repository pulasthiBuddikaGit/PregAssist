import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustedPersonScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const TrustedPersonScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<TrustedPersonScreen> createState() => _TrustedPersonScreenState();
}

class _TrustedPersonScreenState extends State<TrustedPersonScreen> {
  final _phoneController = TextEditingController();
  bool _isValid = false;
  bool _isSending = false;

  static const String _whatsAppMessage =
      'Hi 💛 I am using the MomCare pregnancy support app. '
      'My emotional health check just flagged that I may be going through a difficult time right now. '
      'I would really appreciate your support. Could you please check on me when you get a chance? '
      'Thank you for being someone I can trust. 🙏';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone(String value) {
    // Allow digits, spaces, dashes, plus sign
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    setState(() {
      _isValid = digits.length >= 7;
    });
  }

  String _cleanPhone(String raw) {
    // Remove everything except digits and leading +
    final stripped = raw.replaceAll(RegExp(r'[^\d+]'), '');
    // Remove leading + for wa.me URL (it expects digits only)
    return stripped.replaceAll('+', '');
  }

  Future<void> _sendWhatsApp() async {
    if (!_isValid || _isSending) return;
    setState(() => _isSending = true);

    final phone = _cleanPhone(_phoneController.text.trim());
    final encoded = Uri.encodeComponent(_whatsAppMessage);
    final url = Uri.parse('https://wa.me/$phone?text=$encoded');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // After launching WhatsApp, go back to the graph
        if (mounted) widget.onContinue();
      } else {
        _showError('WhatsApp is not installed on this device.');
      }
    } catch (e) {
      _showError('Could not open WhatsApp. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFAF5FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon + Title ───────────────────────────────────────
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 40,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Alert Trusted Person',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your emotional check indicates you may need support right now. '
                        'Enter a trusted person\'s WhatsApp number and we\'ll send them a message on your behalf.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF2563EB),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── High-Risk Badge ────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'High emotional risk detected — reaching out to someone you trust can help.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF991B1B),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Phone Input ────────────────────────────────────────
                      const Text(
                        'WhatsApp Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isValid
                                ? const Color(0xFF10B981)
                                : const Color(0xFFBFDBFE),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: _validatePhone,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: '+94 77 123 4567',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image(
                                image: const AssetImage(
                                  'assets/images/whatsapp_icon.png',
                                ),
                                width: 24,
                                height: 24,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.chat_rounded,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Include country code, e.g. +94 for Sri Lanka',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Message Preview ────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Message Preview',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _whatsAppMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF166534),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Send Button ────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isValid
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF25D366),
                                      Color(0xFF128C7E),
                                    ],
                                  )
                                : null,
                            color: _isValid ? null : Colors.grey[300],
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: _isValid
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF25D366,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                (_isValid && !_isSending) ? _sendWhatsApp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            icon: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            label: Text(
                              _isSending ? 'Opening WhatsApp...' : 'Send WhatsApp Alert',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Skip ──────────────────────────────────────────────
                      Center(
                        child: TextButton(
                          onPressed: widget.onContinue,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

