import 'package:flutter/material.dart';
import '../../main.dart'; // AuthLocal

class DoctorPanelScreen extends StatelessWidget {
  const DoctorPanelScreen({super.key});

  void _openNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/app/doctor/notifications');
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthLocal.clearSession();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
    }
  }

  void _notAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is not available yet")),
    );
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
            "Doctor Panel",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: "Notifications",
              onPressed: () => _openNotifications(context),
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
            IconButton(
              tooltip: "Logout",
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Select a feature",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Quick access to doctor tools",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,

                    // ✅ Make tiles taller to avoid overflow on smaller screens
                    childAspectRatio: 0.88,

                    children: [
                      _FeatureTile(
                        title: "CTG Assessment",
                        subtitle: "Fetal health classification",
                        icon: Icons.monitor_heart,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
                        ),
                        onTap: () => Navigator.pushNamed(context, '/app/doctor/ctg'),
                      ),
                      _FeatureTile(
                        title: "Patient Details",
                        subtitle: "View patient profiles",
                        icon: Icons.people_alt,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF51A2FF), Color(0xFF00D2F2)],
                        ),
                        onTap: () => _notAvailable(context, "Patient Details"),
                      ),
                      _FeatureTile(
                        title: "Medical Reports",
                        subtitle: "Reports & history",
                        icon: Icons.description,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF637E), Color(0xFFFF8904)],
                        ),
                        onTap: () => _notAvailable(context, "Medical Reports"),
                      ),
                      _FeatureTile(
                        title: "Notifications",
                        subtitle: "Patient physical health alerts",
                        icon: Icons.notifications_active,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00B894), Color(0xFF0984E3)],
                        ),
                        onTap: () => _openNotifications(context),
                      ),
                      _FeatureTile(
                        title: "Logout",
                        subtitle: "Switch account / role",
                        icon: Icons.logout,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFDD2476), Color(0xFFFB5938)],
                        ),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.75),
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12), // slightly reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),

              // ✅ Prevent text from growing vertically and causing overflow
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),

              const Spacer(),

              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
