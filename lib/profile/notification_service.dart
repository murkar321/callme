import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("========== BACKGROUND MESSAGE ==========");
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
  debugPrint("Data: ${message.data}");
}



class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      debugPrint("========== NOTIFICATION START ==========");

      /// 🔥 IMPORTANT: register background handler first (call in main too)
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      /// Permission
      NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("Permission: ${settings.authorizationStatus}");

      /// FCM Token
      String? token = await _messaging.getToken();
      debugPrint("FCM TOKEN: $token");

      /// Token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint("NEW TOKEN: $newToken");
        // SAVE TO FIRESTORE HERE
      });

      /// FOREGROUND
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("========== FOREGROUND ==========");
        debugPrint("Title: ${message.notification?.title}");
        debugPrint("Body: ${message.notification?.body}");
        debugPrint("Data: ${message.data}");
      });

      /// BACKGROUND TAP (app in background → user taps)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint("========== NOTIFICATION TAP ==========");
        debugPrint("Data: ${message.data}");
      });

      /// TERMINATED APP (app closed → opened via notification)
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        debugPrint("========== APP OPENED FROM CLOSED STATE ==========");
        debugPrint("Data: ${initialMessage.data}");
      }

      debugPrint("========== NOTIFICATION READY ==========");
    } catch (e) {
      debugPrint("NOTIFICATION ERROR: $e");
    }
  }
}