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
    // providerId is already the readable doc ID — fetch the doc directly.
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
    final normalizedServiceType = serviceType.trim().toLowerCase();
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

      'providerId':     resolvedProviderId,     // readable doc ID (CIV-765791)
      'providerUserId': resolvedProviderUserId, // Firebase UID — used for auth checks
      'providerName':   resolvedProviderName,

      'provider': {
        'providerId':     resolvedProviderId,
        'providerUserId': resolvedProviderUserId,
        'providerName':   resolvedProviderName,
      },

      'serviceType': normalizedServiceType,
      'serviceName': normalizedServiceType,
      'services':    services,

      // Category stored on the order so provider dashboard can
      // filter and the card can show a category chip.
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
      // If a specific provider was assigned, only notify that one.
      // Pass the readable doc ID directly — no lookup needed here.
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
    required String userId,       // customer Firebase UID
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
  //
  // providerUserId is the provider's Firebase UID (stored on
  // the order as providerUserId). We resolve it to the readable
  // doc ID only when we need to fetch the FCM token.
  // ==========================================================
  static Future<void> userCancelOrder({
    required String orderId,
    required String providerUserId,   // provider's Firebase UID
    required String userName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.cancelled,
      'cancelledBy': 'user',
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    if (providerUserId.isNotEmpty) {
      // In-app notification uses the UID as receiverId — unchanged.
      await _sendNotification(
        receiverId: providerUserId,
        role:       'provider',
        orderId:    orderId,
        title:      '⚠️ Order Cancelled by User',
        body:       '$userName has cancelled their $serviceType booking.',
        type:       NotificationType.userCancelled,
      );

      // Resolve UID → readable doc ID to fetch the FCM token.
      final docId = await _getProviderDocId(providerUserId);
      if (docId != null) {
        final snap      = await _db.collection('providers').doc(docId).get();
        final fcmToken  =
            (snap.data()?['fcmToken'] ?? '').toString().trim();

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
  //   2. provider.serviceType == order.serviceType
  //   3. If order carries a category AND provider has categories[]:
  //        provider.categories must contain the order.category
  //      Else: notify all providers of that serviceType (fallback)
  //
  // When specificProviderId is given (direct assignment),
  // only that one provider is notified.
  // specificProviderId is already the readable doc ID.
  // ==========================================================
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
      QuerySnapshot<Map<String, dynamic>> snap;

      if (specificProviderId != null && specificProviderId.isNotEmpty) {
        // Direct assignment — fetch just that one provider doc by readable ID.
        final doc = await _db
            .collection('providers')
            .doc(specificProviderId)
            .get();
        if (!doc.exists) return;
        await _sendProviderNotification(
          providerId: doc.id,
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

      // Fetch all approved providers with this serviceType.
      // Query uses field values, not doc ID — unaffected by the ID change.
      snap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: serviceType)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();

        // ── Category filter ────────────────────────────────────────────
        if (category.isNotEmpty) {
          final rawCats = (data['categories'] as List?) ?? [];
          final providerCats =
              rawCats.map((e) => e.toString().trim().toLowerCase()).toList();

          if (providerCats.isEmpty) continue;

          final orderCatNorm = category.trim().toLowerCase();
          if (!providerCats.any((c) => c == orderCatNorm)) continue;
        }

        await _sendProviderNotification(
          providerId: doc.id,
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
  // providerDoc.id  → readable doc ID (CIV-765791)  [stored as providerId]
  // data['userId']  → Firebase UID                  [stored as receiverId]
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
    final data             = await _db.collection('providers').doc(providerId).get();
    final providerUserId   =
        (data['userId'] ?? data['uid'] ?? '').toString().trim();
    final providerName     =
        (data['businessName'] ?? data['providerName'] ?? data['name'] ?? '')
            .toString();

    if (providerUserId.isEmpty) {
      debugPrint(
          '[OrderService] Provider ${providerId} has no userId — skipping');
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
    final fcmToken = (data['fcmToken'] ?? '').toString().trim();
    if (fcmToken.isNotEmpty) {
      await _db.collection('fcm_queue').add({
        'token':      fcmToken,
        'receiverId': providerUserId,         // Firebase UID
        'providerId': providerId,         // readable doc ID (CIV-765791)
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

