import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── DIAGNOSTIC FLAG ──────────────────────────────────────────────────────────
const bool _debugNotif = true;

// ─── Sound config ─────────────────────────────────────────────────────────────
// File must exist at: android/app/src/main/res/raw/notification_sound.mp3
// Filename: lowercase, numbers, underscores only. No spaces or caps.
// After adding/changing: flutter clean → uninstall app → reinstall.
const bool _useCustomSound = true;
const String _soundFile = 'notification_sound';

// ─── Channel constants ────────────────────────────────────────────────────────
// Bump the version suffix whenever you change importance or sound.
// Android permanently caches channel settings — a new ID forces a fresh channel.
// MUST match android:value in AndroidManifest.xml <meta-data>.
class NotificationChannels {
  static const String id   = 'callme_high_v6';
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

// ─── Shared plugin instance ───────────────────────────────────────────────────
// A single instance is used everywhere so the channel is only created once
// and the same plugin handles both foreground and background taps.
final FlutterLocalNotificationsPlugin _sharedPlugin =
    FlutterLocalNotificationsPlugin();

// ─── Background tap handler ───────────────────────────────────────────────────
// MUST be top-level AND annotated so it survives tree-shaking in release.
@pragma('vm:entry-point')
void _onTapBackground(NotificationResponse response) {
  debugPrint('[NOTIF-TAP-BG] payload: ${response.payload}');
  NotificationService.pendingNavigationPayload = response.payload;
  if (response.payload != null) {
    try {
      NotificationService.onNotificationTap
          ?.call(jsonDecode(response.payload!) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NOTIF-TAP-BG] decode error: $e');
    }
  }
}

// ─── Background FCM handler ───────────────────────────────────────────────────
// MUST be top-level, annotated, and registered in main() BEFORE
// Firebase.initializeApp() AND before runApp(). Registering after either
// of those calls means the native FCM plugin never wires it up on Android.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialise Firebase — the background isolate is a fresh Dart runtime.
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

  // When the FCM payload includes a "notification" block, Android OS
  // auto-displays the tray notification — do NOT call show() again or you
  // get duplicates. Only show manually for DATA-ONLY messages (no
  // notification block).
  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotificationStandalone(
      id: _notifId(message),
      title: message.data['title']?.toString() ?? 'New notification',
      body:  message.data['body']?.toString()  ?? '',
      payload: jsonEncode(message.data),
    );
  }

  await _persistNotification(message, source: 'background-isolate');
}

// ─── Helpers shared between background handler and service ───────────────────

int _notifId(RemoteMessage message) {
  final raw = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  return raw.hashCode & 0x7fffffff; // ensure positive 32-bit int
}

/// Single source of truth for the Android notification channel.
/// Call this once during init — Android silently ignores duplicate
/// createNotificationChannel calls with the same ID.
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
  enableLights: true,
  showBadge: true,
);

/// Builds [NotificationDetails] at runtime — not const because the sound
/// value is determined at runtime.
NotificationDetails _buildDetails() => NotificationDetails(
  android: AndroidNotificationDetails(
    NotificationChannels.id,
    NotificationChannels.name,
    channelDescription: NotificationChannels.desc,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: _useCustomSound
        ? RawResourceAndroidNotificationSound(_soundFile)
        : null,
    enableVibration: true,
    enableLights: true,
    visibility: NotificationVisibility.public,
    fullScreenIntent: false,
    // Routes audio through the NOTIFICATION stream (respects notification
    // volume), not the media stream.
    audioAttributesUsage: AudioAttributesUsage.notification,
  ),
  iOS: const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.active,
  ),
);

/// Standalone show — used by the background isolate which has no service
/// instance. Re-initialises the plugin and channel each call (safe to repeat).
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
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_buildChannel());

  if (_debugNotif) {
    debugPrint('━━━ NOTIF DEBUG (bg-standalone) ━━━━━━━━━━━━━');
    debugPrint('  channelId : ${NotificationChannels.id}');
    debugPrint('  title     : $title');
    debugPrint('  body      : $body');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  await plugin.show(id, title, body, _buildDetails(), payload: payload);
}

