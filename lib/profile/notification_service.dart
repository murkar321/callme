import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// DIAGNOSTIC FLAG
const bool _debugNotif = true;

// Sound config
const bool _useCustomSound = true;
const String _soundFile = 'notification_sound';



// ═══════════════════════════════════════════════════════════════
const String _smallIconDrawable = 'ic_notification';
const String _largeIconResource = '@mipmap/ic_launcher';
const String _safeInitIcon = '@mipmap/ic_launcher';

// ═══════════════════════════════════════════════════════════════
// Channel constants
//
// Android notification channels are IMMUTABLE once created on a given
// device — if you change importance/sound/vibration in this file, you
// must bump the channel id or Android keeps reusing the old channel
// definition already on that device. Bump again (v9, v10, ...) any
// time you touch channel settings.
// ═══════════════════════════════════════════════════════════════
class NotificationChannels {
  static const String id = 'callme_high_v8';
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

  static const String workStarted = 'work_started_otp';
  static const String orderTakenByOther = 'order_taken_by_other';
  static const String userCancelled = 'user_cancelled';

  static const String orderCancelled = 'order_cancelled';
  static const String orderUnavailable = 'order_unavailable';

  // Fired by OrderService.adminDeclineOrder() when an admin manually
  // declines a booking (e.g. no provider available/accepted in time).
  // Kept distinct from bookingRejected (provider-initiated) so the
  // notification list and icon clearly read as "our team", not "the
  // provider".
  static const String adminDeclined = 'admin_declined';
}

// ═══════════════════════════════════════════════════════════════
// Shared icon/color mapping — used everywhere a banner/list item
// needs to know what a notification type looks like.
// ═══════════════════════════════════════════════════════════════
({IconData icon, Color color}) bannerStyleForType(String? type) {
  switch (type) {
    case NotificationType.newBooking:
      return (icon: Icons.event_available_outlined, color: const Color(0xFF1565C0));
    case NotificationType.bookingAccepted:
      return (icon: Icons.check_circle_outline, color: const Color(0xFF2E7D32));
    case NotificationType.bookingRejected:
      return (icon: Icons.cancel_outlined, color: const Color(0xFFD32F2F));
    case NotificationType.providerRegistered:
      return (icon: Icons.store_mall_directory_outlined, color: const Color(0xFFE65100));
    case NotificationType.registrationApproved:
      return (icon: Icons.verified_outlined, color: const Color(0xFF2E7D32));
    case NotificationType.registrationRejected:
      return (icon: Icons.block_outlined, color: const Color(0xFFD32F2F));
    case NotificationType.serviceCompleted:
      return (icon: Icons.task_alt_outlined, color: const Color(0xFF00695C));
    case NotificationType.workStarted:
      return (icon: Icons.lock_clock_rounded, color: const Color(0xFF00695C));
    case NotificationType.orderTakenByOther:
      return (icon: Icons.timer_off_outlined, color: const Color(0xFF9E9E9E));
    case NotificationType.userCancelled:
      return (icon: Icons.event_busy_outlined, color: const Color(0xFFE64A19));
    case NotificationType.orderCancelled:
      return (icon: Icons.event_busy_outlined, color: const Color(0xFFD32F2F));
    case NotificationType.orderUnavailable:
      return (icon: Icons.hourglass_disabled_outlined, color: const Color(0xFF9E9E9E));
    case NotificationType.providerFound:
      return (icon: Icons.person_search_outlined, color: const Color(0xFF3F51B5));
    case NotificationType.adminDeclined:
      return (icon: Icons.gpp_bad_outlined, color: const Color(0xFFD32F2F));
    default:
      return (icon: Icons.notifications_active_outlined, color: const Color(0xFF3F51B5));
  }
}

class _NotifDedupe {
  static final Map<String, DateTime> _fired = {};
  static const Duration _window = Duration(seconds: 45);

