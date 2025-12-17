import 'package:flutter/material.dart';
import 'screens/signup_page.dart';

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
      home: SignupPage(),
    );
  }
}
