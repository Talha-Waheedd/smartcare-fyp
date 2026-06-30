import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:animate_do/animate_do.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_screen.dart';
import 'screens/doctor/doctor_screen.dart';
import 'screens/admin/admin_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartCare',
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }
        final uid = authSnapshot.data!.uid;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }
            final data = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (data == null) {
              return const LoginScreen();
            }
            if (data['isActive'] == false) {
              return const _InactiveUserRedirect();
            }
            final role = (data['role'] as String?) ?? 'patient';
            if (role == 'doctor') return const DoctorScreen();
            if (role == 'admin') return const AdminScreen();
            return const PatientScreen();
          },
        );
      },
    );
  }
}

/// Signs out deactivated users and returns to login.
class _InactiveUserRedirect extends StatefulWidget {
  const _InactiveUserRedirect();

  @override
  State<_InactiveUserRedirect> createState() => _InactiveUserRedirectState();
}

class _InactiveUserRedirectState extends State<_InactiveUserRedirect> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppGradients.loginHero),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Decorative pulse rings + logo + wordmark ──────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _PulseRing(
                              size: 160,
                              duration: const Duration(milliseconds: 2200)),
                          _PulseRing(
                              size: 130,
                              duration: const Duration(milliseconds: 1800),
                              delay: const Duration(milliseconds: 400)),
                          ElasticIn(
                            duration: const Duration(milliseconds: 1100),
                            child: const AppLogo(size: AppLogoSize.large),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                      child: const AppLogoText(fontSize: 34),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 600),
                      child: Text('AI Powered Health Assistant',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w300)),
                    ),
                  ],
                ),
              ),

              // ── Thin gradient loading line at the bottom ──────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: FadeIn(
                  delay: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppGradients.button,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Loading...',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12)),
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

/// Decorative expanding/fading ring used purely for splash visuals.
class _PulseRing extends StatefulWidget {
  final double size;
  final Duration duration;
  final Duration delay;
  const _PulseRing({
    required this.size,
    required this.duration,
    this.delay = Duration.zero,
  });

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.size * (0.7 + 0.3 * t),
          height: widget.size * (0.7 + 0.3 * t),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity((1 - t) * 0.4),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