  static bool claim(String key) {
    if (key.isEmpty) return true;
    final now = DateTime.now();
    _fired.removeWhere((_, t) => now.difference(t) > _window);
    if (_fired.containsKey(key)) {
      debugPrint('[NOTIF-DEDUPE] SKIP duplicate ring for key="$key"');
      return false;
    }
    _fired[key] = now;
    return true;
  }
}

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
    // Data-only message — WE fully control display here, custom icon,
    // custom sound, custom channel all apply correctly.
    debugPrint('[FCM-BG] data-only payload → showing via app code '
        '(custom icon + sound WILL apply).');
    try {
      await _showLocalNotificationStandalone(
        id: _uniqueNotifId(),
        title: message.data['title']?.toString() ?? 'New notification',
        body: message.data['body']?.toString() ?? '',
        payload: jsonEncode(message.data),
      );
    } catch (e, st) {
      debugPrint('[FCM-BG] failed to show local notification: $e\n$st');
    }
  } else if (message.notification != null) {
    // ⚠️ The payload includes a top-level "notification" block, so
    // Android/Google Play Services auto-renders this itself — this
    // app's Dart code never runs in this case. Whether the icon/sound
    // look right depends ENTIRELY on AndroidManifest.xml's
    // default_notification_icon / default_notification_channel_id /
    // default_notification_sound meta-data tags, which must point at
    // resources that actually exist. If those are missing or wrong,
    // Android can fail to render the notification AT ALL for this
    // message shape — no exception ever reaches Dart because Dart
    // isn't in the loop.
    //
    // If background/terminated notifications still don't show after
    // fixing the icon resource below, switch your Cloud Function /
    // server to send DATA-ONLY payloads (no top-level "notification"
    // key) so this file controls display consistently in every app
    // state.
    debugPrint('[FCM-BG] ⚠️ payload has a "notification" block — Android '
        'will auto-display this using AndroidManifest.xml defaults, NOT '
        'this file\'s custom icon/sound. Verify default_notification_icon '
        'in AndroidManifest.xml points to a drawable that actually exists.');
  }
}

// Helpers

int _uniqueNotifId() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

const List<int> _vibrationPattern = [0, 300, 200, 300, 200, 600];

AndroidNotificationChannel _buildChannel({bool forceDefaultSound = false}) =>
    AndroidNotificationChannel(
      NotificationChannels.id,
      NotificationChannels.name,
      description: NotificationChannels.desc,
      importance: Importance.max,
      playSound: true,
      sound: (_useCustomSound && !forceDefaultSound)
          ? RawResourceAndroidNotificationSound(_soundFile)
          : null,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(_vibrationPattern),
      enableLights: true,
      showBadge: true,
    );

// FIX: added `forceDefaultIcon` alongside the existing
// `forceDefaultSound`, so the retry ladder in `_showTrayNotification`
// / `_showLocalNotificationStandalone` can independently rule out
// "bad sound resource" vs "bad icon resource" as the cause of a
// show() failure, and still land on something that displays.
NotificationDetails _buildDetails({
  String body = '',
  bool forceDefaultSound = false,
  bool forceDefaultIcon = false,
}) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.id,
        NotificationChannels.name,
        channelDescription: NotificationChannels.desc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: (_useCustomSound && !forceDefaultSound)
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
        icon: forceDefaultIcon ? _largeIconResource : _smallIconDrawable,
        largeIcon: forceDefaultIcon
            ? null
            : const DrawableResourceAndroidBitmap(_largeIconResource),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
        sound: (_useCustomSound && !forceDefaultSound) ? '$_soundFile.caf' : 'default',
      ),
    );

