import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// DIAGNOSTIC FLAG
const bool _debugNotif = true;

// Sound config
const bool _useCustomSound = true;
const String _soundFile = 'notification_sound';

// Channel constants
class NotificationChannels {
  static const String id = 'callme_high_v7';
  static const String name = 'CallMe Notifications';
  static const String desc = 'Booking, acceptance, and admin alerts.';
}

// Notification types
class NotificationType {
  static const String newBooking = 'new_booking';
  static const String bookingAccepted = 'booking_accepted';
  static const String bookingRejected = 'booking_rejected';
  static const String providerRegistered = 'provider_registered';
  static const String registrationApproved = 'registration_approved';
  static const String registrationRejected = 'registration_rejected';
  static const String providerFound = 'provider_found';
  static const String serviceCompleted = 'service_completed';
}

// Shared plugin instance
final FlutterLocalNotificationsPlugin _sharedPlugin =
    FlutterLocalNotificationsPlugin();

// Background tap handler
@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) {
  debugPrint('[NOTIF-TAP-BG] payload: ${response.payload}');
  NotificationService.pendingNavigationPayload = response.payload;

  final payload = response.payload;
  if (payload == null) return;

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    NotificationService.fireTap(data);
  } catch (e) {
    debugPrint('[NOTIF-TAP-BG] decode error: $e');
  }
}

// a data-only message) — it no longer touches Firestore.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('[FCM-BG] Firebase init error: $e');
    }
  }

  debugPrint('[FCM-BG] messageId=${message.messageId}');
  debugPrint(
      '[FCM-BG]   notification: ${message.notification?.title} / ${message.notification?.body}');
  debugPrint('[FCM-BG]   data: ${message.data}');

  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotificationStandalone(
      id: _uniqueNotifId(),
      title: message.data['title']?.toString() ?? 'New notification',
      body: message.data['body']?.toString() ?? '',
      payload: jsonEncode(message.data),
    );
  }
}

// Helpers

int _uniqueNotifId() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

const List<int> _vibrationPattern = [0, 300, 200, 300, 200, 600];

AndroidNotificationChannel _buildChannel() => AndroidNotificationChannel(
      NotificationChannels.id,
      NotificationChannels.name,
      description: NotificationChannels.desc,
      importance: Importance.max,
      playSound: true,
      sound: _useCustomSound
          ? RawResourceAndroidNotificationSound(_soundFile)
          : null,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
      enableLights: true,
      showBadge: true,
    );

NotificationDetails _buildDetails({String body = ''}) => NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.id,
        NotificationChannels.name,
        channelDescription: NotificationChannels.desc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: _useCustomSound
            ? RawResourceAndroidNotificationSound(_soundFile)
            : null,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPattern),
        enableLights: true,
        ledColor: const Color(0xFFAE91BA),
        ledOnMs: 500,
        ledOffMs: 500,
        visibility: NotificationVisibility.public,
        ticker: 'CallMe',
        fullScreenIntent: false,
        audioAttributesUsage: AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );

Future<void> _showLocalNotificationStandalone({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();

  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_buildChannel());

  if (_debugNotif) {
    debugPrint('=== NOTIF DEBUG (bg-standalone) ===');
    debugPrint('  channelId : ${NotificationChannels.id}');
    debugPrint('  title     : $title');
    debugPrint('  body      : $body');
    debugPrint('====================================');
  }

  await plugin.show(id, title, body, _buildDetails(body: body), payload: payload);
}

