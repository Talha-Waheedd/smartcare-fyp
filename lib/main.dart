import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety_rounded,
                  size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('SmartCare',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            const Text('AI Powered Health Assistant',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}