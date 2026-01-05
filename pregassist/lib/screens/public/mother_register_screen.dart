import 'package:flutter/material.dart';

class MotherRegisterScreen extends StatefulWidget {
  const MotherRegisterScreen({super.key});

  @override
  State<MotherRegisterScreen> createState() => _MotherRegisterScreenState();
}

class _MotherRegisterScreenState extends State<MotherRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _doctorSearchCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weekCtrl = TextEditingController();

  bool _submitting = false;

  // Demo doctor list (later you can load from local DB or backend)
  final List<String> _doctors = const [
    "Dr. Nimal Perera (SLMC 12345)",
    "Dr. Sanduni Jayasinghe (SLMC 33441)",
    "Dr. Kavindu Fernando (SLMC 90871)",
    "Dr. Iresha Silva (SLMC 55102)",
    "Dr. Tharindu Gunasekara (SLMC 77220)",
  ];

  String? _selectedDoctor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _doctorSearchCtrl.dispose();
    _ageCtrl.dispose();
    _weekCtrl.dispose();
    super.dispose();
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

  String? _required(String? v, String name) {
    if ((v ?? '').trim().isEmpty) return "$name is required";
    return null;
  }

  String? _emailValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "Email is required";
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(value);
    if (!ok) return "Enter a valid email";
    return null;
  }

  String? _intRangeValidator(String? v, String label, int min, int max) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return "$label is required";
    final n = int.tryParse(value);
    if (n == null) return "Enter a valid number";
    if (n < min || n > max) return "$label must be between $min and $max";
    return null;
  }

  Future<void> _pickDoctor() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = _doctorSearchCtrl.text;

        List<String> filtered() {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return _doctors;
          return _doctors.where((d) => d.toLowerCase().contains(q)).toList();
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final list = filtered();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select Assigned Doctor",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _doctorSearchCtrl,
                      onChanged: (v) => setModalState(() => query = v),
                      decoration: InputDecoration(
                        hintText: "Search doctor name or SLMC…",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text("No doctors found"))
                          : ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final d = list[index];
                                final selected = d == _selectedDoctor;

                                return ListTile(
                                  title: Text(d),
                                  trailing: selected
                                      ? const Icon(Icons.check_circle, color: Color(0xFF2B80FF))
                                      : const Icon(Icons.circle_outlined, color: Colors.black26),
                                  onTap: () => Navigator.pop(context, d),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDoctor = picked;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an assigned doctor")),
      );
      return;
    }

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
            "Mother Registration",
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
                          "Create your mother account",
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
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Email", icon: Icons.email),
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 12),

                        // Assigned Doctor picker (looks like a form field)
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickDoctor,
                          child: InputDecorator(
                            decoration: _inputDecoration(
                              label: "Assigned Doctor",
                              icon: Icons.medical_services,
                              suffix: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _selectedDoctor ?? "Tap to search and select",
                              style: TextStyle(
                                color: _selectedDoctor == null ? Colors.black45 : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _ageCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(label: "Age", icon: Icons.cake),
                          validator: (v) => _intRangeValidator(v, "Age", 12, 60),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _weekCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(label: "Pregnant Week", icon: Icons.calendar_month),
                          validator: (v) => _intRangeValidator(v, "Pregnant Week", 1, 45),
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
