import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── DIAGNOSTIC FLAG ───────────────────────────────────────────────────────────
const bool _debugNotif = true;

// ─── Sound config ──────────────────────────────────────────────────────────────
const bool _useCustomSound = true;
const String _soundFile = 'notification_sound';

// ─── Channel constants ─────────────────────────────────────────────────────────
class NotificationChannels {
  static const String id   = 'callme_high_v7';
  static const String name = 'CallMe Notifications';
  static const String desc = 'Booking, acceptance, and admin alerts.';
}

// ─── Notification types ────────────────────────────────────────────────────────
class NotificationType {
  static const String newBooking           = 'new_booking';
  static const String bookingAccepted      = 'booking_accepted';
  static const String bookingRejected      = 'booking_rejected';
  static const String providerRegistered   = 'provider_registered';
  static const String registrationApproved = 'registration_approved';
  static const String registrationRejected = 'registration_rejected';
  static const String providerFound        = 'provider_found';
  static const String serviceCompleted     = 'service_completed';
}

// ─── Shared plugin instance ────────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin _sharedPlugin =
    FlutterLocalNotificationsPlugin();

// ─── Background tap handler ────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) {
  debugPrint('[NOTIF-TAP-BG] payload: ${response.payload}');
  NotificationService.pendingNavigationPayload = response.payload;
  if (response.payload != null) {
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      // FIX: use _fireTap() which queues the tap if the callback isn't set yet.
      // Previously calling onNotificationTap directly meant cold-start taps
      // were lost because the callback hadn't been assigned yet.
      NotificationService._fireTap(data);
    } catch (e) {
      debugPrint('[NOTIF-TAP-BG] decode error: $e');
    }
  }
}

// ─── Background FCM handler ────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('[FCM-BG] Firebase init error: $e');
    }
  }

  debugPrint('[FCM-BG] ▶ messageId=${message.messageId}');
  debugPrint('[FCM-BG]   notification: ${message.notification?.title} / ${message.notification?.body}');
  debugPrint('[FCM-BG]   data: ${message.data}');

  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotificationStandalone(
      id: _uniqueNotifId(),
      title: message.data['title']?.toString() ?? 'New notification',
      body:  message.data['body']?.toString()  ?? '',
      payload: jsonEncode(message.data),
    );
  }

  await _persistNotification(message, source: 'background-isolate');
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

// FIX: unique ID per notification — using messageId.hashCode caused Android
// to *replace* the previous notification (same slot = same ID) instead of
// showing a new popup + sound. Epoch millis guarantees a fresh slot every time.
int _uniqueNotifId() =>
    DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

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

// FIX: pass actual body text into BigTextStyleInformation — empty string
// caused Samsung/MIUI/ColorOS to suppress heads-up banners on repeat messages.
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

  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_buildChannel());

  if (_debugNotif) {
    debugPrint('━━━ NOTIF DEBUG (bg-standalone) ━━━━━━━━━━━━━');
    debugPrint('  channelId : ${NotificationChannels.id}');
    debugPrint('  title     : $title');
    debugPrint('  body      : $body');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  await plugin.show(id, title, body, _buildDetails(body: body), payload: payload);
}

