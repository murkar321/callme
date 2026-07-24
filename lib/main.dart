import 'dart:async';

import 'package:callme/profile/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'profile/notification_service.dart';
import 'profile/notification_router.dart';
import 'payment/settings_controller.dart';

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

    NotificationService.onNotificationTap = routeNotification;

    // ② Load the persisted theme / notification preferences so the very
    //   first frame already renders in the user's chosen theme instead of
    //   flashing light-mode then swapping.
    try {
      await SettingsController.instance.load().timeout(
        const Duration(seconds: 3),
        onTimeout: () =>
            debugPrint('[MAIN] SettingsController load timed out — continuing'),
      );
    } catch (e, st) {
      debugPrint('[MAIN] SettingsController load error: $e\n$st');
    }

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

  // CallMe brand purple, shared by both the light and dark themes.
  static const Color _brandPurple = Color(0xFFAE91BA);

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: _brandPurple,
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
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: _brandPurple,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF1B1922),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    scaffoldBackgroundColor: const Color(0xFF121016),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CallMe',
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: mode,
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
      },
    );
  }
}