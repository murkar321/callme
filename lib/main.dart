import 'dart:async';

import 'package:callme/profile/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'profile/notification_service.dart';
import 'profile/notification_router.dart';

import 'screens/logo_page.dart';
import 'login/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock orientation to portrait.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // ① Register background FCM handler FIRST — before Firebase.initializeApp().
    //   Flutter requires this to be registered before the engine starts
    //   processing background messages.
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // ② Assign tap callback BEFORE initialize() so cold-start taps are never
    //   lost. The pending-queue in NotificationService holds any tap that
    //   arrives before the callback is set, then flushes it the moment this
    //   line runs.
    NotificationService.onNotificationTap = routeNotification;

    // ③ Initialize Firebase.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      debugPrint('[MAIN] Firebase init error: $e\n$st');
    }

    // ④ Initialize notification service (channel, permissions, FCM listeners).
    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () =>
            debugPrint('[MAIN] NotificationService init timed out — continuing'),
      );
    } catch (e, st) {
      debugPrint('[MAIN] NotificationService error: $e\n$st');
    }

    runApp(const CallMeApp());
  }, (error, stack) {
    debugPrint('[MAIN] Uncaught zone error: $error\n$stack');
  });
}

class CallMeApp extends StatelessWidget {
  const CallMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CallMe',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFAE91BA), // CallMe brand purple
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF212121),
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      initialRoute: '/logo',
      routes: {
        '/logo':   (_) => const LogoPage(),
        '/signup': (_) => const SignupPage(),
        '/home':   (_) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/bottomnav') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => BottomNavPage(
              userPhone: args['userPhone']?.toString() ?? '',
              userEmail: args['userEmail']?.toString() ?? '',
            ),
          );
        }
        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const LogoPage(),
      ),
    );
  }
}