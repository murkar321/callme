import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── DIAGNOSTIC FLAG ──────────────────────────────────────────────────────────
// Set true once to log exactly what Android sees. Turn off before release.
const bool _debugNotif = true;

// ─── Sound config ─────────────────────────────────────────────────────────────
// Place file at: android/app/src/main/res/raw/notification_sound.mp3
// Set false if you don't have the file yet — uses system default sound.
const bool _useCustomSound = true; // ← keep false until file is added
const String _soundFile = 'notification_sound';

// ─── Background handler ───────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }
  debugPrint('[FCM-BG] ${message.notification?.title}');

  // Only needed for data-only payloads (no notification block)
  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotification(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: message.data['title'] ?? 'New notification',
      body: message.data['body'] ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

// ─── Show local notification ──────────────────────────────────────────────────
Future<void> _showLocalNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));

  final details = _buildDetails();

  if (_debugNotif) {
    final android = details.android!;
    debugPrint('━━━ NOTIF DEBUG ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('  channelId  : ${android.channelId}');
    debugPrint('  importance : ${android.importance}');
    debugPrint('  priority   : ${android.priority}');
    debugPrint('  playSound  : ${android.playSound}');
    debugPrint('  sound      : ${android.sound}');
    debugPrint('  title      : $title');
    debugPrint('  body       : $body');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  await plugin.show(id, title, body, details, payload: payload);
}

// ─── NotificationDetails builder — NOT const ──────────────────────────────────
// Must NOT be const — RawResourceAndroidNotificationSound is not a
// compile-time constant. Using const here silently breaks the sound
// and can suppress heads-up banners on some devices.
NotificationDetails _buildDetails() {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationChannels.id,
      NotificationChannels.name,
      channelDescription: NotificationChannels.desc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      fullScreenIntent: false,
      sound: _useCustomSound
          ? RawResourceAndroidNotificationSound(_soundFile)
          : null,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

// ─── Channel ──────────────────────────────────────────────────────────────────
class NotificationChannels {
  // Bump version suffix whenever you change importance or sound.
  // Android permanently caches channel settings — a new ID forces
  // a fresh channel with the correct settings.
  static const String id   = 'callme_high_v4';
  static const String name = 'CallMe Notifications';
  static const String desc = 'Booking, acceptance, and admin alerts.';
}

// ─── Notification types ───────────────────────────────────────────────────────
class NotificationType {
  static const String newBooking           = 'new_booking';
  static const String bookingAccepted      = 'booking_accepted';
  static const String bookingRejected      = 'booking_rejected';
  static const String providerRegistered   = 'provider_registered';
  static const String registrationApproved = 'registration_approved';
  static const String registrationRejected = 'registration_rejected';
}

// ─── NotificationService ──────────────────────────────────────────────────────
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  bool _initialised = false;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static void Function(Map<String, dynamic> data)? onNotificationTap;
  static String? pendingNavigationPayload;

  // ── initialize ───────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialised) return;
    try {
      // Order matters: channel must exist before any show() call
      await _createChannel();
      await _initPlugin();
      await _requestPermissions();
      await _configureForegroundPresentation();

      _listenForeground();
      _listenBackgroundTap();
      _listenTokenRefresh();

      Future.microtask(_saveToken);
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 800));
        await _checkColdStart();
      });

      _initialised = true;
      debugPrint('[NOTIF] ✓ Initialised — channel: ${NotificationChannels.id}');
    } catch (e) {
      debugPrint('[NOTIF] Init error: $e');
    }
  }

  // ── Create Android channel ───────────────────────────────────────────────────
  // CRITICAL RULES:
  //   1. importance MUST be Importance.max — lower values disable heads-up
  //   2. sound on channel MUST match sound in AndroidNotificationDetails
  //   3. After changing channel settings → uninstall app → reinstall
  Future<void> _createChannel() async {
    final channel = AndroidNotificationChannel(
      NotificationChannels.id,
      NotificationChannels.name,
      description: NotificationChannels.desc,
      importance: Importance.max,
      playSound: true,
      sound: _useCustomSound
          ? RawResourceAndroidNotificationSound(_soundFile)
          : null,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('[NOTIF] Channel registered: ${channel.id}');
  }

  // ── Init local plugin ────────────────────────────────────────────────────────
  Future<void> _initPlugin() async {
    await _localPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTap,
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    final s = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] Auth: ${s.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      final granted = await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS: $granted');
    }
  }

  // ── iOS foreground ───────────────────────────────────────────────────────────
  Future<void> _configureForegroundPresentation() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  // ── FOREGROUND message listener ──────────────────────────────────────────────
  // This is the key method for "app open, notification in tray" problem.
  //
  // When the app is OPEN:
  //   • FCM delivers to onMessage stream (no auto-banner on Android)
  //   • We must call _localPlugin.show() to display the heads-up banner
  //   • The banner will only appear if:
  //       a) Channel importance = Importance.max  ✓
  //       b) Notification permission granted      ✓
  //       c) Device not in DND / battery saver    (check device)
  //       d) App not in "minimised" category      (check device settings)
  //
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('[FCM-FG] ▶ received: ${message.notification?.title}');
        debugPrint('[FCM-FG]   data: ${message.data}');

        if (!kIsWeb && Platform.isAndroid) {
          final notif = message.notification;

          // Use notification fields if present, fall back to data fields.
          // Some FCM payloads arrive data-only — handle both.
          final title = notif?.title ?? message.data['title'] ?? 'New message';
          final body  = notif?.body  ?? message.data['body']  ?? '';

          final id = message.messageId?.hashCode
              ?? DateTime.now().millisecondsSinceEpoch;

          debugPrint('[FCM-FG] Showing local notification id=$id');

          await _localPlugin.show(
            id,
            title,
            body,
            _buildDetails(),               // ← non-const, correct details
            payload: jsonEncode(message.data),
          );

          debugPrint('[FCM-FG] ✓ _localPlugin.show() called');
        }

        // iOS: setForegroundNotificationPresentationOptions handles the banner.
        // We still store for the in-app list.
        await _storeNotification(message);
      },
      onError: (e) => debugPrint('[FCM-FG] stream error: $e'),
    );
  }

  // ── Background tap ───────────────────────────────────────────────────────────
  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage msg) {
        pendingNavigationPayload = jsonEncode(msg.data);
        _handleNav(msg.data);
      },
      onError: (e) => debugPrint('[FCM-BG-TAP] $e'),
    );
  }

  // ── Cold start ───────────────────────────────────────────────────────────────
  Future<void> _checkColdStart() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) {
      pendingNavigationPayload = jsonEncode(msg.data);
      _handleNav(msg.data);
    }
  }

  // ── Token ────────────────────────────────────────────────────────────────────
  Future<void> _saveToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        if (await _fcm.getAPNSToken() == null) return;
      }
      final token = await _fcm.getToken();
      if (token != null) await _writeToken(token);
    } catch (e) {
      debugPrint('[FCM] token error: $e');
    }
  }

  void _listenTokenRefresh() =>
      _fcm.onTokenRefresh.listen(_writeToken,
          onError: (e) => debugPrint('[FCM] refresh: $e'));

  Future<void> _writeToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
      'platform': (!kIsWeb && Platform.isIOS) ? 'ios' : 'android',
    }, SetOptions(merge: true));
    debugPrint('[FCM] Token saved uid=$uid');
  }

  // ── Tap handler ──────────────────────────────────────────────────────────────
  @pragma('vm:entry-point')
  static void _onTap(NotificationResponse r) {
    pendingNavigationPayload = r.payload;
    if (r.payload != null) {
      try {
        onNotificationTap?.call(jsonDecode(r.payload!) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  void _handleNav(Map<String, dynamic> data) => onNotificationTap?.call(data);

  // ── Firestore store ──────────────────────────────────────────────────────────
  Future<void> _storeNotification(RemoteMessage msg) async {
    final rid = msg.data['receiverId'] as String?;
    if (rid == null) return;
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': rid,
        'title': msg.notification?.title ?? msg.data['title'] ?? '',
        'body':  msg.notification?.body  ?? msg.data['body']  ?? '',
        'type':  msg.data['type'] ?? '',
        'data':  msg.data,
        'read':  false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NOTIF] store error: $e');
    }
  }

  // ── Public ───────────────────────────────────────────────────────────────────
  Future<void> refreshTokenAfterLogin() => _saveToken();

  Future<void> clearTokenOnLogout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .update({'fcmToken': FieldValue.delete()});
    await _fcm.deleteToken();
    debugPrint('[FCM] Token cleared');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETE CHECKLIST — do ALL steps or heads-up will not show
// ─────────────────────────────────────────────────────────────────────────────
//
// ① AndroidManifest.xml  (android/app/src/main/AndroidManifest.xml)
//
//    <manifest>
//      <uses-permission android:name="android.permission.VIBRATE"/>
//      <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//    <application>
//      <meta-data
//        android:name="com.google.firebase.messaging.default_notification_channel_id"
//        android:value="callme_high_v4"/>          ← must match channel id above
//
// ② Cloud Function — android.priority MUST be 'high'
//
//    await admin.messaging().send({
//      token: fcmToken,
//      notification: { title: 'Hello', body: 'Test' },
//      data: { type: 'new_booking', receiverId: uid, title: 'Hello', body: 'Test' },
//      android: {
//        priority: 'high',                  // ← CRITICAL: wakes the device
//        notification: {
//          channelId: 'callme_high_v4',     // ← must match channel id above
//          defaultSound: true,
//          defaultVibrateTimings: true,
//          notificationPriority: 'PRIORITY_MAX',  // ← extra insurance
//        },
//      },
//      apns: {
//        headers: { 'apns-priority': '10' },
//        payload: { aps: { sound: 'default', badge: 1 } },
//      },
//    });
//
// ③ Device settings — CHECK ALL:
//    • Settings → Apps → [Your App] → Notifications
//        - "Allow notifications" = ON
//        - "High Importance Notifications" or "CallMe Notifications" = ON
//        - Sound = ON (not silent)
//    • Settings → Battery → [Your App] → "Unrestricted" (not Optimised)
//    • Do Not Disturb = OFF during testing
//
// ④ UNINSTALL app fully → reinstall (mandatory after channel ID change)
//
// ─────────────────────────────────────────────────────────────────────────────