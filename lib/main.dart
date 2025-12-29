import 'package:callme/screens/singup_page.dart';
import 'package:flutter/material.dart';
import 'screens/logo_page.dart';
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

      // Start app with Logo Page
      home: const LogoPage(),

      // Optional named routes (for later navigation)
      routes: {
        '/signup': (context) => const SignupPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