// ═══════════════════════════════════════════════════════════════
// FIX: 3-step fallback ladder so a bad custom sound AND/OR a bad
// custom icon can never fully silence a notification:
//   1. custom sound + custom icon
//   2. default sound + custom icon   (isolates a bad sound file)
//   3. default sound + safe icon     (isolates a bad icon resource)
// Every step is logged so you can see exactly which resource is
// broken instead of just "nothing happened".
// ═══════════════════════════════════════════════════════════════
Future<bool> _showTrayNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  try {
    await _sharedPlugin.show(id, title, body, _buildDetails(body: body), payload: payload);
    return true;
  } catch (e, st) {
    debugPrint('[NOTIF] show() failed with custom sound "$_soundFile" — '
        'retrying with default sound. Error: $e\n$st');
  }

  try {
    await _sharedPlugin.show(
      id,
      title,
      body,
      _buildDetails(body: body, forceDefaultSound: true),
      payload: payload,
    );
    return true;
  } catch (e, st) {
    debugPrint('[NOTIF] show() failed with default sound + custom icon '
        '"$_smallIconDrawable" — this usually means that drawable is '
        'missing from android/app/src/main/res/drawable*/. Retrying with '
        'safe launcher icon. Error: $e\n$st');
  }

  try {
    await _sharedPlugin.show(
      id,
      title,
      body,
      _buildDetails(body: body, forceDefaultSound: true, forceDefaultIcon: true),
      payload: payload,
    );
    debugPrint('[NOTIF] show() succeeded only after falling back to '
        'default sound + safe icon — fix the custom sound/icon resources '
        'when you get a chance.');
    return true;
  } catch (e2, st2) {
    debugPrint('[NOTIF] show() failed even with default sound + safe icon '
        '— this notification will NOT appear at all. Check '
        'POST_NOTIFICATIONS permission and channel setup. Error: $e2\n$st2');
    return false;
  }
}

