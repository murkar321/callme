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
// File must exist at: android/app/src/main/res/raw/notification_sound.mp3
// Filename: lowercase, numbers, underscores only. No spaces or caps.
// After adding/changing: flutter clean → uninstall app → reinstall.
const bool _useCustomSound = true;
const String _soundFile = 'notification_sound';

// ─── Channel constants ─────────────────────────────────────────────────────────
// ⚠ Bump version suffix when you change importance/sound — Android permanently
// caches channel settings; a new ID forces fresh settings.
// MUST match android:value in AndroidManifest.xml <meta-data>.
class NotificationChannels {
  static const String id   = 'callme_high_v7'; // bumped → forces fresh channel
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
      NotificationService.onNotificationTap
          ?.call(jsonDecode(response.payload!) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[NOTIF-TAP-BG] decode error: $e');
    }
  }
}

// ─── Background FCM handler ────────────────────────────────────────────────────
// MUST be top-level, annotated, registered in main() BEFORE Firebase.initializeApp().
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

  // Only show manually for DATA-ONLY messages — FCM auto-shows notification-block messages.
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

// ─── Shared helpers ────────────────────────────────────────────────────────────

int _notifId(RemoteMessage message) {
  final raw = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
  return raw.hashCode & 0x7fffffff;
}

/// Vibration pattern: [delay, vibrate, pause, vibrate, …] all in ms.
/// 0 ms delay → immediate. Pattern: short-short-long.
const List<int> _vibrationPattern = [0, 300, 200, 300, 200, 600];

/// Builds the Android notification channel.
/// ─ Importance.max   → heads-up (on-screen) popup + lock screen
/// ─ enableVibration  → vibrates using _vibrationPattern
/// ─ playSound + RawResource → custom sound from res/raw/
AndroidNotificationChannel _buildChannel() => AndroidNotificationChannel(
  NotificationChannels.id,
  NotificationChannels.name,
  description: NotificationChannels.desc,
  importance: Importance.max,          // IMPORTANCE_HIGH = heads-up popup
  playSound: true,
  sound: _useCustomSound
      ? RawResourceAndroidNotificationSound(_soundFile)
      : null,
  enableVibration: true,
  vibrationPattern: Int64List.fromList(_vibrationPattern),
  enableLights: true,
  showBadge: true,
);

/// Builds [NotificationDetails] for every show() call.
NotificationDetails _buildDetails() => NotificationDetails(
  android: AndroidNotificationDetails(
    NotificationChannels.id,
    NotificationChannels.name,
    channelDescription: NotificationChannels.desc,
    importance: Importance.max,        // triggers heads-up popup
    priority: Priority.max,            // ← changed from high → max for on-screen banner
    playSound: true,
    sound: _useCustomSound
        ? RawResourceAndroidNotificationSound(_soundFile)
        : null,
    enableVibration: true,
    vibrationPattern: Int64List.fromList(_vibrationPattern),
    enableLights: true,
    ledColor: const Color(0xFFFF6B9D),  // pink accent matching callme brand
    ledOnMs: 500,
    ledOffMs: 500,
    visibility: NotificationVisibility.public, // show on lock screen
    ticker: 'CallMe',                  // accessibility / status bar ticker
    fullScreenIntent: false,           // true only for calls/alarms
    audioAttributesUsage: AudioAttributesUsage.notification,
    // ⚠ styleInformation not required for popup — defaults to BigTextStyle
    // which expands automatically on pull-down.
    styleInformation: const BigTextStyleInformation(''),
  ),
  iOS: const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.active,
  ),
);

/// Standalone show used by the background isolate.
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

  await plugin.show(id, title, body, _buildDetails(), payload: payload);
}

