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
    // FIX: previously always opened the generic BusinessPage list. Now
    // tries the fast path straight to the matching service's own
    // dashboard first, and only falls back to BusinessPage if an older
    // notification is missing the required fields.
    case NotificationType.newBooking:
      await _routeToProviderDashboard(
        navigator,
        data,
        fallbackToBusinessPage: true,
      );
      break;

    // ── Provider: the order was cancelled by the customer ─────────────────────
    // NEW: takes the provider straight to the dashboard of the specific
    // service the cancelled order belonged to, same fast-path logic as
    // newBooking, so they land on the right "Available Jobs" tab instead
    // of a generic list.
    case NotificationType.orderCancelled:
      await _routeToProviderDashboard(
        navigator,
        data,
        fallbackToBusinessPage: true,
      );
      break;

    // ── Provider: order is no longer available (another provider accepted it,
    //    or it expired/was auto-closed before anyone accepted) ────────────────
    // NEW: same fast-path routing — provider should land on their specific
    // service dashboard, not a generic list, so they can immediately see
    // other available jobs for that category.
    case NotificationType.orderUnavailable:
      await _routeToProviderDashboard(
        navigator,
        data,
        fallbackToBusinessPage: true,
      );
      break;

    // ── Provider: the CUSTOMER cancelled the order directly ────────────────────
    // FIX (NEW): this notification type — 'user_cancelled', sent by
    // OrderService.userCancelOrder() — used to have no case here at all,
    // so it silently fell into `default` below, which pushed the
    // PROVIDER onto MyOrdersPage — a customer-facing screen keyed by
    // email. That's the wrong destination entirely for a provider.
    //
    // The fcm_queue payload written by userCancelOrder() only carries
    // `providerId` + `serviceType` (no `businessName`), so the fast
    // path in _routeToProviderDashboard would never have enough to
    // build the dashboard directly. fallbackToBusinessPage is set to
    // FALSE here (unlike newBooking/orderCancelled/orderUnavailable
    // above) so it falls through to _routeToDashboard(), which looks
    // up the provider's own Firestore doc and opens their REAL
    // BusinessDashboardPage with the correct business name — not just
    // the generic BusinessPage list.
    case 'user_cancelled':
      await _routeToProviderDashboard(
        navigator,
        data,
        fallbackToBusinessPage: false,
      );
      break;

    // ── Provider: an order they could have taken is no longer available
    //    (another provider accepted it first) ───────────────────────────────
    // FIX (NEW): this notification type — 'order_taken_by_other', sent by
    // OrderService.notifyOthersOrderTaken() — also had no case here and
    // fell into `default`, sending the provider to MyOrdersPage instead
    // of their own dashboard. Same reasoning as 'user_cancelled' above:
    // this payload doesn't carry `businessName` either, so
    // fallbackToBusinessPage is FALSE to let the Firestore-lookup
    // fallback build the real dashboard.
    case 'order_taken_by_other':
      await _routeToProviderDashboard(
        navigator,
        data,
        fallbackToBusinessPage: false,
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

    // ── Provider: registration approved → open their dashboard ────────────────
    case NotificationType.registrationApproved:
      await _routeToProviderDashboard(navigator, data);
      break;

    // ── Provider: registration rejected → back to the registration/status page ─
    // FIX: this used to also open BusinessDashboardPage, which is wrong —
    // a rejected provider shouldn't land on the active provider dashboard.
    case NotificationType.registrationRejected:
      debugPrint('[NOTIF-ROUTE] → BusinessPage (registration rejected)');
      navigator.push(
        MaterialPageRoute(builder: (_) => const BusinessPage()),
      );
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
// _routeToProviderDashboard

// ─────────────────────────────────────────────────────────────────────────────
Future<void> _routeToProviderDashboard(
  NavigatorState navigator,
  Map<String, dynamic> data, {
  bool fallbackToBusinessPage = false,
}) async {
  final providerId   = data['providerId']?.toString().trim() ?? '';
  final businessName = data['businessName']?.toString().trim() ?? '';
  final serviceType  = data['serviceType']?.toString().trim() ?? '';

  if (providerId.isNotEmpty && businessName.isNotEmpty && serviceType.isNotEmpty) {
    debugPrint(
      '[NOTIF-ROUTE] → BusinessDashboardPage (fast path) '
      'providerId=$providerId businessName=$businessName serviceType=$serviceType',
    );
    navigator.push(
      MaterialPageRoute(
        builder: (_) => BusinessDashboardPage(
          providerId:   providerId,
          businessName: businessName,
          serviceType:  serviceType,
        ),
      ),
    );
    return;
  }

  if (fallbackToBusinessPage) {
    debugPrint(
      '[NOTIF-ROUTE] Payload missing providerId/businessName/serviceType '
      '— opening BusinessPage (can\'t safely guess which registered '
      'service this belongs to)',
    );
    navigator.push(MaterialPageRoute(builder: (_) => const BusinessPage()));
    return;
  }

  debugPrint(
    '[NOTIF-ROUTE] Payload missing providerId/businessName/serviceType '
    '— falling back to Firestore lookup',
  );
  await _routeToDashboard(navigator);
}

// ─────────────────────────────────────────────────────────────────────────────
// _routeToDashboard (fallback)
// ─────────────────────────────────────────────────────────────────────────────
// Fetches the provider document for the current user from Firestore, then
// opens BusinessDashboardPage with real data. Only used when the
// notification payload doesn't already carry providerId/businessName/
// serviceType (e.g. older notifications).
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