Future<void> _showLocalNotificationStandalone({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();

  // FIX: use the guaranteed-to-exist launcher icon for the plugin's
  // *initialization* default. This is just a fallback value the
  // plugin uses internally — it does NOT determine what icon shows on
  // an actual notification (that's controlled per-call by
  // `_buildDetails()`'s `icon:` field below). Using a resource that's
  // guaranteed to exist here prevents init from throwing.
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings(_safeInitIcon),
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

  try {
    await plugin.show(id, title, body, _buildDetails(body: body), payload: payload);
    return;
  } catch (e, st) {
    debugPrint('[NOTIF-BG-STANDALONE] show() failed with custom sound, '
        'retrying with default: $e\n$st');
  }

  try {
    await plugin.show(
      id,
      title,
      body,
      _buildDetails(body: body, forceDefaultSound: true),
      payload: payload,
    );
    return;
  } catch (e, st) {
    debugPrint('[NOTIF-BG-STANDALONE] show() failed with custom icon too, '
        'retrying with safe icon: $e\n$st');
  }

  try {
    await plugin.show(
      id,
      title,
      body,
      _buildDetails(body: body, forceDefaultSound: true, forceDefaultIcon: true),
      payload: payload,
    );
  } catch (e2, st2) {
    debugPrint('[NOTIF-BG-STANDALONE] show() failed even with default '
        'sound + safe icon — notification NOT shown: $e2\n$st2');
  }
}

// ═══════════════════════════════════════════════════════════════
// IN-APP ON-SCREEN BANNER
// ═══════════════════════════════════════════════════════════════
class _TopBanner {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show({
    required String title,
    required String body,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final overlay = NotificationService.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[NOTIF-BANNER] No overlay available yet — skipping on-screen popup '
          '(add navigatorKey: NotificationService.navigatorKey to your MaterialApp).');
      return;
    }

    _entry?.remove();
    _timer?.cancel();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _BannerWidget(
        title: title,
        body: body,
        icon: icon,
        color: color,
        onTap: () {
          onTap?.call();
        },
        onDismiss: () {
          if (_entry == entry) _entry = null;
          entry.remove();
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(const Duration(seconds: 6), () {
      if (_entry == entry) {
        _entry = null;
        entry.remove();
      }
    });
  }
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget> {
  bool _visible = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 220), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, -1.6),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: () {
                  _close();
                  widget.onTap();
                },
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < 0) _close();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: widget.color.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF212121))),
                          const SizedBox(height: 2),
                          Text(widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF757575), height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _close,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// NotificationService
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    } catch (e, st) {
      debugPrint('[NOTIF] Channel registration with custom sound failed: '
          '$e\n$st — retrying with default sound.');
      try {
        await _sharedPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_buildChannel(forceDefaultSound: true));
        debugPrint('[NOTIF] Channel registered with default sound fallback.');
      } catch (e2, st2) {
        debugPrint('[NOTIF] Channel registration failed even with default '
            'sound: $e2\n$st2');
      }
    }

    // FIX (the core bug): this used to pass `_smallIconDrawable`
    // directly into AndroidInitializationSettings. If that drawable
    // resource is missing/invalid, this call throws natively, the
    // outer catch below swallows it, and EVERYTHING after this block
    // — foreground listener, background-tap listener, token refresh
    // listener, token save, cold-start check — silently never runs.
    // That is why nothing rang or popped up. Using `_safeInitIcon`
    // (`@mipmap/ic_launcher`, guaranteed to exist) here removes that
    // failure point entirely. The custom icon is still applied
    // per-notification in `_buildDetails()`, with its own fallback
    // ladder in `_showTrayNotification`.
    try {
      await _sharedPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(_safeInitIcon),
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
      debugPrint('[NOTIF] ⚠️ Because init failed, NO notification listeners '
          'are attached — nothing will ring or pop up until this succeeds. '
          'This should now be very unlikely since init uses the safe '
          'launcher icon, but if you still see this, check '
          'POST_NOTIFICATIONS/EXACT_ALARM permissions and the '
          'notification_sound raw resource.');
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
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[NOTIF] ⚠️ Notification permission is DENIED. No '
          'notification — tray or otherwise — will ever appear until the '
          'user re-enables notifications for this app in system settings.');
    }

    if (!kIsWeb && Platform.isAndroid) {
      final granted = await _sharedPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('[NOTIF] POST_NOTIFICATIONS granted: $granted');
      if (granted == false) {
        debugPrint('[NOTIF] ⚠️ POST_NOTIFICATIONS was denied on Android 13+. '
            'flutter_local_notifications will silently do nothing on '
            'show() — no exception, no tray icon. This is the other '
            'common "silent" failure mode besides a bad sound/icon resource.');
      }

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

        if (_debugNotif) {
          debugPrint('=== NOTIF DEBUG (foreground) ===');
          debugPrint('  channelId : ${NotificationChannels.id}');
          debugPrint('  id        : $id');
          debugPrint('  title     : $title');
          debugPrint('  body      : $body');
          debugPrint('  dedupeKey : $dedupeKey');
          debugPrint('=================================');
        }

        // 1) System tray notification — rings / vibrates. Isolated so a
        // failure here can never block the banner below.
        final shown = await _showTrayNotification(
          id: id,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );
        debugPrint('[FCM-FG] tray show() succeeded=$shown id=$id');

        // 2) In-app on-screen banner — wrapped separately so a bug in
        // the banner layer (e.g. overlay not ready) can never suppress
        // the tray notification above, and vice versa.
        try {
          final style = bannerStyleForType(message.data['type']?.toString());
          _TopBanner.show(
            title: title,
            body: body,
            icon: style.icon,
            color: style.color,
            onTap: () => NotificationService.fireTap(message.data),
          );
        } catch (e, st) {
          debugPrint('[NOTIF-BANNER] failed to show in-app banner: $e\n$st');
        }
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

  Future<List<String>> _resolveAllProviderDocIds(String uid) async {
    if (uid.isEmpty) return const [];
    final db = FirebaseFirestore.instance;
    final ids = <String>{};

    try {
      final byUserId = await db
          .collection('providers')
          .where('userId', isEqualTo: uid)
          .get();
      ids.addAll(byUserId.docs.map((d) => d.id));

      final byUid = await db
          .collection('providers')
          .where('uid', isEqualTo: uid)
          .get();
      ids.addAll(byUid.docs.map((d) => d.id));
    } catch (e) {
      debugPrint('[FCM] _resolveAllProviderDocIds error: $e');
    }

    return ids.toList();
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

    await db.collection('users').doc(uid).set(tokenData, SetOptions(merge: true));
    debugPrint('[FCM] Token saved -> users/$uid (primary, uid-keyed)');

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      await db.collection('users').doc(email).set(tokenData, SetOptions(merge: true));
      debugPrint('[FCM] Token also mirrored -> users/$email (back-compat)');
    }

    try {
      final providerDocIds = await _resolveAllProviderDocIds(uid);
      if (providerDocIds.isEmpty) {
        debugPrint('[FCM] No provider profiles found for uid=$uid — '
            'nothing to mirror (fine if this login is a customer, not a provider).');
      }
      for (final id in providerDocIds) {
        await db.collection('providers').doc(id).set(tokenData, SetOptions(merge: true));
        debugPrint('[FCM] Token also saved -> providers/$id');
      }
      if (providerDocIds.length > 1) {
        debugPrint('[FCM] uid=$uid owns ${providerDocIds.length} provider profiles '
            '(${providerDocIds.join(", ")}) — token mirrored to ALL of them.');
      }
    } catch (e) {
      debugPrint('[FCM] provider token mirror error: $e');
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
      final providerDocIds = await _resolveAllProviderDocIds(uid);
      for (final id in providerDocIds) {
        await db.collection('providers').doc(id).update({
          'fcmToken': FieldValue.delete(),
        }).catchError((e) {
          debugPrint('[FCM] providers/$id token clear error (may not exist): $e');
        });
      }
    } catch (e) {
      debugPrint('[FCM] provider token clear error: $e');
    }

    await _fcm.deleteToken();
    debugPrint('[FCM] Token cleared on logout');
  }

  // Entry point business_dashboard_page.dart uses for its own instant
  // "new order available" alert.
  static Future<void> showLocalAlert({
    required String title,
    required String body,
    String? payload,
    required String dedupeKey,
  }) async {
    if (!_NotifDedupe.claim(dedupeKey)) {
      debugPrint('[NOTIF] showLocalAlert skipped — duplicate key="$dedupeKey"');
      return;
    }

    try {
      await NotificationService().initialize();
    } catch (e, st) {
      debugPrint('[NOTIF] showLocalAlert: initialize() failed: $e\n$st');
      // fall through and still attempt to show — plugin may already be
      // initialised from a previous call even if this one errored.
    }

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

    // 1) System tray notification.
    final shown = await _showTrayNotification(id: id, title: title, body: body, payload: payload);
    debugPrint('[NOTIF] showLocalAlert tray show() succeeded=$shown id=$id');

    // 2) In-app on-screen banner — independent of whether (1) succeeded.
    try {
      Map<String, dynamic>? parsedPayload;
      if (payload != null) {
        try {
          parsedPayload = jsonDecode(payload) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[NOTIF] showLocalAlert payload decode error: $e');
        }
      }
      final style = bannerStyleForType(parsedPayload?['type']?.toString());
      _TopBanner.show(
        title: title,
        body: body,
        icon: style.icon,
        color: style.color,
        onTap: () {
          if (parsedPayload != null) NotificationService.fireTap(parsedPayload);
        },
      );
    } catch (e, st) {
      debugPrint('[NOTIF-BANNER] showLocalAlert failed to show banner: $e\n$st');
    }
  }

  // ============================================================
  static Future<void> testNotification() async {
    await NotificationService().initialize();
    final shown = await _showTrayNotification(
      id: _uniqueNotifId(),
      title: '🔔 Test Notification',
      body: 'If you can see and hear this, local notifications are working '
          'correctly. Any missing ring elsewhere is happening upstream '
          '(Cloud Function / fcmToken / Firestore rules), not here.',
    );
    debugPrint('[NOTIF] testNotification() tray shown=$shown');
    _TopBanner.show(
      title: '🔔 Test Notification',
      body: 'On-screen banner is working too.',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF3F51B5),
    );
  }
}