import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/logo_page.dart';
import 'screens/singup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';
import 'screens/salon_provider_form.dart';

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      /// First screen
      initialRoute: '/logo',

      /// All routes
      routes: {
        '/logo': (context) => const LogoPage(),

        '/signup': (context) => const SignupPage(),

        '/bottomnav': (context) => const BottomNavPage(),

        '/home': (context) => HomePage(),

        /// Salon Provider Registration
        '/salonRegister': (context) => const SalonProviderForm(),
      },
    );
  }
}
