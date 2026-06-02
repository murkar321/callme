import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      debugPrint(
        "========== NOTIFICATION START ==========",
      );

      /// Request Permission
      NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        "Permission Status: ${settings.authorizationStatus}",
      );

      /// Get FCM Token
      String? token =
          await _messaging.getToken();

      debugPrint(
        "FCM TOKEN: $token",
      );

      if (token == null) {
        debugPrint(
          "WARNING: FCM Token is NULL",
        );
      }

      /// Listen for token refresh
      _messaging.onTokenRefresh.listen(
        (newToken) {
          debugPrint(
            "NEW FCM TOKEN: $newToken",
          );

          /// Later we will save this
          /// to Firestore automatically
        },
        onError: (e) {
          debugPrint(
            "TOKEN REFRESH ERROR: $e",
          );
        },
      );

      /// Foreground Notifications
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint(
            "========== FOREGROUND MESSAGE ==========",
          );

          debugPrint(
            "Title: ${message.notification?.title}",
          );

          debugPrint(
            "Body: ${message.notification?.body}",
          );

          debugPrint(
            "Data: ${message.data}",
          );
        },
      );

      /// User taps notification
      FirebaseMessaging.onMessageOpenedApp
          .listen(
        (RemoteMessage message) {
          debugPrint(
            "Notification Opened",
          );

          debugPrint(
            "Data: ${message.data}",
          );
        },
      );

      /// App launched from notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance
              .getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          "App opened from terminated notification",
        );

        debugPrint(
          "Data: ${initialMessage.data}",
        );
      }

      debugPrint(
        "========== NOTIFICATION READY ==========",
      );
    } catch (e) {
      debugPrint(
        "NOTIFICATION ERROR: $e",
      );
    }
  }
}