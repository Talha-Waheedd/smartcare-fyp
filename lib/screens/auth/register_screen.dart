import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();        // NEW: name field
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); // NEW: confirm

  bool isLoading = false;
  bool obscurePassword = true;                           // NEW: show/hide toggle

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ── Validation ──────────────────────────────────────────────────────
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack("All fields are required");
      return;
    }

    if (name.length < 2) {
      _showSnack("Please enter your full name");
      return;
    }

    if (!email.contains('@')) {
      _showSnack("Enter a valid email address");
      return;
    }

    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Step 1: Create Firebase Auth account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Save user data in Firestore
      // Role is ALWAYS 'patient' for self-registration — doctors are added by Admin
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': name,           // Now saving name
        'email': email,
        'role': 'patient',      // Hard-coded — patients cannot choose their role
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _showSnack("Account created successfully!");

      // Go back to login screen
      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnack("This email is already registered");
      } else if (e.code == 'weak-password') {
        _showSnack("Password is too weak");
      } else {
        _showSnack("Registration failed: ${e.message}");
      }
    } catch (e) {
      _showSnack("Something went wrong. Please try again.");
    }

    setState(() => isLoading = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),

      body: SingleChildScrollView(   // Prevents overflow on small screens
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 20),

            // ── Full Name ────────────────────────────────────────────────
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            // ── Email ────────────────────────────────────────────────────
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

            // ── Password ─────────────────────────────────────────────────
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

            const SizedBox(height: 14),

            // ── Confirm Password ─────────────────────────────────────────
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Register Button ──────────────────────────────────────────
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Create Account", style: TextStyle(fontSize: 16)),
                  ),

            const SizedBox(height: 12),

            // ── Back to Login ────────────────────────────────────────────
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login"),
            ),

            // ── Medical disclaimer ───────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                "⚠️ SmartCare provides wellness suggestions only. "
                "It does not diagnose or prescribe. Always consult a doctor.",
                style: TextStyle(fontSize: 12, color: Colors.brown),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}