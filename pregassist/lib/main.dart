import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Protected shells / existing screens
import 'screens/common/main_wrapper.dart';

// You already have these:
import 'screens/pulasthi/ctg_segment_screen.dart';
import 'models/pulasthi/assessment_data.dart';

// New public flow screens (create these files below)
import 'screens/public/welcome_screen.dart';
import 'screens/public/doctor_register_screen.dart';
import 'screens/public/mother_register_screen.dart';
import 'screens/public/login_screen.dart';

// New doctor area (placeholder screen below)
import 'screens/pulasthi/doctor_panel_screen.dart';

import 'screens/Malikshi/chatbot_screen.dart';
import 'screens/Malikshi/emotion_graph_screen.dart';
import 'screens/Malikshi/score_screen.dart';
import 'screens/Malikshi/suggestion_screen.dart';
import 'screens/Malikshi/summary_screen.dart';
import 'screens/Malikshi/trusted_person_screen.dart';
import 'screens/common/home_screen.dart';
import 'screens/common/dashboard_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/nisalka/emergency_dashboard.dart';
import 'services/malikshi_data_service.dart';

void main() {
  runApp(const MyApp());
}

/// -------------------------
/// Simple Offline Session API
/// -------------------------
class AuthSession {
  final bool isLoggedIn;
  final String? role; // 'doctor' | 'mother'

  AuthSession({required this.isLoggedIn, required this.role});
}

class AuthLocal {
  static const _kLoggedIn = 'isLoggedIn';
  static const _kRole = 'role';

  static Future<AuthSession> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_kLoggedIn) ?? false;
    final role = prefs.getString(_kRole);
    return AuthSession(isLoggedIn: isLoggedIn, role: role);
  }

  static Future<void> setSession({required bool isLoggedIn, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, isLoggedIn);
    await prefs.setString(_kRole, role);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kRole);
  }
}

/// -------------------------
/// App
/// -------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Keep one shared instance for CTG screens
  final AssessmentData _assessmentData = AssessmentData();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PregAssist',
      theme: ThemeData(primarySwatch: Colors.blue),

      // Always start at Gate
      initialRoute: '/',

      // Public routes (no guard needed)
      routes: {
        '/': (context) => const AuthGate(),
        '/welcome': (context) => const WelcomeScreen(),
        '/register/doctor': (context) => const DoctorRegisterScreen(),
        '/register/mother': (context) => const MotherRegisterScreen(),

        // Login is public; after login we redirect based on role
        '/login': (context) => const LoginScreen(),
      },

      // Guard protected routes here:
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';

        // PROTECTED: everything under /app/*
        final isProtected = name.startsWith('/app/');

        if (!isProtected) return null; // let `routes:` handle

        // We return a guarded route that decides where to go
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            return FutureBuilder<AuthSession>(
              future: AuthLocal.getSession(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const _Splash();
                }

                final session = snap.data!;
                final role = session.role;

                // Not logged in -> kick to welcome
                if (!session.isLoggedIn || role == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
                  });
                  return const _Splash();
                }

                // Role-based route protection:
                final isDoctorRoute = name.startsWith('/app/doctor');
                final isMotherRoute = name.startsWith('/app/mother');

                if (isDoctorRoute && role != 'doctor') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushNamedAndRemoveUntil(context, '/app/mother', (_) => false);
                  });
                  return const _Splash();
                }

                if (isMotherRoute && role != 'mother') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushNamedAndRemoveUntil(context, '/app/doctor', (_) => false);
                  });
                  return const _Splash();
                }

                final malikshiData = MalikshiDataService();

                // ✅ Allowed -> return actual protected screen
                switch (name) {
                  case '/app/mother':
                  case '/app/mother/home':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: HomeScreen(
                        onStartChat: () => Navigator.pushNamed(context, '/app/mother/chat'),
                      ),
                    );
                  case '/app/mother/chat':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: ChatbotScreen(
                        onComplete: (records) {
                          malikshiData.currentRecords = records;
                          Navigator.pushNamed(context, '/app/mother/graph');
                        },
                        onBack: () => Navigator.pushNamed(context, '/app/mother/home'),
                      ),
                    );
                  case '/app/mother/dashboard':
                    return MainWrapper(
                      selectedIndex: 1,
                      child: const DashboardScreen(motherId: "test@email.com"),
                    );
                  case '/app/mother/graph':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: EmotionGraphScreen(
                        emotionRecords: malikshiData.currentRecords,
                        onStartNew: () => Navigator.pushNamed(context, '/app/mother/chat'),
                        onBack: () => Navigator.pushNamed(context, '/app/mother/chat'),
                        onViewExercises: () => Navigator.pushNamed(context, '/app/mother/score'),
                        onAlertTrustedPerson: () => Navigator.pushNamed(context, '/app/mother/trusted'),
                      ),
                    );
                  case '/app/mother/trusted':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: TrustedPersonScreen(
                        onContinue: () => Navigator.pushNamed(context, '/app/mother/graph'),
                        onBack: () => Navigator.pushNamed(context, '/app/mother/graph'),
                      ),
                    );
                  case '/app/mother/score':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: ScoreScreen(
                        score: malikshiData.calculateScore(),
                        onContinue: () {
                          final score = malikshiData.calculateScore();
                          if (score < 60) {
                            Navigator.pushNamed(context, '/app/mother/suggestions');
                          } else {
                            Navigator.pushNamed(context, '/app/mother/summary');
                          }
                        },
                        onBack: () => Navigator.pushNamed(context, '/app/mother/graph'),
                      ),
                    );
                  case '/app/mother/suggestions':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: SuggestionScreen(
                        onContinue: () => Navigator.pushNamed(context, '/app/mother/summary'),
                        onBack: () => Navigator.pushNamed(context, '/app/mother/score'),
                      ),
                    );
                  case '/app/mother/summary':
                    return MainWrapper(
                      selectedIndex: 0,
                      child: SummaryScreen(
                        score: malikshiData.calculateScore(),
                        onStartNew: () => Navigator.pushNamed(context, '/app/mother/chat'),
                        onBack: () => Navigator.pushNamed(context, '/app/mother/suggestions'),
                      ),
                    );
                  case '/app/mother/emergency':
                    return MainWrapper(
                      selectedIndex: 2,
                      child: EmergencyDashboard(),
                    );
                  case '/app/mother/profile':
                    return MainWrapper(
                      selectedIndex: 3,
                      child: ProfileScreen(),
                    );
                  case '/app/doctor':
                    return const DoctorPanelScreen();
                  case '/app/doctor/ctg':
                    return CTGSegmentScreen(data: _assessmentData);
                  default:
                    return const _NotFound();
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Gate: decides initial screen based on local session
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession>(
      future: AuthLocal.getSession(),
      builder: (context, snap) {
        if (!snap.hasData) return const _Splash();

        final session = snap.data!;
        if (!session.isLoggedIn || session.role == null) {
          // Not logged in -> public flow
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
          });
          return const _Splash();
        }

        // Logged in -> role-based home
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final role = session.role;
          final target = (role == 'doctor') ? '/app/doctor' : '/app/mother';
          Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
        });

        return const _Splash();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Route not found')),
    );
  }
}
