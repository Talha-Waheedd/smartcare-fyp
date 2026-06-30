import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_theme.dart';
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
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading      = false;
  bool _obscurePass    = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _errorMsg = null; });
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);

      final doc = await FirebaseFirestore.instance
          .collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        setState(() => _errorMsg = 'Account data not found. Contact support.');
        return;
      }

      final data     = doc.data() as Map<String, dynamic>;
      final isActive = data['isActive'];
      if (isActive == false) {
        await FirebaseAuth.instance.signOut();
        setState(() => _errorMsg = 'Account deactivated. Contact admin.');
        return;
      }

      final role = (data['role'] as String?) ?? 'patient';
      if (!mounted) return;

      Widget destination;
      if (role == 'doctor')      destination = const DoctorScreen();
      else if (role == 'admin')  destination = const AdminScreen();
      else                       destination = const PatientScreen();

      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => destination), (_) => false);

    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':     _errorMsg = 'No account found with this email'; break;
          case 'wrong-password':     _errorMsg = 'Incorrect password'; break;
          case 'invalid-credential': _errorMsg = 'Incorrect email or password'; break;
          case 'too-many-requests':  _errorMsg = 'Too many attempts. Please wait'; break;
          default:                   _errorMsg = 'Login failed (${e.code})';
        }
      });
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await FirebaseAuth.instance.sendPasswordResetEmail(email: ctrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset link sent! Check your inbox.')));
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.loginHero),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - 24),
              child: Column(
                children: [
                  // ── TOP HERO SECTION ──────────────────────────────────
                  SizedBox(
                    height: size.height * 0.38,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Floating background healthcare icons (10% opacity)
                        Positioned(
                          top: 30,
                          left: 24,
                          child: Icon(Icons.favorite,
                              size: 40,
                              color: Colors.white.withOpacity(0.10)),
                        ),
                        Positioned(
                          top: 90,
                          right: 30,
                          child: Icon(Icons.medication_rounded,
                              size: 52,
                              color: Colors.white.withOpacity(0.10)),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 40,
                          child: Icon(Icons.monitor_heart_rounded,
                              size: 44,
                              color: Colors.white.withOpacity(0.10)),
                        ),
                        // Logo + wordmark
                        Center(
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                AppLogo(size: AppLogoSize.large),
                                SizedBox(height: 18),
                                AppLogoText(
                                  fontSize: 32,
                                  subtitle: 'Your Personal Health Assistant',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BOTTOM CARD SECTION ───────────────────────────────
                  Expanded(
                    child: SlideInUp(
                      duration: const Duration(milliseconds: 500),
                      from: 120,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome Back',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('Sign in to continue',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                            const SizedBox(height: 24),

                            // Error banner
                            if (_errorMsg != null) ...[
                              FadeIn(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppColors.error,
                                      AppColors.error.withOpacity(0.8),
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(_errorMsg!,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13))),
                                  ]),
                                ),
                              ),
                            ],

                            // Email
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon:
                                    Icon(Icons.email_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePass,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                              ),
                            ),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPassword,
                                child: const Text('Forgot Password?',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Login button
                            GradientButton(
                              label: 'Sign In',
                              loading: _isLoading,
                              onPressed: _isLoading ? null : _login,
                            ),

                            const SizedBox(height: 20),

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ",
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen())),
                                  child: const Text('Register',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Doctors: Contact your administrator for access.',
                                style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}