import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/logo_page.dart';
import 'screens/singup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

      // Splash / Logo screen
      home: const LogoPage(),

      // Named routes
      routes: {
        '/signup': (context) => const SignupPage(),
        '/bottomnav': (context) => const BottomNavPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