/// Persists an incoming FCM message to Firestore so the NotificationPage
/// can display it. Requires `data.receiverId` in the FCM payload.
Future<void> _persistNotification(
  RemoteMessage msg, {
  required String source,
}) async {
  final rid = msg.data['receiverId']?.toString();

  if (rid == null || rid.isEmpty) {
    debugPrint(
      '[NOTIF-STORE:$source] ⚠ Skipped — no "receiverId" in message.data '
      '(${msg.data}). Add receiverId to your Cloud Function data block.',
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
    debugPrint(
      '[NOTIF-STORE:$source] Check Firestore rules allow writes to '
      '"notifications", and that a composite index exists for '
      'receiverId + createdAt.',
    );
  }
}

// ─── NotificationService ──────────────────────────────────────────────────────
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  bool _initialised = false;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Callback invoked when a notification is tapped (foreground or background).
  /// For COLD START (app was killed), read [pendingNavigationPayload] instead —
  /// LogoPage consumes it once its own splash navigation is complete, avoiding
  /// a race with two competing pushes on launch.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Stashed payload from the last notification tap, consumed by LogoPage
  /// after it has resolved the initial route (cold-start safe).
  static String? pendingNavigationPayload;

  // ── initialize ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialised) return;

    try {
      // 1. Create the notification channel FIRST.
      //    Android caches channel settings permanently. A new channel ID
      //    forces fresh settings including importance and sound.
      //    This call is idempotent — safe to repeat.
      await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_buildChannel());
      debugPrint('[NOTIF] Channel registered: ${NotificationChannels.id}');

      // 2. Initialise flutter_local_notifications with both tap callbacks.
      //    onDidReceiveNotificationResponse       → foreground taps
      //    onDidReceiveBackgroundNotificationResponse → background/killed taps
      //      (must be a top-level @pragma function — see _onTapBackground above)
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

      // 3. Request OS-level permissions (shows dialog on first run).
      await _requestPermissions();

      // 4. iOS: present alerts/badges/sound even when the app is foregrounded.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Start FCM listeners.
      _listenForeground();
      _listenBackgroundTap();
      _listenTokenRefresh();

      // 6. Save FCM token asynchronously — doesn't block init.
      Future.microtask(_saveToken);

      // 7. Cold-start: stash the payload so LogoPage can consume it after
      //    its own navigation has settled (avoids racing pushes on launch).
      Future.delayed(const Duration(seconds: 1), _checkColdStart);

      _initialised = true;
      debugPrint('[NOTIF] ✓ Initialised — channel: ${NotificationChannels.id}');
    } catch (e, st) {
      debugPrint('[NOTIF] Init error: $e\n$st');
    }
  }

  // ── Permissions ──────────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    final s = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    debugPrint('[FCM] Auth status: ${s.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      final granted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS granted: $granted');
    }
  }

  // ── Foreground tap ────────────────────────────────────────────────────────────
  void _onTapForeground(NotificationResponse response) {
    debugPrint('[NOTIF-TAP-FG] payload: ${response.payload}');
    pendingNavigationPayload = response.payload;
    if (response.payload != null) {
      try {
        onNotificationTap
            ?.call(jsonDecode(response.payload!) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('[NOTIF-TAP-FG] decode error: $e');
      }
    }
  }

  // ── Foreground FCM listener ───────────────────────────────────────────────────
  // When the app is OPEN, Android does NOT auto-show a tray notification even
  // when the FCM payload includes a "notification" block — we must call
  // _sharedPlugin.show() ourselves. On iOS the banner is shown automatically
  // (via setForegroundNotificationPresentationOptions), but we still call
  // show() so the local tap callback fires correctly.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('[FCM-FG] ▶ messageId=${message.messageId}');
        debugPrint('[FCM-FG]   notification: ${message.notification?.title} / ${message.notification?.body}');
        debugPrint('[FCM-FG]   data: ${message.data}');

        final notif  = message.notification;
        final title  = notif?.title ?? message.data['title']?.toString() ?? 'New message';
        final body   = notif?.body  ?? message.data['body']?.toString()  ?? '';
        final id     = _notifId(message);
        final details = _buildDetails();

        if (_debugNotif) {
          debugPrint('━━━ NOTIF DEBUG (foreground) ━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('  channelId  : ${NotificationChannels.id}');
          debugPrint('  sound      : ${_useCustomSound ? _soundFile : "default"}');
          debugPrint('  title      : $title');
          debugPrint('  body       : $body');
          debugPrint('  id         : $id');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        await _sharedPlugin.show(
          id,
          title,
          body,
          details,
          payload: jsonEncode(message.data),
        );

        debugPrint('[FCM-FG] ✓ _sharedPlugin.show() called (id=$id)');

        await _persistNotification(message, source: 'foreground');
      },
      onError: (e) => debugPrint('[FCM-FG] stream error: $e'),
    );
  }

  // ── Background tap (app backgrounded, user taps notification) ──────────────
  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage msg) {
        debugPrint('[FCM-TAP] opened from background: ${msg.data}');
        pendingNavigationPayload = jsonEncode(msg.data);
        onNotificationTap?.call(msg.data);
      },
      onError: (e) => debugPrint('[FCM-TAP] error: $e'),
    );
  }

  // ── Cold start ────────────────────────────────────────────────────────────────
  // Stash the payload so LogoPage can consume it after its own navigation
  // has settled. Calling onNotificationTap directly here would race with
  // LogoPage's splash push and cause a double-navigation on first frame.
  Future<void> _checkColdStart() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) {
      debugPrint('[FCM-COLD] opened from terminated state: ${msg.data}');
      pendingNavigationPayload = jsonEncode(msg.data);
    }
  }

  // ── FCM token ──────────────────────────────────────────────────────────────
  Future<void> _saveToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _fcm.getAPNSToken();
        if (apns == null) {
          debugPrint('[FCM] APNS token not ready — skipping for now');
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[FCM] No logged-in user — token not saved yet');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken':       token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
      'platform':       (!kIsWeb && Platform.isIOS) ? 'ios' : 'android',
    }, SetOptions(merge: true));
    debugPrint('[FCM] Token saved uid=$uid');
  }

  // ── Public helpers ────────────────────────────────────────────────────────────
  Future<void> refreshTokenAfterLogin() => _saveToken();

  Future<void> clearTokenOnLogout() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .update({'fcmToken': FieldValue.delete()});
    await _fcm.deleteToken();
    debugPrint('[FCM] Token cleared on logout');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKLIST — everything needed for foreground popups + sound to work