// NotificationService
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  bool _initialised = false;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Map<String, dynamic>? _pendingTap;

  static void Function(Map<String, dynamic> data)? _onNotificationTap;

  static set onNotificationTap(void Function(Map<String, dynamic>)? cb) {
    _onNotificationTap = cb;
    if (cb != null && _pendingTap != null) {
      debugPrint('[NOTIF] Flushing pending tap: $_pendingTap');
      final queued = _pendingTap!;
      _pendingTap = null;
      cb(queued);
    }
  }

  static void Function(Map<String, dynamic> data)? get onNotificationTap =>
      _onNotificationTap;

  static void fireTap(Map<String, dynamic> data) {
    final cb = _onNotificationTap;
    if (cb != null) {
      cb(data);
    } else {
      debugPrint('[NOTIF] Callback not set - queuing tap: $data');
      _pendingTap = data;
    }
  }

  static String? pendingNavigationPayload;

  Future<void> initialize() async {
    if (_initialised) return;

    try {
      await _sharedPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_buildChannel());
      debugPrint('[NOTIF] Channel registered: ${NotificationChannels.id}');

      await _sharedPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onTapForeground,
        onDidReceiveBackgroundNotificationResponse: _onTapBackground,
      );

      await _requestPermissions();

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _listenForeground();
      _listenBackgroundTap();
      _listenTokenRefresh();

      Future.microtask(_saveToken);

      Future.delayed(const Duration(milliseconds: 500), _checkColdStart);

      _initialised = true;
      debugPrint('[NOTIF] Initialised');
    } catch (e, st) {
      debugPrint('[NOTIF] Init error: $e\n$st');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
      announcement: false,
      carPlay: false,
      provisional: false,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      final granted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS granted: $granted');

      final exactAlarm = await _sharedPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      debugPrint('[NOTIF] EXACT_ALARM granted: $exactAlarm');
    }
  }

  void _onTapForeground(NotificationResponse response) {
    debugPrint('[NOTIF-TAP-FG] payload: ${response.payload}');
    pendingNavigationPayload = response.payload;

    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      NotificationService.fireTap(data);
    } catch (e) {
      debugPrint('[NOTIF-TAP-FG] decode error: $e');
    }
  }

  // exists the moment the action occurred, regardless of push delivery.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('[FCM-FG] messageId=${message.messageId}');
        debugPrint(
            '[FCM-FG]   notification: ${message.notification?.title} / ${message.notification?.body}');
        debugPrint('[FCM-FG]   data: ${message.data}');

        final notif = message.notification;
        final title =
            notif?.title ?? message.data['title']?.toString() ?? 'New message';
        final body = notif?.body ?? message.data['body']?.toString() ?? '';
        final id = _uniqueNotifId();
        final details = _buildDetails(body: body);

        if (_debugNotif) {
          debugPrint('=== NOTIF DEBUG (foreground) ===');
          debugPrint('  channelId : ${NotificationChannels.id}');
          debugPrint('  id        : $id');
          debugPrint('  title     : $title');
          debugPrint('  body      : $body');
          debugPrint('=================================');
        }

        await _sharedPlugin.show(
          id,
          title,
          body,
          details,
          payload: jsonEncode(message.data),
        );

        debugPrint('[FCM-FG] show() called id=$id');
      },
      onError: (e) => debugPrint('[FCM-FG] stream error: $e'),
    );
  }

  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage msg) {
        debugPrint('[FCM-TAP] opened from background: ${msg.data}');
        pendingNavigationPayload = jsonEncode(msg.data);
        NotificationService.fireTap(msg.data);
      },
      onError: (e) => debugPrint('[FCM-TAP] error: $e'),
    );
  }

  Future<void> _checkColdStart() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) {
      debugPrint('[FCM-COLD] opened from terminated state: ${msg.data}');
      pendingNavigationPayload = jsonEncode(msg.data);
      NotificationService.fireTap(msg.data);
    }
  }

  Future<void> _saveToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _fcm.getAPNSToken();
        if (apns == null) {
          debugPrint('[FCM] APNS token not ready - skipping');
          return;
        }
      }
      final token = await _fcm.getToken();
      debugPrint('[FCM] token: $token');
      if (token != null) await _writeToken(token);
    } catch (e) {
      debugPrint('[FCM] token error: $e');
    }
  }

  void _listenTokenRefresh() {
    _fcm.onTokenRefresh.listen(
      _writeToken,
      onError: (e) => debugPrint('[FCM] token refresh error: $e'),
    );
  }

  Future<void> _writeToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] No logged-in user - token not saved yet');
      return;
    }

    final db = FirebaseFirestore.instance;
    final uid = user.uid;
    final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await db.collection('users').doc(email).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': platform,
      }, SetOptions(merge: true));
      debugPrint('[FCM] Token saved -> users/$email');
    } else {
      debugPrint('[FCM] No email on current user - users/ token not saved');
    }

    try {
      final providerDocId = await _resolveProviderDocId(uid);
      if (providerDocId != null) {
        await db.collection('providers').doc(providerDocId).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': platform,
        }, SetOptions(merge: true));
        debugPrint('[FCM] Token also saved -> providers/$providerDocId');
      }
    } catch (e) {
      debugPrint('[FCM] provider token mirror error: $e');
    }
  }

  Future<String?> _resolveProviderDocId(String uid) async {
    if (uid.isEmpty) return null;
    final db = FirebaseFirestore.instance;

    try {
      var snap = await db
          .collection('providers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await db
            .collection('providers')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
      }

      return snap.docs.isNotEmpty ? snap.docs.first.id : null;
    } catch (e) {
      debugPrint('[FCM] _resolveProviderDocId error: $e');
      return null;
    }
  }

  Future<void> refreshTokenAfterLogin() => _saveToken();

  Future<void> clearTokenOnLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final uid = user.uid;

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await db.collection('users').doc(email).update({
        'fcmToken': FieldValue.delete(),
      });
    }

    try {
      final providerDocId = await _resolveProviderDocId(uid);
      if (providerDocId != null) {
        await db.collection('providers').doc(providerDocId).update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint('[FCM] provider token clear error: $e');
    }

    await _fcm.deleteToken();
    debugPrint('[FCM] Token cleared on logout');
  }

  static Future<void> showLocalAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await NotificationService().initialize();

      final id = _uniqueNotifId();

      if (_debugNotif) {
        debugPrint('=== NOTIF DEBUG (local-alert) ===');
        debugPrint('  channelId : ${NotificationChannels.id}');
        debugPrint('  id        : $id');
        debugPrint('  title     : $title');
        debugPrint('  body      : $body');
        debugPrint('==================================');
      }

      await _sharedPlugin.show(
        id,
        title,
        body,
        _buildDetails(body: body),
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('[NOTIF] showLocalAlert error: $e\n$st');
    }
  }
}