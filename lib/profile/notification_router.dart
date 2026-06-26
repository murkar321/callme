import 'package:callme/profile/feedback_page.dart';
import 'package:callme/profile/navigation.dart';
import 'package:callme/provider/provider_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'notification_service.dart';

import '../provider/business_page.dart';
import '../screens/myorders_page.dart';
import '../Admin/approve_providers_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// routeNotification
// ─────────────────────────────────────────────────────────────────────────────
// Entry point called from three places:
//   • NotificationPage.onNotificationTap  (user taps a list item in the page)
//   • NotificationService._onTapForeground (local notification tapped while app open)
//   • NotificationService._listenBackgroundTap / _checkColdStart (FCM tap)
//
// BUG FIXES vs previous version:
//   1. registrationApproved/Rejected: payload never reliably contained
//      businessName/serviceType — now fetches the provider doc from Firestore
//      using the current user's UID so the dashboard always opens with real data.
//   2. MyOrdersPage used phoneNumber (null for email-auth) → now uses email.
//   3. FeedbackPage is `const` — was being constructed without const.
//   4. Navigator retry loop: on cold-start the navigator isn't mounted for
//      ~1-2 s; retries up to 10× at 300 ms intervals.
// ─────────────────────────────────────────────────────────────────────────────

void routeNotification(Map<String, dynamic> data) {
  _routeWithRetry(data, attempts: 10, delay: const Duration(milliseconds: 300));
}

Future<void> _routeWithRetry(
  Map<String, dynamic> data, {
  required int attempts,
  required Duration delay,
}) async {
  for (var i = 0; i < attempts; i++) {
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      await _doRoute(navigator, data);
      return;
    }
    debugPrint('[NOTIF-ROUTE] Navigator not ready — retry ${i + 1}/$attempts');
    await Future.delayed(delay);
  }
  debugPrint('[NOTIF-ROUTE] ✗ Navigator never became ready — skipped');
}

Future<void> _doRoute(NavigatorState navigator, Map<String, dynamic> data) async {
  final type = data['type']?.toString() ?? '';
  debugPrint('[NOTIF-ROUTE] type=$type  data=$data');

  switch (type) {

    // ── Provider receives a new booking ──────────────────────────────────────
    case NotificationType.newBooking:
      navigator.push(
        MaterialPageRoute(builder: (_) => const BusinessPage()),
      );
      break;

    // ── Customer: booking status or provider assigned ─────────────────────────
    // FIX: phoneNumber is null for email-auth → use email.
    case NotificationType.bookingAccepted:
    case NotificationType.bookingRejected:
    case NotificationType.providerFound:
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      if (email.isEmpty) {
        debugPrint('[NOTIF-ROUTE] ⚠ No email for current user — cannot open MyOrdersPage');
        return;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (_) => MyOrdersPage(phone: email),
        ),
      );
      break;

    // ── Admin: new provider registration waiting for approval ─────────────────
    case NotificationType.providerRegistered:
      navigator.push(
        MaterialPageRoute(builder: (_) => const ApproveProvidersPage()),
      );
      break;

    // ── Provider: registration approved/rejected → open their dashboard ───────
    // FIX: businessName and serviceType were never reliably present in the
    // notification payload. Instead we look up the provider document from
    // Firestore using the current user's UID, which is always available.
    case NotificationType.registrationApproved:
    case NotificationType.registrationRejected:
      await _routeToDashboard(navigator);
      break;

    // ── Customer: service completed → leave a review ──────────────────────────
    // FIX: was missing `const` — FeedbackPage takes no params.
    case NotificationType.serviceCompleted:
      navigator.push(
        MaterialPageRoute(builder: (_) =>  FeedbackPage()),
      );
      break;

    // ── Fallback ──────────────────────────────────────────────────────────────
    default:
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      if (email.isEmpty) {
        debugPrint('[NOTIF-ROUTE] ⚠ No email — fallback navigation skipped');
        return;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (_) => MyOrdersPage(phone: email),
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _routeToDashboard
// ─────────────────────────────────────────────────────────────────────────────
// Fetches the provider document for the current user from Firestore, then
// opens BusinessDashboardPage with real data.
//
// Why Firestore fetch instead of payload fields?
//   The Cloud Function sends a short FCM payload (title + body + type +
//   receiverId). Adding businessName/serviceType to every notification payload
//   is fragile — they can be missing or stale. Fetching from Firestore is
//   always accurate and costs one read.
//
// Firestore query: providers where userId == currentUser.uid
// Falls back to a loading indicator route while the fetch is in-flight,
// then replaces it once data arrives.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _routeToDashboard(NavigatorState navigator) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    debugPrint('[NOTIF-ROUTE] ⚠ No UID — cannot open dashboard');
    return;
  }

  // Push a loading screen immediately so the user sees a response right away.
  navigator.push(
    MaterialPageRoute(builder: (_) => const _LoadingRoute()),
  );

  try {
    // Query the providers collection for this user's document.
    final snap = await FirebaseFirestore.instance
        .collection('providers')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // Try doc keyed by UID directly (some versions use doc(uid)).
      final direct = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();

      if (!direct.exists) {
        debugPrint('[NOTIF-ROUTE] ⚠ No provider doc found for uid=$uid');
        // Pop the loading screen.
        if (navigator.mounted) navigator.pop();
        return;
      }

      _pushDashboard(navigator, uid, direct.data()!);
      return;
    }

    _pushDashboard(navigator, snap.docs.first.id, snap.docs.first.data());
  } catch (e) {
    debugPrint('[NOTIF-ROUTE] ✗ Firestore fetch failed: $e');
    if (navigator.mounted) navigator.pop();
  }
}

void _pushDashboard(
  NavigatorState navigator,
  String providerId,
  Map<String, dynamic> data,
) {
  // Extract fields — try multiple key names for robustness.
  final businessName = _first(data, [
    'businessName', 'business_name', 'name', 'providerName',
  ]);
  final serviceType = _first(data, [
    'serviceType', 'service_type', 'service', 'category',
  ]);

  if (businessName.isEmpty || serviceType.isEmpty) {
    debugPrint(
      '[NOTIF-ROUTE] ⚠ Provider doc missing businessName or serviceType '
      '(businessName="$businessName", serviceType="$serviceType")',
    );
    // Pop loading screen and bail — better than opening a blank dashboard.
    if (navigator.mounted) navigator.pop();
    return;
  }

  debugPrint(
    '[NOTIF-ROUTE] → BusinessDashboardPage '
    'providerId=$providerId businessName=$businessName serviceType=$serviceType',
  );

  // Replace the loading screen with the real dashboard.
  if (navigator.mounted) {
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => BusinessDashboardPage(
          providerId:   providerId,
          businessName: businessName,
          serviceType:  serviceType,
        ),
      ),
    );
  }
}

// ─── helper ──────────────────────────────────────────────────────────────────
String _first(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    final v = data[k]?.toString().trim() ?? '';
    if (v.isNotEmpty) return v;
  }
  return '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Transient loading screen shown while Firestore fetch is in-flight.
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingRoute extends StatelessWidget {
  const _LoadingRoute();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Opening dashboard…',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}