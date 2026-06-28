import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// NOTIFICATION TYPE CONSTANTS
// ============================================================
class NotificationType {
  static const String newBooking       = 'new_booking';
  static const String accepted         = 'order_accepted';
  static const String rejected         = 'order_rejected';
  static const String cancelled        = 'order_cancelled';
  static const String completed        = 'order_completed';
  static const String userCancelled    = 'user_cancelled';
  static const String bookingAccepted  = 'booking_accepted';
  static const String bookingRejected  = 'booking_rejected';
  static const String serviceCompleted = 'service_completed';
}

// ============================================================
// ORDER STATUS CONSTANTS
// ============================================================
class OrderStatus {
  static const String pending   = 'pending';
  static const String accepted  = 'accepted';
  static const String rejected  = 'rejected';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String enquiry   = 'enquiry';
}

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================================
  // ORDER ID GENERATOR
  // ==========================================================
  static String generateOrderId(String userName) {
    final cleanName =
        userName.trim().toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cleanName}_$timestamp';
  }

  // ==========================================================
  // PROVIDER DOC ID RESOLVER
  //
  // Provider Firestore documents now use a readable ID
  // (e.g. CIV-765791) instead of the Firebase UID.
  // This helper resolves uid → readable doc ID via the
  // provider_uid_lookup collection written at registration.
  //
  // Returns null when no lookup entry exists.
  // ==========================================================
  static Future<String?> _getProviderDocId(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final snap =
          await _db.collection('provider_uid_lookup').doc(uid).get();
      final id = (snap.data()?['providerId'] ?? '').toString().trim();
      return id.isNotEmpty ? id : null;
    } catch (e) {
      debugPrint('[OrderService] _getProviderDocId error: $e');
      return null;
    }
  }

  // ==========================================================
  // PLACE ORDER
  //
  // After writing the order, this fans out a notification to
  // every APPROVED provider whose:
  //   • serviceType  matches the order's serviceType
  //   • categories[] contains the order's category  (if the
  //     order carries a category; falls back to all providers
  //     of that serviceType when category is absent)
  // ==========================================================
  static Future<DocumentReference> placeOrder({
    required String serviceType,
    required List<String> services,

    required String userId,
    required String userName,
    required String phone,
    String? email,

    required String createdBy,
    required String createdByRole,

    required String address,
    String? note,

    required DateTime date,
    required String time,

    required double totalAmount,

    int? adults,
    int? children,
    String? visitType,

    // The readable provider doc ID (e.g. CIV-765791), not the Firebase UID.
    // Only supplied when the caller already knows which provider to assign.
    String? providerId,

    // Category chosen by the customer (e.g. "Ice Blocks").
    // Used to filter which providers receive the notification.
    String? category,

    bool isEnquiry = false,

    // Legacy positional params kept for call-site compat
    String providerName = '',
    Object? providerUserId,
  }) async {
    // ── Resolve provider details ──────────────────────────────────────────────
    String resolvedProviderId     = providerId ?? '';
    String resolvedProviderName   = '';
    String resolvedProviderUserId = '';

    if (resolvedProviderId.isNotEmpty) {
      final snap = await _db
          .collection('providers')
          .doc(resolvedProviderId)
          .get();
      final d = snap.data() ?? {};
      resolvedProviderName   =
          (d['businessName'] ?? d['providerName'] ?? d['name'] ?? '')
              .toString();
      resolvedProviderUserId =
          (d['userId'] ?? d['uid'] ?? '').toString();
    }

    final orderId               = generateOrderId(userName);
    final docRef                = _db.collection('orders').doc(orderId);
    // FIX 1: Always store serviceType as lowercase so Firestore equality
    // queries from the dashboard (_svcNorm) match reliably.
    final normalizedServiceType = serviceType.trim().toLowerCase();
    // FIX 2: Normalise category the same way — trim only, keep original
    // casing so the UI can display it nicely, but compare via _normCat().
    final normalizedCategory    = (category ?? '').trim();

    await docRef.set({
      'orderId': orderId,
      'userId':  userId,

      'userName': userName,
      'phone':    phone,
      'email':    email ?? '',

      'user': {
        'id':    userId,
        'name':  userName,
        'phone': phone,
        'email': email ?? '',
      },

      'providerId':     resolvedProviderId,
      'providerUserId': resolvedProviderUserId,
      'providerName':   resolvedProviderName,

      'provider': {
        'providerId':     resolvedProviderId,
        'providerUserId': resolvedProviderUserId,
        'providerName':   resolvedProviderName,
      },

      // FIX 3: Store BOTH forms so old and new clients can read it.
      'serviceType': normalizedServiceType,   // lowercase — queried by dashboard
      'serviceName': normalizedServiceType,
      'services':    services,

      // Category stored exactly as the user chose it (original case).
      // The dashboard's _categoryMatch() uses _norm() on both sides so
      // "Software And Programming" == "software and programming" == "softwareandprogramming".
      'category': normalizedCategory,

      'date': Timestamp.fromDate(date),
      'time': time,

      'schedule': {
        'date': Timestamp.fromDate(date),
        'time': time,
      },

      'address': address.isEmpty ? 'Not Provided' : address,
      'note':    note ?? '',

      'location': {
        'address': address.isEmpty ? 'Not Provided' : address,
        'note':    note ?? '',
      },

      'totalAmount': totalAmount,

      'payment': {
        'totalAmount': totalAmount,
        'paid':        !isEnquiry,
        'method':      isEnquiry ? 'enquiry' : 'upi',
      },

      'adults':    adults    ?? 0,
      'children':  children  ?? 0,
      'visitType': visitType ?? '',

      'isEnquiry': isEnquiry,

      'status':      isEnquiry ? OrderStatus.enquiry : OrderStatus.pending,
      'isAssigned':  resolvedProviderId.isNotEmpty,
      'isCompleted': false,

      'declineReason': '',
      'cancelReason':  '',
      'cancelledBy':   '',

      'createdBy':     createdBy,
      'createdByRole': createdByRole,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ── Fan-out notification to matching providers ──────────────────────────
    await _notifyMatchingProviders(
      orderId:       orderId,
      serviceType:   normalizedServiceType,
      category:      normalizedCategory,
      userName:      userName,
      date:          date,
      time:          time,
      totalAmount:   totalAmount,
      specificProviderId: resolvedProviderId.isNotEmpty
          ? resolvedProviderId
          : null,
    );

    return docRef;
  }

  // ==========================================================
  // PROVIDER ACTIONS
  // ==========================================================

  static Future<void> acceptOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':     OrderStatus.accepted,
      'isAssigned': true,
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '✅ Booking Accepted',
      body:    '$providerName has accepted your $serviceType booking. '
               'They will contact you soon.',
      type:    NotificationType.bookingAccepted,
    );
  }

  static Future<void> rejectOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.rejected,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '❌ Booking Rejected',
      body:    '$providerName has rejected your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
    );
  }

  static Future<void> completeOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.completed,
      'isCompleted': true,
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🎉 Service Completed',
      body:    'Your $serviceType service by $providerName has been '
               'marked as completed. Thank you!',
      type:    NotificationType.serviceCompleted,
    );
  }

  static Future<void> providerCancelOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.cancelled,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🚫 Booking Cancelled by Provider',
      body:    '$providerName cancelled your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
    );
  }

  // ==========================================================
  // USER CANCELS ORDER
  // ==========================================================
  static Future<void> userCancelOrder({
    required String orderId,
    required String providerUserId,
    required String userName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.cancelled,
      'cancelledBy': 'user',
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    if (providerUserId.isNotEmpty) {
      await _sendNotification(
        receiverId: providerUserId,
        role:       'provider',
        orderId:    orderId,
        title:      '⚠️ Order Cancelled by User',
        body:       '$userName has cancelled their $serviceType booking.',
        type:       NotificationType.userCancelled,
      );

      final docId = await _getProviderDocId(providerUserId);
      if (docId != null) {
        // FIX 4: Use typed DocumentSnapshot to avoid shadowing the outer
        // `data` variable.  Renamed to `providerSnap` for clarity.
        final providerSnap = await _db.collection('providers').doc(docId).get();
        final providerData = providerSnap.data() ?? {};
        final fcmToken     = (providerData['fcmToken'] ?? '').toString().trim();

        if (fcmToken.isNotEmpty) {
          await _db.collection('fcm_queue').add({
            'token':      fcmToken,
            'receiverId': providerUserId,
            'providerId': docId,
            'orderId':    orderId,
            'title':      '⚠️ Order Cancelled by User',
            'body':       '$userName has cancelled their $serviceType booking.',
            'type':       NotificationType.userCancelled,
            'data': {
              'type':       NotificationType.userCancelled,
              'orderId':    orderId,
              'receiverId': providerUserId,
            },
            'sent':      false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // ==========================================================
  // FAN-OUT: notify ALL matching approved providers
  //
  // Matching rules (mirrors _AvailTab client-side filter):
  //   1. provider.status == 'approved'
  //   2. provider.serviceType == order.serviceType  (normalised)
  //   3. If order carries a category AND provider has categories[]:
  //        provider.categories must contain the order.category
  //        (comparison via _normCat — case/space insensitive)
  //      Else: notify all providers of that serviceType (fallback)
  //
  // When specificProviderId is given (direct assignment),
  // only that one provider is notified.
  // ==========================================================

  /// Normalise a category string for comparison:
  /// trim, lowercase, collapse whitespace / underscores / hyphens.
  /// Mirrors the `_norm()` helper in business_dashboard_page.dart.
  static String _normCat(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  static Future<void> _notifyMatchingProviders({
    required String orderId,
    required String serviceType,
    required String category,
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
    String? specificProviderId,
  }) async {
    try {
      if (specificProviderId != null && specificProviderId.isNotEmpty) {
        // Direct assignment — notify only this provider.
        final doc = await _db
            .collection('providers')
            .doc(specificProviderId)
            .get();
        if (!doc.exists) return;
        await _sendProviderNotification(
          providerId:  doc.id,
          orderId:     orderId,
          serviceType: serviceType,
          category:    category,
          userName:    userName,
          date:        date,
          time:        time,
          totalAmount: totalAmount,
        );
        return;
      }

      // Fetch all approved providers for this serviceType.
      final snap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: serviceType)
          .get();

      for (final doc in snap.docs) {
        final provData = doc.data();

        // ── Category filter ────────────────────────────────────────────
        // FIX 5: Use _normCat on BOTH sides so "Software And Programming"
        // matches "software and programming" and "softwareandprogramming".
        if (category.isNotEmpty) {
          final rawCats      = (provData['categories'] as List?) ?? [];
          final providerCats = rawCats.map((e) => _normCat(e.toString())).toList();

          // Provider has no categories saved → skip (should not happen post-v2)
          if (providerCats.isEmpty) continue;

          final orderCatNorm = _normCat(category);
          if (!providerCats.any((c) => c == orderCatNorm)) continue;
        }

        await _sendProviderNotification(
          providerId:  doc.id,
          orderId:     orderId,
          serviceType: serviceType,
          category:    category,
          userName:    userName,
          date:        date,
          time:        time,
          totalAmount: totalAmount,
        );
      }
    } catch (e) {
      debugPrint('[OrderService] _notifyMatchingProviders error: $e');
    }
  }

  // ── Send notification + FCM queue entry for one provider doc ──────────────
  // FIX 6: The original code had `final data = await _db...get()` which
  // returned a DocumentSnapshot but then accessed it as `data['fcmToken']`
  // (Map syntax). This caused a type error at runtime.
  // Fixed by calling `.data()` explicitly and renaming variable to `provMap`.
  static Future<void> _sendProviderNotification({
    required String providerId,
    required String orderId,
    required String serviceType,
    required String category,
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
  }) async {
    final provSnap = await _db.collection('providers').doc(providerId).get();
    if (!provSnap.exists) {
      debugPrint('[OrderService] Provider $providerId not found — skipping');
      return;
    }

    // FIX 7: Explicitly call .data() so we get Map<String, dynamic>
    // not DocumentSnapshot. Original code shadowed the variable name
    // and tried to use DocumentSnapshot as a Map.
    final provMap = provSnap.data()!;

    final providerUserId = (provMap['userId'] ?? provMap['uid'] ?? '').toString().trim();
    final providerName   =
        (provMap['businessName'] ?? provMap['providerName'] ?? provMap['name'] ?? '')
            .toString();

    if (providerUserId.isEmpty) {
      debugPrint('[OrderService] Provider $providerId has no userId — skipping');
      return;
    }

    final catLabel = category.isNotEmpty ? ' ($category)' : '';
    final title    = '📦 New Order Received';
    final body     =
        'Hi $providerName, new $serviceType$catLabel booking from $userName '
        'on ${_formatDate(date)} at $time.'
        '${totalAmount > 0 ? ' Amount ₹${totalAmount.toStringAsFixed(0)}' : ''}';

    // In-app notification document
    await _sendNotification(
      receiverId: providerUserId,
      role:       'provider',
      orderId:    orderId,
      title:      title,
      body:       body,
      type:       NotificationType.newBooking,
    );

    // FCM push via Cloud Function queue
    // FIX 8: Access fcmToken from provMap (Map), not provSnap (DocumentSnapshot).
    final fcmToken = (provMap['fcmToken'] ?? '').toString().trim();
    if (fcmToken.isNotEmpty) {
      await _db.collection('fcm_queue').add({
        'token':      fcmToken,
        'receiverId': providerUserId,
        'providerId': providerId,
        'orderId':    orderId,
        'title':      title,
        'body':       body,
        'type':       NotificationType.newBooking,
        'data': {
          'type':       NotificationType.newBooking,
          'orderId':    orderId,
          'receiverId': providerUserId,
        },
        'sent':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ==========================================================
  // NOTIFY USER — status updates from provider
  // ==========================================================
  static Future<void> notifyUser({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    required String type,
  }) async {
    if (userId.isEmpty) return;

    try {
      await _sendNotification(
        receiverId: userId,
        role:       'user',
        orderId:    orderId,
        title:      title,
        body:       body,
        type:       type,
      );

      final userDoc  = await _db.collection('users').doc(userId).get();
      final fcmToken =
          (userDoc.data()?['fcmToken'] ?? '').toString().trim();

      if (fcmToken.isNotEmpty) {
        await _db.collection('fcm_queue').add({
          'token':      fcmToken,
          'receiverId': userId,
          'orderId':    orderId,
          'title':      title,
          'body':       body,
          'type':       type,
          'data': {
            'type':       type,
            'orderId':    orderId,
            'receiverId': userId,
          },
          'sent':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[OrderService] notifyUser error: $e');
    }
  }

  // ==========================================================
  // INTERNAL: write to notifications collection
  // ==========================================================
  static Future<void> _sendNotification({
    required String receiverId,
    required String role,
    required String orderId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'receiverId': receiverId,
      'senderId':   '',
      'role':       role,
      'orderId':    orderId,
      'title':      title,
      'body':       body,
      'type':       type,
      'read':       false,
      'createdAt':  FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // DATE FORMATTER
  // ==========================================================
  static String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}