Future<void> _persistNotification(
  RemoteMessage msg, {
  required String source,
}) async {
  final rid = msg.data['receiverId']?.toString();

  if (rid == null || rid.isEmpty) {
    debugPrint(
      '[NOTIF-STORE:$source] ⚠ Skipped — no "receiverId" in message.data.',
    );
    return;
  }

  try {
    await FirebaseFirestore.instance.collection('notifications').add({
      'receiverId': rid,
      'title':     msg.notification?.title ?? msg.data['title'] ?? '',
      'body':      msg.notification?.body  ?? msg.data['body']  ?? '',
      'type':      msg.data['type'] ?? '',
      'data':      msg.data,
      'read':      false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[NOTIF-STORE:$source] ✓ Saved for receiverId=$rid');
  } catch (e, st) {
    debugPrint('[NOTIF-STORE:$source] ✗ Firestore write failed: $e\n$st');
  }
}

// ─── NotificationService ───────────────────────────────────────────────────────
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  bool _initialised = false;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ── Tap callback with pending-queue ─────────────────────────────────────────
  // FIX: This is the root cause of navigation never working on cold-start and
  // background taps.
  //
  // What was happening:
  //   1. User taps a notification while app is terminated.
  //   2. Flutter engine starts → firebaseMessagingBackgroundHandler runs →
  //      onNotificationTap is called.
  //   3. BUT the app's main() hasn't called NotificationService.initialize()
  //      yet, and the widget tree hasn't assigned onNotificationTap yet.
  //   4. So onNotificationTap is null → tap is silently dropped → no navigation.
  //
  // Fix: _pendingTap stores the data if the callback isn't set yet.
  //      When the callback IS assigned (via setTapCallback), we immediately
  //      fire any queued tap so navigation always happens.
  static Map<String, dynamic>? _pendingTap;

  static void Function(Map<String, dynamic> data)? _onNotificationTap;

  /// Assign the callback that routes notifications to pages.
  /// Call this as early as possible — ideally in main() or BottomNavPage.initState().
  static set onNotificationTap(void Function(Map<String, dynamic>)? cb) {
    _onNotificationTap = cb;
    // If a tap arrived before the callback was ready, fire it now.
    if (cb != null && _pendingTap != null) {
      debugPrint('[NOTIF] Flushing pending tap: $_pendingTap');
      final queued = _pendingTap!;
      _pendingTap = null;
      cb(queued);
    }
  }

  static void Function(Map<String, dynamic> data)? get onNotificationTap =>
      _onNotificationTap;

  /// Routes a tap — queues it if the callback isn't set yet.
  static void _fireTap(Map<String, dynamic> data) {
    if (_onNotificationTap != null) {
      _onNotificationTap!(data);
    } else {
      debugPrint('[NOTIF] Callback not set — queuing tap: $data');
      _pendingTap = data;
    }
  }

  static String? pendingNavigationPayload;

  // ── initialize ───────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialised) return;

    try {
      await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
      // FIX: cold-start delay reduced to 500 ms — 1 s was too long on fast
      // devices and the callback was sometimes still null at 1 s anyway.
      // The pending-queue mechanism above makes the delay irrelevant for
      // correctness, but shorter is better for UX.
      Future.delayed(const Duration(milliseconds: 500), _checkColdStart);

      _initialised = true;
      debugPrint('[NOTIF] ✓ Initialised');
    } catch (e, st) {
      debugPrint('[NOTIF] Init error: $e\n$st');
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    final s = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
      criticalAlert: false, announcement: false,
      carPlay: false, provisional: false,
    );
    debugPrint('[FCM] Auth status: ${s.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      final granted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS granted: $granted');

      final exactAlarm = await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      debugPrint('[NOTIF] EXACT_ALARM granted: $exactAlarm');
    }
  }

  // ── Foreground tap ─────────────────────────────────────────────────────────────
  void _onTapForeground(NotificationResponse response) {
    debugPrint('[NOTIF-TAP-FG] payload: ${response.payload}');
    pendingNavigationPayload = response.payload;
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        // FIX: use _fireTap so it queues if callback not ready yet.
        NotificationService._fireTap(data);
      } catch (e) {
        debugPrint('[NOTIF-TAP-FG] decode error: $e');
      }
    }
  }

  // ── Foreground FCM listener ────────────────────────────────────────────────────
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('[FCM-FG] ▶ messageId=${message.messageId}');
        debugPrint('[FCM-FG]   notification: ${message.notification?.title} / ${message.notification?.body}');
        debugPrint('[FCM-FG]   data: ${message.data}');

        final notif  = message.notification;
        final title  = notif?.title ?? message.data['title']?.toString() ?? 'New message';
        final body   = notif?.body  ?? message.data['body']?.toString()  ?? '';
        final id     = _uniqueNotifId();      // FIX: unique every time
        final details = _buildDetails(body: body); // FIX: pass body

        if (_debugNotif) {
          debugPrint('━━━ NOTIF DEBUG (foreground) ━━━━━━━━━━━━━━━━━━━');
          debugPrint('  channelId : ${NotificationChannels.id}');
          debugPrint('  id        : $id');
          debugPrint('  title     : $title');
          debugPrint('  body      : $body');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        await _sharedPlugin.show(id, title, body, details,
            payload: jsonEncode(message.data));

        debugPrint('[FCM-FG] ✓ show() called id=$id');
        await _persistNotification(message, source: 'foreground');
      },
      onError: (e) => debugPrint('[FCM-FG] stream error: $e'),
    );
  }

  // ── Background tap ────────────────────────────────────────────────────────────
  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage msg) {
        debugPrint('[FCM-TAP] opened from background: ${msg.data}');
        pendingNavigationPayload = jsonEncode(msg.data);
        // FIX: _fireTap queues if callback not set yet.
        NotificationService._fireTap(msg.data);
      },
      onError: (e) => debugPrint('[FCM-TAP] error: $e'),
    );
  }

  // ── Cold start ─────────────────────────────────────────────────────────────────
  Future<void> _checkColdStart() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) {
      debugPrint('[FCM-COLD] opened from terminated state: ${msg.data}');
      pendingNavigationPayload = jsonEncode(msg.data);
      // FIX: _fireTap queues if callback not set yet, and the pending-queue
      // setter flushes it the moment onNotificationTap is assigned.
      NotificationService._fireTap(msg.data);
    }
  }

  // ── FCM token ──────────────────────────────────────────────────────────────────
  Future<void> _saveToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _fcm.getAPNSToken();
        if (apns == null) {
          debugPrint('[FCM] APNS token not ready — skipping');
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

  void _listenTokenRefresh() =>
      _fcm.onTokenRefresh.listen(
        _writeToken,
        onError: (e) => debugPrint('[FCM] token refresh error: $e'),
      );

  Future<void> _writeToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] No logged-in user — token not saved yet');
      return;
    }

    // FIX: your users collection is keyed by EMAIL, not UID.
    final email = user.email;
    if (email == null || email.isEmpty) {
      debugPrint('[FCM] No email on current user — token not saved');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(email)             // FIX: was doc(uid)
        .set({
      'fcmToken':       token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
      'platform':       (!kIsWeb && Platform.isIOS) ? 'ios' : 'android',
    }, SetOptions(merge: true));

    debugPrint('[FCM] Token saved → users/$email');
  }

  // ── Public helpers ─────────────────────────────────────────────────────────────
  Future<void> refreshTokenAfterLogin() => _saveToken();

  Future<void> clearTokenOnLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)           // FIX: was doc(uid)
          .update({'fcmToken': FieldValue.delete()});
    }

    await _fcm.deleteToken();
    debugPrint('[FCM] Token cleared on logout');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO WIRE onNotificationTap IN YOUR APP
