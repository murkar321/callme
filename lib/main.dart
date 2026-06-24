import 'dart:async';

import 'package:callme/profile/navigation.dart';
import 'package:flutter/material.dart';
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
    // Ensure Flutter engine is ready.
    WidgetsFlutterBinding.ensureInitialized();

    // Register background FCM handler.
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Notification tap routing.
    NotificationService.onNotificationTap = routeNotification;

    // Initialize Firebase.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      debugPrint('[MAIN] Firebase init error: $e');
      debugPrint('$st');
    }

    // Initialize notification service.
    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint(
            '[MAIN] NotificationService init timed out, continuing.',
          );
        },
      );
    } catch (e, st) {
      debugPrint('[MAIN] NotificationService error: $e');
      debugPrint('$st');
    }

    runApp(const CallMeApp());
  }, (error, stack) {
    debugPrint('[MAIN] Uncaught zone error: $error');
    debugPrint('$stack');
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
      ),
      initialRoute: '/logo',
      routes: {
        '/logo': (_) => const LogoPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/bottomnav':
            final args =
                settings.arguments as Map<String, dynamic>? ?? {};

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
