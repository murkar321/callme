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

// ─── IMPORTANT ────────────────────────────────────────────────────────────────
// FirebaseMessaging.onBackgroundMessage() MUST receive a top-level, annotated
// function. It is called in a separate Dart isolate, so it cannot be a closure
// or a class method. The function lives in notification_service.dart and is
// exported here via the import above.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  // ① Ensure Flutter engine is ready — required before ANY plugin call.
  WidgetsFlutterBinding.ensureInitialized();

  // ② Register the background FCM handler BEFORE Firebase.initializeApp().
  //    Flutter's FCM plugin hooks into native code during this call;
  //    if you register after init the handler is never wired up on Android.
  //    The function MUST be top-level and annotated @pragma('vm:entry-point').
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ③ Wire up notification-tap routing before NotificationService.initialize()
  //    so the listeners it creates already have a valid callback to call.
  NotificationService.onNotificationTap = routeNotification;

  runZonedGuarded(() async {
    // ④ Initialise Firebase.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      debugPrint('[MAIN] Firebase init error: $e');
      debugPrint('$st');
      // Continue — don't let a network/config issue block the UI forever.
    }

    // ⑤ Initialise the notification service (permissions, channel, listeners).
    try {
      await NotificationService().initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[MAIN] NotificationService init timed out, continuing.');
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