import 'dart:ui';

import 'package:callme/login/auth_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool loading = false;
  bool _pressed = false;

  // =====================================================
  // ANIMATION CONTROLLERS
  // =====================================================

  // Logo entrance: rotation + fade + scale
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoScale;

  // Content (title/subtitle/card) entrance
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  // Feature chips staggered entrance
  late final AnimationController _chipsController;

  // Ambient glow pulse behind logo (loops)
  late final AnimationController _glowController;

  // Slow floating background blobs (loops)
  late final AnimationController _blobController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _logoRotation = Tween<double>(begin: -0.35, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _chipsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _chipsController.forward();
    });

    autoLogin();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _chipsController.dispose();
    _glowController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  // =====================================================
  // AUTO LOGIN
  // If user is already signed in, refresh the ID token
  // so Firestore rules see valid auth, then navigate.
  // =====================================================

  Future<void> autoLogin() async {
    if (!_authService.isLoggedIn()) return;

    try {
      await _authService.currentUser!.getIdToken(true);
    } catch (e) {
      print('AUTO LOGIN TOKEN REFRESH ERROR: $e');
      await _authService.logout();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _navigateToHome(_authService.currentUser!);
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
  // NAVIGATION
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
  // BRAND COLORS
  // =====================================================

  static const _indigo = Color(0xFF4F46E5);
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF14B8A6);
  static const _purple = Color(0xFF7C3AED);

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    final isSmall = width < 360;
    final isTablet = width >= 600;

    final logoSize = isTablet ? 150.0 : (isSmall ? 96.0 : 112.0);
    final titleSize = isTablet ? 36.0 : (isSmall ? 25.0 : 29.0);
    final horizontalPadding = isTablet ? 48.0 : (isSmall ? 16.0 : 22.0);
    final cardPadding = isTablet ? 32.0 : (isSmall ? 18.0 : 24.0);
    final maxContentWidth = isTablet ? 520.0 : 440.0;

    return Scaffold(
      body: Stack(
        children: [
          // ---------- BASE GRADIENT BACKGROUND ----------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEFF3FC), Color(0xFFE4ECFB)],
              ),
            ),
          ),

          // ---------- FLOATING BLOBS ----------
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, _) {
              final t = _blobController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -130 + (t * 20),
                    right: -80 - (t * 15),
                    child: _blob(280, _blue.withOpacity(0.16)),
                  ),
                  Positioned(
                    top: 90 - (t * 18),
                    left: -100 + (t * 12),
                    child: _blob(230, _purple.withOpacity(0.13)),
                  ),
                  Positioned(
                    bottom: -90 + (t * 14),
                    right: -60 - (t * 10),
                    child: _blob(220, _teal.withOpacity(0.12)),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: isTablet ? 26 : 8),

                            // ---------- LOGO WITH AMBIENT GLOW ----------
                            SizedBox(
                              width: logoSize * 1.7,
                              height: logoSize * 1.7,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _glowController,
                                    builder: (context, _) {
                                      final glow = _glowController.value;
                                      return Container(
                                        width: logoSize * (1.35 + glow * 0.15),
                                        height:
                                            logoSize * (1.35 + glow * 0.15),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              _indigo.withOpacity(
                                                  0.28 - glow * 0.10),
                                              _blue.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  AnimatedBuilder(
                                    animation: _logoController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _logoFade.value,
                                        child: Transform.scale(
                                          scale: _logoScale.value,
                                          child: Transform.rotate(
                                            angle: _logoRotation.value,
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: 'logo',
                                      child: Container(
                                        width: logoSize,
                                        height: logoSize,
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [_indigo, _blue, _teal],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _indigo.withOpacity(0.28),
                                              blurRadius: 26,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: ClipOval(
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                  logoSize * 0.16),
                                              child: Image.asset(
                                                'assets/logo.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isTablet ? 14 : 8),

                            FadeTransition(
                              opacity: _contentFade,
                              child: SlideTransition(
                                position: _contentSlide,
                                child: Column(
                                  children: [
                                    // ---------- BADGE ----------
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                        gradient: LinearGradient(
                                          colors: [
                                            _indigo.withOpacity(0.10),
                                            _blue.withOpacity(0.10),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: _indigo.withOpacity(0.18),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt_rounded,
                                              size: 14, color: _indigo),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ALL YOUR SERVICES, ONE APP',
                                            style: TextStyle(
                                              fontSize: isSmall ? 10.5 : 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.6,
                                              color: _indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF111827),
                                          _indigo,
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        'Welcome to CallMe',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Sign in securely using your Google account.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isSmall ? 13.5 : 15,
                                        height: 1.6,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 30 : 24),

                                    // ---------- FEATURE CHIPS ----------
                                    FadeTransition(
                                      opacity: _chipsController,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _featureChip(
                                            icon: Icons.verified_rounded,
                                            label: 'Verified\nProviders',
                                            color: _indigo,
                                            small: isSmall,
                                          ),
                                          _featureChip(
                                            icon: Icons.flash_on_rounded,
                                            label: 'Instant\nBooking',
                                            color: _teal,
                                            small: isSmall,
                                          ),
                                          _featureChip(
                                            icon: Icons.lock_rounded,
                                            label: 'Secure &\nPrivate',
                                            color: _purple,
                                            small: isSmall,
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 34 : 28),

                                    // ---------- SIGN-IN CARD ----------
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _indigo.withOpacity(0.10),
                                            blurRadius: 34,
                                            offset: const Offset(0, 16),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // top accent bar
                                          Container(
                                            height: 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft:
                                                    Radius.circular(28),
                                                topRight:
                                                    Radius.circular(28),
                                              ),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  _indigo,
                                                  _blue,
                                                  _teal,
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.all(cardPadding),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Your profile, email, and photo will be securely saved. We will never share your information with anyone.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        Colors.grey.shade600,
                                                    height: 1.5,
                                                    fontSize:
                                                        isSmall ? 12.5 : 13.5,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        isTablet ? 26 : 20),

                                                // ---------- GOOGLE BUTTON ----------
                                                GestureDetector(
                                                  onTapDown: (_) => setState(
                                                      () => _pressed = true),
                                                  onTapUp: (_) => setState(
                                                      () => _pressed = false),
                                                  onTapCancel: () => setState(
                                                      () => _pressed = false),
                                                  onTap: loading
                                                      ? null
                                                      : googleLogin,
                                                  child: AnimatedScale(
                                                    scale:
                                                        _pressed ? 0.97 : 1.0,
                                                    duration: const Duration(
                                                        milliseconds: 120),
                                                    curve: Curves.easeOut,
                                                    child: Container(
                                                      width: double.infinity,
                                                      height:
                                                          isTablet ? 62 : 56,
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 18),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFFE5E7EB),
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .black
                                                                .withOpacity(
                                                                    0.05),
                                                            blurRadius: 12,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: loading
                                                          ? const Center(
                                                              child: SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2.5),
                                                              ),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Image.asset(
                                                                  'assets/google.png',
                                                                  height: 22,
                                                                  width: 22,
                                                                ),
                                                                const SizedBox(
                                                                    width: 14),
                                                                Text(
                                                                  'Continue with Google',
                                                                  style:
                                                                      TextStyle(
                                                                    color: const Color(
                                                                        0xFF111827),
                                                                    fontSize:
                                                                        isSmall
                                                                            ? 14.5
                                                                            : 16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    letterSpacing:
                                                                        0.2,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: isTablet ? 22 : 18),

                                    Text(
                                      'By continuing you agree to our Terms & Privacy Policy',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isSmall ? 11 : 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: isTablet ? 30 : 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _featureChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool small,
  }) {
    return Column(
      children: [
        Container(
          width: small ? 42 : 48,
          height: small ? 42 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: small ? 20 : 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: small ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}