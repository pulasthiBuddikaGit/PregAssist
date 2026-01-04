import 'package:flutter/material.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regNoCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _hidePw = true;
  bool _hidePw2 = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _regNoCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // TODO: Save locally / send to backend later
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration saved. Please login.")),
    );

    Navigator.pushNamed(context, '/login');
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2B80FF), width: 1.5),
      ),
    );
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Email is required";
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value);
    if (!ok) return "Enter a valid email";
    return null;
  }

  String? _required(String? v, String name) {
    if ((v ?? '').trim().isEmpty) return "$name is required";
    return null;
  }

  String? _mobileValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Mobile No is required";
    // Sri Lanka numbers commonly 9/10 digits; keep it simple:
    final digits = value.replaceAll(RegExp(r"\D"), "");
    if (digits.length < 9) return "Enter a valid mobile number";
    return null;
  }

  String? _pwValidator(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return "Password is required";
    if (value.length < 6) return "Use at least 6 characters";
    return null;
  }

  String? _pw2Validator(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return "Confirm password";
    if (value != _pwCtrl.text) return "Passwords do not match";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
            Color(0xFFDBEAFE),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B80FF),
                  Color(0xFFAC46FF),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          title: const Text(
            "Doctor Registration",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Create your doctor account",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Enter your details to register.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Name", icon: Icons.person),
                          validator: (v) => _required(v, "Name"),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _nicCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "NIC", icon: Icons.badge),
                          validator: (v) => _required(v, "NIC"),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _mobileCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Mobile No", icon: Icons.phone),
                          validator: _mobileValidator,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Email", icon: Icons.email),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _regNoCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Reg No", icon: Icons.verified),
                          validator: (v) => _required(v, "Reg No"),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _pwCtrl,
                          obscureText: _hidePw,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: "Password",
                            icon: Icons.lock,
                            suffix: IconButton(
                              onPressed: () => setState(() => _hidePw = !_hidePw),
                              icon: Icon(_hidePw ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: _pwValidator,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _pw2Ctrl,
                          obscureText: _hidePw2,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            label: "Confirm Password",
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () => setState(() => _hidePw2 = !_hidePw2),
                              icon: Icon(_hidePw2 ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: _pw2Validator,
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2B80FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    "Register",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: const Text("Already registered? Login"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