// ─────────────────────────────────────────────────────────────────────────────
//
// ① AndroidManifest.xml  (android/app/src/main/AndroidManifest.xml)
//
//    <uses-permission android:name="android.permission.VIBRATE"/>
//    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//
//    Inside <application>:
//    <meta-data
//      android:name="com.google.firebase.messaging.default_notification_channel_id"
//      android:value="callme_high_v6"/>   ← must match NotificationChannels.id
//
// ② Sound file
//    android/app/src/main/res/raw/notification_sound.mp3
//    → lowercase, no spaces, no extension in _soundFile constant
//    → After any change: flutter clean → uninstall app → flutter run
//
// ③ main.dart order (CRITICAL)
//    WidgetsFlutterBinding.ensureInitialized()          ← step 1
//    FirebaseMessaging.onBackgroundMessage(handler)     ← step 2 (before init!)
//    NotificationService.onNotificationTap = callback   ← step 3
//    Firebase.initializeApp()                           ← step 4
//    NotificationService().initialize()                 ← step 5
//    runApp()                                           ← step 6
//
// ④ Cloud Function payload
//    Send BOTH "notification" block (for bg/killed auto-display) AND "data"
//    block (for foreground manual display + Firestore storage).
//
//    await admin.messaging().send({
//      token: fcmToken,
//      notification: { title: 'Hello', body: 'World' },
//      data: {
//        type: 'new_booking',
//        receiverId: uid,          ← REQUIRED for Firestore storage
//        title: 'Hello',
//        body: 'World',
//      },
//      android: {
//        priority: 'high',
//        notification: {
//          channelId: 'callme_high_v6',          ← must match
//          defaultSound: false,
//          defaultVibrateTimings: true,
//          notificationPriority: 'PRIORITY_MAX',
//        },
//      },
//      apns: {
//        headers: { 'apns-priority': '10' },
//        payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } },
//      },
//    });
//
// ⑤ Device checks
//    - App notifications: ON
//    - Channel "CallMe Notifications": Sound ON, Importance HIGH
//    - Battery optimisation: Unrestricted
//    - DND: OFF during testing
//    - Both media volume AND notification volume turned up
//
// ⑥ After ANY channel ID or sound file change:
//    flutter clean → uninstall app from device → flutter run
// ─────────────────────────────────────────────────────────────────────────────