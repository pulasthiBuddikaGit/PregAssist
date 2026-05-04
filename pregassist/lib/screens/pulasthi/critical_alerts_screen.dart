import 'package:flutter/material.dart';
import '../dimalsha/maternal_model.dart';
import 'alert_detail_screen.dart';
import '../../utils/critical_alert_state.dart';

class CriticalAlertsScreen extends StatefulWidget {
  const CriticalAlertsScreen({super.key});

  @override
  State<CriticalAlertsScreen> createState() => _CriticalAlertsScreenState();
}

class _CriticalAlertsScreenState extends State<CriticalAlertsScreen> {
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Mark critical alerts as read — clear the badge everywhere
    criticalAlertState.value = false;
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      final alerts = await MaternalService.getDoctorCriticalAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load alerts. Ensure backend is running.";
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B80FF), Color(0xFFAC46FF)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: const Text(
          "Critical Alerts",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchAlerts();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_alerts.isEmpty) {
      return const Center(
        child: Text("No critical alerts at this time."),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final motherId = "M001";
          final dateStr = alert['createdAt'] != null
              ? _formatDate(alert['createdAt'])
              : _formatDate(DateTime.now().toIso8601String());
          final riskLevel =
              alert['risk_level']?.toString().toUpperCase() ?? 'HIGH RISK';

          final sbp = num.tryParse(alert['SystolicBP']?.toString() ?? '0') ?? 0;
          final dbp =
              num.tryParse(alert['DiastolicBP']?.toString() ?? '0') ?? 0;
          final bs = num.tryParse(alert['BS']?.toString() ?? '0') ?? 0;
          final hr = num.tryParse(alert['HeartRate']?.toString() ?? '0') ?? 0;

          String dynamicWarning = "Multiple elevated parameters detected.";
          if (sbp >= 140 || dbp >= 90) {
            dynamicWarning = "Hypertension Risk: High blood pressure detected.";
          } else if (bs >= 7.8) {
            dynamicWarning =
                "High Blood Sugar Alert: Elevated glucose levels detected.";
          } else if (hr >= 100) {
            dynamicWarning = "Elevated Heart Rate: Tachycardia risk detected.";
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            riskLevel,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateStr,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: const Icon(Icons.person, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mother ID",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              motherId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dynamicWarning,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlertDetailScreen(
                                alertData: alert as Map<String, dynamic>,
                                dynamicWarning: dynamicWarning,
                              ),
                            ),
                          );
                        },
                        child: const Text("View"),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
