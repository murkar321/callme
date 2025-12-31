import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'screens/logo_page.dart';
import 'screens/singup_page.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const CallMeApp());
}

class CallMeApp extends StatelessWidget {
  const CallMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),

      // First screen (splash → logo page)
      home: const LogoPage(),

      // Named routes
      routes: {
        '/signup': (context) => const SignupPage(),
        '/bottomnav': (context) => const BottomNavPage(), // 👈 Added
        '/home': (context) => HomePage(), // Still usable
      },
    );
  }
}
