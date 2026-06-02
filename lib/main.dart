import 'package:callme/profile/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';

import 'screens/logo_page.dart';
import 'login/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';


/// ======================================================
/// BACKGROUND NOTIFICATION HANDLER
/// ======================================================

Future<void> firebaseBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform,
  );

  debugPrint(
    "Background Notification: "
    "${message.notification?.title}",
  );
}

/// ======================================================
/// MAIN
/// ======================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    /// FIREBASE INIT

    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions
              .currentPlatform,
    );

    /// ==================================================
    /// APP CHECK (PLAY INTEGRITY)
    /// ==================================================

    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.playIntegrity,
    );

    debugPrint(
      "Firebase App Check Activated",
    );

    /// ==================================================
    /// BACKGROUND FCM
    /// ==================================================

    FirebaseMessaging.onBackgroundMessage(
      firebaseBackgroundHandler,
    );
    await NotificationService().initialize();
  } catch (e) {
    debugPrint(
      "Firebase initialization error: $e",
    );
  }

  runApp(
    const CallMeApp(),
  );
}

/// ======================================================
/// APP
/// ======================================================

class CallMeApp extends StatelessWidget {
  const CallMeApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallMe',

      debugShowCheckedModeBanner:
          false,

      /// ==================================================
      /// THEME
      /// ==================================================

      theme: ThemeData(
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(
            0xffAE91BA,
          ),
        ),

        appBarTheme:
            const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      /// ==================================================
      /// ROUTES
      /// ==================================================

      initialRoute: '/logo',

      routes: {
        '/logo': (context) =>
            const LogoPage(),

        '/signup': (context) =>
            const SignupPage(),

        '/bottomnav': (context) =>
            const BottomNavPage(
              userPhone: '',
              userEmail: '',
            ),

        '/home': (context) =>
            const HomePage(),
      },

      /// ==================================================
      /// UNKNOWN ROUTES
      /// ==================================================

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) =>
              const LogoPage(),
        );
      },
    );
  }
}