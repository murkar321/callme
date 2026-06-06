import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'profile/notification_service.dart';

import 'screens/logo_page.dart';
import 'login/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/bottom_nav_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase: safe init (handles hot-restart duplicate-app error) ──────────
  // Firebase.apps.isEmpty check is not enough on hot restart because the
  // native layer already has a live app while the Dart side lost state.
  // Using a try/catch is the only reliable guard.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // [core/duplicate-app] is expected on hot-restart — safe to ignore.
    // Any other error is re-thrown so it is visible during development.
    if (!e.toString().contains('duplicate-app')) rethrow;
    debugPrint('[MAIN] Firebase already initialised — skipping (hot-restart)');
  }

  // ── Register background handler BEFORE runApp ──────────────────────────────
  // Must be top-level and registered here; any later registration is ignored.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Launch the UI immediately — no heavy work blocks the first frame ────────
  runApp(const CallMeApp());

  // ── Initialise notifications AFTER the first frame is painted ──────────────
  // addPostFrameCallback fires once the first frame is on screen, keeping
  // startup smooth. The 500 ms extra delay lets the widget tree fully settle
  // (avoids the Choreographer "skipped frames" warning).
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      await NotificationService().initialize();
      debugPrint('[MAIN] NotificationService ready');
    } catch (e) {
      debugPrint('[MAIN] Notification init failed: $e');
    }
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class CallMeApp extends StatelessWidget {
  const CallMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CallMe',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/logo',
      routes: {
        '/logo': (_) => const LogoPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomePage(),
        '/bottomnav': (_) => const BottomNavPage(
              userPhone: '',
              userEmail: '',
            ),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const LogoPage(),
      ),
    );
  }
}