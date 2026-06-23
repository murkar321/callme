
import 'package:callme/profile/navigation.dart';
import 'package:callme/profile/notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'notification_service.dart';

import '../provider/business_page.dart';
import '../screens/myorders_page.dart';


// TODO: if you have a dedicated admin approve/reject page (separate from
// the dashboard), swap this import + the AdminDashboard() reference below
// for that page instead, e.g.:
//   import '../Admin/provider_approval_page.dart';
//   ... ProviderApprovalPage()
import '../Admin/admin_dashboard.dart';

/// Single source of truth for "which screen opens when this notification
/// is tapped" — used for foreground taps, background taps, and cold
/// starts alike, so behaviour is consistent no matter how the app was
/// opened.
void routeNotification(Map<String, dynamic> data) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) {
    debugPrint('[NOTIF-ROUTE] navigator not ready yet, dropping tap: $data');
    return;
  }

  final type = data['type']?.toString();
  debugPrint('[NOTIF-ROUTE] routing type="$type" data=$data');

  switch (type) {
    case NotificationType.newBooking:
      // The provider received a new order — open Business page, where
      // their incoming orders are listed.
      navigator.push(
        MaterialPageRoute(builder: (_) => const BusinessPage()),
      );
      break;

    case NotificationType.bookingAccepted:
    case NotificationType.bookingRejected:
      // The customer who placed the order needs to see its status.
      // MyOrdersPage requires a phone number — falls back to the
      // currently signed-in user's phone. If your account flow allows
      // email-only sign-in with no phone, this may come back empty; in
      // that case MyOrdersPage's own query will need to handle it (e.g.
      // by uid instead of phone) — let me know if that's the case.
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
      navigator.push(
        MaterialPageRoute(builder: (_) => MyOrdersPage(phone: phone)),
      );
      break;

    case NotificationType.providerRegistered:
      // Admin needs to review the newly registered provider.
      navigator.push(
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
      break;

    case NotificationType.registrationApproved:
    case NotificationType.registrationRejected:
      // No specific page given for these yet — falls back to the
      // notification list. Tell me where these should go and I'll wire it.
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationPage()),
      );
      break;

    default:
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationPage()),
      );
  }
}
