import 'package:flutter/material.dart';
import 'screens/logo_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_page.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LogoPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
