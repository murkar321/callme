import 'dart:convert';

import 'package:callme/login/signup_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/profile/notification_service.dart';
import 'package:callme/profile/notification_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Clips its child down to just the left or right half, so the same
/// logo image can be split into two pieces that slide together.
class _HalfClipper extends CustomClipper<Rect> {
  final bool isLeft;
  const _HalfClipper({required this.isLeft});

  @override
  Rect getClip(Size size) {
    return isLeft
        ? Rect.fromLTWH(0, 0, size.width / 2, size.height)
        : Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class LogoPage extends StatefulWidget {
  const LogoPage({super.key});

  @override
  State<LogoPage> createState() => _LogoPageState();
}

class _LogoPageState extends State<LogoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _textFade;
  // How far (in pixels) each half of the logo starts from its resting
  // position before sliding together.
  late Animation<double> _splitOffset;

  // Track whether navigation has already been triggered so a hot-restart
  // or rapid rebuild can never fire pushReplacement twice.
  bool _navigated = false;

  // Total intro animation length (split-in + stabilize).
  static const Duration _animDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _animDuration,
    );

    // Whole logo fades in almost immediately, then the two halves slide
    // together over the rest of the animation.
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Text underneath fades in after the halves have joined.
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Starts wide apart, slides in with a slight overshoot so it feels
    // like the two halves "snap" together at the end.
    _splitOffset = Tween<double>(begin: 160.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Wait for the animation, then route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_animDuration, _navigate);
    });
  }

  Future<void> _navigate() async {
    // Guard: do nothing if widget is gone or we already navigated.
    if (!mounted || _navigated) return;
    _navigated = true;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: user.phoneNumber ?? '',
            userEmail: user.email ?? '',
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignupPage()),
      );
    }

    // If the app was cold-started by tapping a notification (app was
    // fully killed), the payload is waiting here. We deliberately handle
    // it AFTER pushReplacement above, so it opens on top of the correct
    // base screen instead of racing with it.
    _consumePendingNotificationTap();
  }

  void _consumePendingNotificationTap() {
    final payload = NotificationService.pendingNavigationPayload;
    if (payload == null) return;

    // Clear immediately so this can never fire twice.
    NotificationService.pendingNavigationPayload = null;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      // Small delay lets the base route's first frame settle before we
      // push the notification's target screen on top of it.
      Future.delayed(const Duration(milliseconds: 300), () {
        routeNotification(data);
      });
    } catch (e) {
      debugPrint('[LOGO] cold-start notification payload decode error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fade.value,
                      child: Stack(
                        children: [
                          // Left half: clipped to the left 50% of the logo,
                          // slides in from further left.
                          Transform.translate(
                            offset: Offset(-_splitOffset.value, 0),
                            child: ClipRect(
                              clipper: _HalfClipper(isLeft: true),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Right half: clipped to the right 50%, slides in
                          // from further right.
                          Transform.translate(
                            offset: Offset(_splitOffset.value, 0),
                            child: ClipRect(
                              clipper: _HalfClipper(isLeft: false),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: child,
                  );
                },
                child: const Text(
                  'All in One Service',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 70, 69, 69),
                    letterSpacing: 1,
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