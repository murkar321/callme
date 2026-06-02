import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  Future<void> initialize() async {
    NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Notification Permission: ${settings.authorizationStatus}',
    );

    String? token =
        await _messaging.getToken();

    debugPrint(
      'FCM TOKEN: $token',
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint(
          'Foreground Notification: '
          '${message.notification?.title}',
        );
      },
    );
  }
}