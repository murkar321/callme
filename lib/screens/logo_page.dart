import 'dart:convert';

import 'package:callme/login/signup_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/profile/notification_service.dart';
import 'package:callme/profile/notification_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogoPage extends StatefulWidget {
  const LogoPage({super.key});

  @override
  State<LogoPage> createState() => _LogoPageState();
}

class _LogoPageState extends State<LogoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  // Track whether navigation has already been triggered so a hot-restart
  // or rapid rebuild can never fire pushReplacement twice.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Wait for the animation, then route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), _navigate);
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
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Transform.translate(
                    offset: const Offset(0, -50),
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
        ),
      ),
    );
  }
}