/// Persists FCM message to Firestore for NotificationPage display.
Future<void> _persistNotification(
  RemoteMessage msg, {
  required String source,
}) async {
  final rid = msg.data['receiverId']?.toString();

  if (rid == null || rid.isEmpty) {
    debugPrint(
      '[NOTIF-STORE:$source] ⚠ Skipped — no "receiverId" in message.data. '
      'Add receiverId to your Cloud Function data block.',
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

  static void Function(Map<String, dynamic> data)? onNotificationTap;
  static String? pendingNavigationPayload;

  // ── initialize ───────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialised) return;

    try {
      // ① Create channel FIRST — Android caches settings permanently.
      await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_buildChannel());
      debugPrint('[NOTIF] Channel registered: ${NotificationChannels.id}');

      // ② Init plugin with both tap callbacks.
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

      // ③ Request OS permissions.
      await _requestPermissions();

      // ④ iOS foreground presentation.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // ⑤ FCM listeners.
      _listenForeground();
      _listenBackgroundTap();
      _listenTokenRefresh();

      // ⑥ Save token (non-blocking).
      Future.microtask(_saveToken);

      // ⑦ Cold-start payload (1 s delay avoids race with LogoPage navigation).
      Future.delayed(const Duration(seconds: 1), _checkColdStart);

      _initialised = true;
      debugPrint('[NOTIF] ✓ Initialised — channel: ${NotificationChannels.id}');
    } catch (e, st) {
      debugPrint('[NOTIF] Init error: $e\n$st');
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    final s = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
      announcement: false,
      carPlay: false,
      provisional: false,
    );
    debugPrint('[FCM] Auth status: ${s.authorizationStatus}');

    if (!kIsWeb && Platform.isAndroid) {
      // POST_NOTIFICATIONS required on Android 13+ (API 33+)
      final granted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS granted: $granted');

      // ─── EXACT_ALARM permission (Android 12+ API 31+) ─────────────────────
      // Required to schedule precise local notifications. Without it,
      // scheduled notifications silently fail on Android 12+. For immediate
      // show() calls this isn't needed, but good practice to request.
      final exactAlarmGranted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
      debugPrint('[NOTIF] EXACT_ALARM granted: $exactAlarmGranted');
    }
  }

  // ── Foreground tap ─────────────────────────────────────────────────────────────
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

  // ── Foreground FCM listener ────────────────────────────────────────────────────
  // Android does NOT auto-show a banner when the app is open — we must call
  // _sharedPlugin.show() ourselves to get the heads-up popup + sound + vibration.
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

  // ── Background tap ────────────────────────────────────────────────────────────
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

  // ── Cold start ─────────────────────────────────────────────────────────────────
  Future<void> _checkColdStart() async {
    final msg = await _fcm.getInitialMessage();
    if (msg != null) {
      debugPrint('[FCM-COLD] opened from terminated state: ${msg.data}');
      pendingNavigationPayload = jsonEncode(msg.data);
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

  // ── Public helpers ─────────────────────────────────────────────────────────────
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
// WHAT CHANGED FROM v6 → v7  (all the fixes for popup / sound / vibration)
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. Channel ID bumped to callme_high_v7
//    Android permanently caches channel settings. Changing importance/sound
//    on an existing channel ID has NO effect. A new ID forces fresh settings.
//    Update AndroidManifest.xml <meta-data android:value="callme_high_v7"/>.
//
// 2. Priority.max (was Priority.high)
//    Priority.high can still suppress heads-up popups on some OEMs.
//    Priority.max guarantees the floating heads-up banner on Android 8+.
//
// 3. vibrationPattern added (both channel + details)
//    Without an explicit pattern the channel may silently skip vibration
//    on some devices even when enableVibration = true.
//    Pattern [0,300,200,300,200,600] = short-short-long, starts immediately.
//
// 4. visibility = NotificationVisibility.public
//    Makes the full notification content visible on the lock screen.
//    Private/Secret would hide or redact it.
//
// 5. styleInformation = BigTextStyleInformation('')
//    Ensures long bodies expand without truncation, and fixes a rendering
//    quirk on some Samsung devices that suppressed heads-up for
//    notifications with no explicit style.
//
// 6. ledColor / ledOnMs / ledOffMs added
//    Blinks the notification LED (devices that have one).
//
// 7. requestExactAlarmsPermission() added
//    Required on Android 12+ (API 31+) for reliable notification delivery.
//    Without it, some OEMs silently drop notifications from the tray.
//
// ─────────────────────────────────────────────────────────────────────────────
// MANDATORY AndroidManifest.xml CHECKLIST
// ─────────────────────────────────────────────────────────────────────────────
//
//  <uses-permission android:name="android.permission.VIBRATE"/>
//  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>   ← ADD THIS
//  <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>        ← ADD THIS (API 33+)
//
//  Inside <application>:
//  <meta-data
//    android:name="com.google.firebase.messaging.default_notification_channel_id"
//    android:value="callme_high_v7"/>    ← must match NotificationChannels.id
//
// ─────────────────────────────────────────────────────────────────────────────
// CLOUD FUNCTION PAYLOAD (send BOTH notification + data blocks)
// ─────────────────────────────────────────────────────────────────────────────
//
//  await admin.messaging().send({
//    token: fcmToken,
//    notification: { title: 'Hello', body: 'World' },
//    data: {
//      type: 'new_booking',
//      receiverId: uid,       ← REQUIRED for Firestore persistence
//      title: 'Hello',
//      body: 'World',
//    },
//    android: {
//      priority: 'high',
//      notification: {
//        channelId: 'callme_high_v7',           ← must match
//        defaultSound: false,
//        defaultVibrateTimings: false,           ← false so our pattern is used
//        vibrateTimingsMillis: [0,300,200,300,200,600],
//        notificationPriority: 'PRIORITY_MAX',
//      },
//    },
//    apns: {
//      headers: { 'apns-priority': '10' },
//      payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } },
//    },
//  });
//
// ─────────────────────────────────────────────────────────────────────────────
// AFTER ANY CHANNEL ID OR SOUND FILE CHANGE — ALWAYS DO THIS:
//   flutter clean → uninstall app from device → flutter run
// ─────────────────────────────────────────────────────────────────────────────
//
// DEVICE SETTINGS TO VERIFY:
//   ✓ App notifications: ON
//   ✓ Channel "CallMe Notifications": Sound ON, Importance HIGH or URGENT
//   ✓ Battery optimisation: Unrestricted (Settings > Apps > callme > Battery)
//   ✓ DND: OFF during testing
//   ✓ Notification volume (not media volume) turned up
//   ✓ Lock screen notifications: Show all content
// ─────────────────────────────────────────────────────────────────────────────