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

  // Matches OrderService.NotificationType.orderTakenByOther in
  // order_service.dart. Needed here too because notification_page.dart
  // imports NotificationType from THIS file (not order_service.dart), so
  // without this constant the page can't render the "taken" notice with
  // its own icon/color and would fall through to the generic default.
  static const String orderTakenByOther = 'order_taken_by_other';

  // Matches OrderService.NotificationType.userCancelled in
  // order_service.dart. Single source of truth lives in both places with
  // the same string value ('user_cancelled').
  static const String userCancelled = 'user_cancelled';
}

class _NotifDedupe {
  static final Map<String, DateTime> _fired = {};
  static const Duration _window = Duration(seconds: 45);

  /// Returns true if this key has NOT fired recently (i.e. it's safe to
  /// show a notification for it now) and claims the key. Returns false
  /// if something already fired for this exact key inside the window —
  /// caller should skip showing anything.
  ///
  /// An empty key always returns true (no dedupe requested/possible).
  static bool claim(String key) {
    if (key.isEmpty) return true;
    final now = DateTime.now();
    // Sweep out stale entries so this map never grows unbounded.
    _fired.removeWhere((_, t) => now.difference(t) > _window);
    if (_fired.containsKey(key)) {
      debugPrint('[NOTIF-DEDUPE] SKIP duplicate ring for key="$key"');
      return false;
    }
    _fired[key] = now;
    return true;
  }
}

/// Builds a stable dedupe key from FCM/local-alert data payloads.
/// Format: "<type>:order:<orderId>" — matches the key format
/// business_dashboard_page.dart already builds for its instant local
/// alerts (`'new_booking:order:${doc.id}'`), so both paths agree on the
/// same identity for the same event.
String _dedupeKeyFromData(Map<String, dynamic> data) {
  final type = (data['type'] ?? '').toString().trim();
  final orderId = (data['orderId'] ?? '').toString().trim();
  if (type.isEmpty || orderId.isEmpty) return '';
  return '$type:order:$orderId';
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

  // Every foreground FCM message goes through the same dedupe gate as
  // the dashboard's instant local alert (see `_NotifDedupe` above), keyed
  // off `type` + `orderId` in the message data.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('[FCM-FG] messageId=${message.messageId}');
        debugPrint(
            '[FCM-FG]   notification: ${message.notification?.title} / ${message.notification?.body}');
        debugPrint('[FCM-FG]   data: ${message.data}');

        final dedupeKey = _dedupeKeyFromData(message.data);
        if (!_NotifDedupe.claim(dedupeKey)) {
          debugPrint('[FCM-FG] skipped ring — already fired for key="$dedupeKey"');
          return;
        }

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
          debugPrint('  dedupeKey : $dedupeKey');
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

    final tokenData = {
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
      'platform': platform,
    };

    // PRIMARY: doc(uid) — this is what OrderService.notifyUser() and
    // every other uid-keyed lookup in the app actually reads.
    await db.collection('users').doc(uid).set(tokenData, SetOptions(merge: true));
    debugPrint('[FCM] Token saved -> users/$uid (primary, uid-keyed)');

    // BACK-COMPAT MIRROR: doc(email) — kept so any older code path
    // that still reads by email keeps working.
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await db.collection('users').doc(email).set(tokenData, SetOptions(merge: true));
      debugPrint('[FCM] Token also mirrored -> users/$email (back-compat)');
    }

    try {
      final providerDocId = await _resolveProviderDocId(uid);
      if (providerDocId != null) {
        await db.collection('providers').doc(providerDocId).set(tokenData, SetOptions(merge: true));
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

    await db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    }).catchError((e) {
      debugPrint('[FCM] users/$uid token clear error (may not exist): $e');
    });

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await db.collection('users').doc(email).update({
        'fcmToken': FieldValue.delete(),
      }).catchError((e) {
        debugPrint('[FCM] users/$email token clear error (may not exist): $e');
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

  // `dedupeKey` is enforced via `_NotifDedupe.claim()`. Any caller that
  // passes the SAME key within the dedupe window will be silently
  // skipped.
  static Future<void> showLocalAlert({
    required String title,
    required String body,
    String? payload,
    required String dedupeKey,
  }) async {
    try {
      if (!_NotifDedupe.claim(dedupeKey)) {
        debugPrint('[NOTIF] showLocalAlert skipped — duplicate key="$dedupeKey"');
        return;
      }

      await NotificationService().initialize();

      final id = _uniqueNotifId();

      if (_debugNotif) {
        debugPrint('=== NOTIF DEBUG (local-alert) ===');
        debugPrint('  channelId : ${NotificationChannels.id}');
        debugPrint('  id        : $id');
        debugPrint('  title     : $title');
        debugPrint('  body      : $body');
        debugPrint('  dedupeKey : $dedupeKey');
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


  // ============================================================
  static Future<void> testNotification() async {
    await NotificationService().initialize();
    await _sharedPlugin.show(
      _uniqueNotifId(),
      '🔔 Test Notification',
      'If you can see and hear this, local notifications are working '
          'correctly. Any missing ring elsewhere is happening upstream '
          '(Cloud Function / fcmToken / Firestore rules), not here.',
      _buildDetails(body: 'Local notification test'),
    );
    debugPrint('[NOTIF] testNotification() fired.');
  }
}