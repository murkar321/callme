import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/logo_page.dart';
import 'login/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔹 Firebase Init
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const CallMeApp());
}

class CallMeApp extends StatelessWidget {
  const CallMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallMe',
      debugShowCheckedModeBanner: false,

      /// 🔹 THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffAE91BA),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      /// 🔹 ROUTES
      initialRoute: '/logo',
      routes: {
        '/logo': (context) => const LogoPage(),
        '/signup': (context) => const SignupPage(),
        '/bottomnav': (context) => const BottomNavPage(userPhone: '',),
        '/home': (context) => const HomePage(),
      },

      /// 🔹 SAFETY (UNKNOWN ROUTES)
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const LogoPage(),
        );
      },
    );
  }
}