// ─────────────────────────────────────────────────────────────────────────────
//
// Set the callback AS EARLY AS POSSIBLE — before initialize() if you can.
// The safest place is main() right after WidgetsFlutterBinding.ensureInitialized():
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//
//     // Register background handler FIRST.
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//     // Assign tap callback BEFORE initialize() so cold-start taps are never lost.
//     NotificationService.onNotificationTap = routeNotification;
//
//     await Firebase.initializeApp();
//     await NotificationService().initialize();
//
//     runApp(const MyApp());
//   }
//
// If you also assign it in a widget (e.g. BottomNavPage.initState), that's fine
// as a backup, but main() assignment is what guarantees cold-start works.
//
// ─────────────────────────────────────────────────────────────────────────────
// CLOUD FUNCTION — include these fields in data block:
// ─────────────────────────────────────────────────────────────────────────────
//
//   data: {
//     type: 'registration_approved',   // NotificationType constant
//     receiverId: userEmail,           // email — matches users doc key
//     title: '...',
//     body:  '...',
//     // For registration_approved / registration_rejected only:
//     // No need to send businessName/serviceType — router fetches from Firestore.
//   }
//
// ─────────────────────────────────────────────────────────────────────────────
// AndroidManifest.xml checklist:
//   <uses-permission android:name="android.permission.VIBRATE"/>
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//   <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
//   <meta-data
//     android:name="com.google.firebase.messaging.default_notification_channel_id"
//     android:value="callme_high_v7"/>
// ─────────────────────────────────────────────────────────────────────────────