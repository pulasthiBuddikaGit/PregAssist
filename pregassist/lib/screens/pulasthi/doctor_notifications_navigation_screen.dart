import 'package:flutter/material.dart';
import 'critical_alerts_screen.dart';
import '../../utils/critical_alert_state.dart';

class DoctorNotificationsNavigationScreen extends StatelessWidget {
  const DoctorNotificationsNavigationScreen({super.key});

  void _showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$section UI is ready. Logic will be added soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: criticalAlertState,
      builder: (context, hasUnreadCriticalAlert, _) {
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
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Color(0xFF2B80FF), size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Doctor Notification Navigation',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Choose a notification section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      _NotificationNavTile(
                        title: 'Critical Alerts',
                        subtitle: 'High-priority patient health notifications',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFFF5F6D),
                        showBadge: hasUnreadCriticalAlert,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CriticalAlertsScreen()),
                          );
                        },
                      ),
                      _NotificationNavTile(
                        title: 'Vitals Watchlist',
                        subtitle: 'Track incoming physical health signals',
                        icon: Icons.monitor_heart,
                        color: const Color(0xFF00B894),
                        showBadge: false,
                        onTap: () =>
                            _showComingSoon(context, 'Vitals Watchlist'),
                      ),
                      _NotificationNavTile(
                        title: 'Medication Reminders',
                        subtitle: 'Upcoming medication and treatment reminders',
                        icon: Icons.medical_services_outlined,
                        color: const Color(0xFF2B80FF),
                        showBadge: false,
                        onTap: () =>
                            _showComingSoon(context, 'Medication Reminders'),
                      ),
                      _NotificationNavTile(
                        title: 'All Notifications',
                        subtitle: 'Open full list of doctor notifications',
                        icon: Icons.notifications_none,
                        color: const Color(0xFF7D5FFF),
                        showBadge: false,
                        onTap: () =>
                            _showComingSoon(context, 'All Notifications'),
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
      },
    );
  }
}

class _NotificationNavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool showBadge;
  final VoidCallback onTap;

  const _NotificationNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color),
                    ),

                    // 🔴 RED DOT — only when showBadge is true
                    if (showBadge)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
