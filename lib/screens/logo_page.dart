import 'dart:async';

import 'package:callme/login/signup_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogoPage extends StatefulWidget {
  const LogoPage({super.key});

  @override
  State<LogoPage> createState() =>
      _LogoPageState();
}

class _LogoPageState
    extends State<LogoPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<double> _fade;

  late Animation<double> _scale;

  @override
  void initState() {

    super.initState();

    /// ANIMATION

    _controller = AnimationController(

      vsync: this,

      duration:
      const Duration(seconds: 2),
    );

    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(

      CurvedAnimation(

        parent: _controller,

        curve: Curves.easeIn,
      ),
    );

    _scale = Tween(
      begin: 0.9,
      end: 1.0,
    ).animate(

      CurvedAnimation(

        parent: _controller,

        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    /// CHECK LOGIN

    checkLogin();
  }

  /// =====================================================
  /// LOGIN CHECK
  /// =====================================================

  Future<void> checkLogin() async {

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final User? user =
        FirebaseAuth.instance.currentUser;

    /// USER ALREADY LOGGED IN

    if (user != null) {

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) => BottomNavPage(

            userPhone:
            user.phoneNumber ?? "",

            userEmail:
            user.email ?? "",
          ),
        ),
      );

    } else {

      /// NEW USER

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
          const SignupPage(),
        ),
      );
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

      body: SizedBox(

        width: double.infinity,

        height: double.infinity,

        child: Center(

          child: FadeTransition(

            opacity: _fade,

            child: ScaleTransition(

              scale: _scale,

              child: Column(

                mainAxisSize:
                MainAxisSize.min,

                children: [

                  /// LOGO

                  Image.asset(

                    'assets/logo.png',

                    width: 200,

                    height: 200,

                    fit: BoxFit.contain,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  /// TAGLINE

                  Transform.translate(

                    offset:
                    const Offset(0, -50),

                    child: const Text(

                      'All in One Service',

                      style: TextStyle(

                        fontSize: 16,

                        color: Color.fromARGB(
                          255,
                          70,
                          69,
                          69,
                        ),

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