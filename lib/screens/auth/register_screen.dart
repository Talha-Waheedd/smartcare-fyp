import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _isLoading     = false;
  bool _obscurePass   = true;
  bool _obscureConf   = true;
  bool _acceptTerms   = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMsg = null);
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    final conf  = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || conf.isEmpty) {
      setState(() => _errorMsg = 'All fields are required');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMsg = 'Enter a valid email address');
      return;
    }
    if (pass.length < 8) {
      setState(() => _errorMsg = 'Password must be at least 8 characters');
      return;
    }
    if (pass != conf) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }
    if (!_acceptTerms) {
      setState(() => _errorMsg = 'Please accept the terms to continue');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      try {
        await FirebaseFirestore.instance
            .collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': name,
          'email': email,
          'role': 'patient',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } catch (e) {
        await cred.user!.delete();
        rethrow;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') _errorMsg = 'Email already registered';
        else if (e.code == 'weak-password')   _errorMsg = 'Password is too weak';
        else _errorMsg = 'Registration failed: ${e.message}';
      });
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    int order = 0;
    Widget staggered(Widget child) {
      final widget = FadeInUp(
        delay: Duration(milliseconds: 100 + (order * 50)),
        duration: const Duration(milliseconds: 400),
        from: 20,
        child: child,
      );
      order++;
      return widget;
    }

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
                  // ── TOP HERO (30%) ────────────────────────────────────
                  SizedBox(
                    height: size.height * 0.26,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                size: 20, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Center(
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                AppLogo(size: AppLogoSize.large),
                                SizedBox(height: 14),
                                AppLogoText(fontSize: 28),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BOTTOM CARD ───────────────────────────────────────
                  Expanded(
                    child: SlideInUp(
                      duration: const Duration(milliseconds: 500),
                      from: 120,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                            staggered(const Text('Create Account',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary))),
                            const SizedBox(height: 4),
                            staggered(const Text(
                                'Join thousands managing their health smartly',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14))),
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

                            // Full Name
                            staggered(TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.person_outline,
                                        size: 20)))),
                            const SizedBox(height: 14),

                            // Email
                            staggered(TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        size: 20)))),
                            const SizedBox(height: 14),

                            // Password
                            staggered(TextField(
                              controller: _passCtrl,
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
                            )),
                            const SizedBox(height: 14),

                            // Confirm Password
                            staggered(TextField(
                              controller: _confirmCtrl,
                              obscureText: _obscureConf,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                      _obscureConf
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary),
                                  onPressed: () => setState(
                                      () => _obscureConf = !_obscureConf),
                                ),
                              ),
                            )),
                            const SizedBox(height: 16),

                            // Terms checkbox
                            staggered(Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                  onChanged: (v) => setState(
                                      () => _acceptTerms = v ?? false),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13),
                                        children: [
                                          TextSpan(
                                              text: 'I agree to the '),
                                          TextSpan(
                                              text: 'Terms of Service',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),

                            const SizedBox(height: 8),

                            // Disclaimer
                            staggered(Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFFD27A)),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.info_outline,
                                        color: Color(0xFFD97706), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'SmartCare provides wellness suggestions only. '
                                      'It does not diagnose or prescribe. Always consult a doctor.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF92400E)),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 24),

                            // Register button
                            staggered(GradientButton(
                              label: 'Create Account',
                              loading: _isLoading,
                              onPressed: _isLoading ? null : _register,
                            )),

                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14)),
                                  TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ])),
                              ),
                            ),
                            const SizedBox(height: 16),
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