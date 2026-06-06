import 'package:callme/login/auth_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  // =====================================================
  // AUTO LOGIN
  // =====================================================
  //
  // If user is already signed in, update FCM token (smart
  // diff — only writes to Firestore if changed) then navigate.

  Future<void> autoLogin() async {
    if (!_authService.isLoggedIn()) return;

    await _authService.updateFcmToken();

    final user = _authService.currentUser!;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _navigateToHome(user);
  }

  // =====================================================
  // GOOGLE LOGIN
  // =====================================================

  Future<void> googleLogin() async {
    try {
      setState(() => loading = true);

      final User? user = await _authService.googleLogin();

      if (user == null) {
        setState(() => loading = false);
        return;
      }

      if (!mounted) return;

      _navigateToHome(user);
    } on FirebaseAuthException catch (e) {
      showError(e.message ?? 'Google Sign In Failed');
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // =====================================================
  // NAVIGATION HELPER
  // =====================================================

  void _navigateToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: '',
          userEmail: user.email ?? '',
        ),
      ),
    );
  }

  // =====================================================
  // ERROR
  // =====================================================

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────────
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.08),
              ),
            ),
          ),

          Positioned(
            top: 120,
            left: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // ── Logo ───────────────────────────────────────────
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4F46E5),
                                Color(0xFF2563EB),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Welcome to CallMe',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Sign in securely using your Google account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Card ───────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF4F46E5),
                                size: 30,
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'Continue with Google',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Your profile, email, and photo will be securely saved. We will never share your information with anyone.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Google Sign-In Button ──────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                elevation: 1.5,
                                shadowColor: Colors.black12,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: loading ? null : googleLogin,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: loading
                                        ? const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/google.png',
                                                height: 24,
                                                width: 24,
                                              ),
                                              const SizedBox(width: 14),
                                              const Text(
                                                'Continue with Google',
                                                style: TextStyle(
                                                  color: Color(0xFF111827),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}