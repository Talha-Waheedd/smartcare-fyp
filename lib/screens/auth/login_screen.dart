import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import '../patient/patient_screen.dart';
import '../doctor/doctor_screen.dart';
import '../admin/admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Please enter email and password");
      return;
    }

    if (!email.contains('@')) {
      _showSnack("Enter a valid email address");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Step 1: Sign in with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Fetch Firestore document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showSnack("Account data not found. Please contact support.");
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        return;
      }

      // ✅ FIX: Use safe null-aware access instead of direct map access
      // Direct access like userDoc['isActive'] throws if field doesn't exist
      final data = userDoc.data() as Map<String, dynamic>;
      final isActive = data['isActive'];   // returns null if field missing

      // Only block if explicitly set to false — null means old account, allow it
      if (isActive == false) {
        _showSnack("Your account has been deactivated. Contact admin.");
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        return;
      }

      // Step 3: Get role safely
      final role = (data['role'] as String?) ?? 'patient';

      if (!mounted) return;

      // Step 4: Route to dashboard
      if (role == 'doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorScreen()),
        );
      } else if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email";
          break;
        case 'wrong-password':
          message = "Incorrect password. Please try again";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        case 'invalid-credential':
          // Firebase v4+ uses this code for wrong email/password combination
          message = "Incorrect email or password";
          break;
        case 'user-disabled':
          message = "This account has been disabled";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please wait and try again";
          break;
        default:
          message = "Login failed (${e.code})";
      }
      _showSnack(message);
    } catch (e) {
      // Show the actual error in debug so you can see what's happening
      debugPrint("Login error: $e");
      _showSnack("Error: ${e.toString()}");  // Temporarily show real error
    }

    if (mounted) setState(() => isLoading = false);
  }

  void showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email to receive a reset link."),
            const SizedBox(height: 12),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final resetEmail = resetEmailController.text.trim();
              if (resetEmail.isEmpty) return;
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: resetEmail);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnack("Reset email sent! Check your inbox.");
                }
              } catch (e) {
                _showSnack("Could not send reset email.");
              }
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SmartCare Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.health_and_safety, size: 64, color: Colors.blue),
            const SizedBox(height: 8),
            const Text(
              "SmartCare",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: showForgotPasswordDialog,
                child: const Text("Forgot Password?"),
              ),
            ),
            const SizedBox(height: 8),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text("Don't have an account? Register"),
            ),
            const SizedBox(height: 8),
            const Text(
              "Doctors: Contact your administrator for account access.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}