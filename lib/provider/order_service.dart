import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// NOTIFICATION TYPE CONSTANTS
// ============================================================
class NotificationType {
  // ── existing constants (kept as-is) ──────────────────────
  static const String newBooking    = 'new_booking';
  static const String accepted      = 'order_accepted';
  static const String rejected      = 'order_rejected';
  static const String cancelled     = 'order_cancelled';
  static const String completed     = 'order_completed';
  static const String userCancelled = 'user_cancelled';

  // ── FIX: was `=> null`, now proper string constants ───────
  // These must match the switch-case strings in the notification router.
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
  // PLACE ORDER
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

    required String providerId,

    bool isEnquiry = false,
    required String providerName,
    Object? providerUserId,
  }) async {
    // Resolve provider details fresh from Firestore.
    final providerSnap =
        await _db.collection('providers').doc(providerId).get();
    final providerData = providerSnap.data() ?? {};

    final String resolvedProviderName =
        (providerData['businessName'] ?? providerData['name'] ?? '')
            .toString();
    final String resolvedProviderUserId =
        (providerData['userId'] ?? providerData['uid'] ?? '').toString();

    final orderId = generateOrderId(userName);
    final docRef  = _db.collection('orders').doc(orderId);
    final normalizedServiceType = serviceType.trim().toLowerCase();

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

      'providerId':      providerId,
      'providerUserId':  resolvedProviderUserId,
      'providerName':    resolvedProviderName,

      'provider': {
        'providerId':      providerId,
        'providerUserId':  resolvedProviderUserId,
        'providerName':    resolvedProviderName,
      },

      'serviceType': normalizedServiceType,
      'serviceName': normalizedServiceType,
      'services':    services,

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
      'isAssigned':  false,
      'isCompleted': false,

      // Reason fields — always empty strings so reads never get null.
      'declineReason': '',  // canonical field for reject / provider-cancel reason
      'cancelReason':  '',  // legacy fallback
      'cancelledBy':   '',  // 'user' | 'provider'

      'createdBy':     createdBy,
      'createdByRole': createdByRole,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifyProvider(
      providerId:        providerId,
      providerUserId:    resolvedProviderUserId,
      providerName:      resolvedProviderName,
      orderId:           orderId,
      serviceType:       normalizedServiceType,
      userName:          userName,
      date:              date,
      time:              time,
      totalAmount:       totalAmount,
      providerData:      providerData,
    );

    return docRef;
  }

  // ==========================================================
  // PROVIDER ACTIONS
  // ==========================================================

  /// Provider ACCEPTS the order.
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
      type:    NotificationType.bookingAccepted,   // FIX: was NotificationType.accepted
    );
  }

  /// Provider REJECTS the order (with mandatory reason).
  /// Writes to `declineReason` (canonical) AND legacy `cancelReason`.
  static Future<void> rejectOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':              OrderStatus.rejected,
      'declineReason':       trimmedReason,   // canonical
      'cancelReason':        trimmedReason,   // legacy fallback
      'cancelledBy':         'provider',
      'providerCancelNote':  trimmedReason,   // extra legacy compat
      'updatedAt':           FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '❌ Booking Rejected',
      body:    '$providerName has rejected your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,   // FIX: was NotificationType.rejected
    );
  }

  /// Provider COMPLETES the order.
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
      type:    NotificationType.serviceCompleted,   // FIX: was NotificationType.completed
    );
  }

  /// Provider CANCELS the order after accepting (with reason).
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
      'declineReason':      trimmedReason,   // canonical
      'cancelReason':       trimmedReason,   // legacy
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
      type:    NotificationType.bookingRejected,   // FIX: was NotificationType.cancelled
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
    }
  }

  // ==========================================================
  // NOTIFY PROVIDER — new booking
  // ==========================================================
  static Future<void> _notifyProvider({
    required String providerId,
    required String providerUserId,
    required String providerName,
    required String orderId,
    required String serviceType,
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
    required Map<String, dynamic> providerData,
  }) async {
    if (providerUserId.isEmpty) {
      debugPrint('[OrderService] providerUserId empty — skipping notification');
      return;
    }

    final title = '📦 New Order Received';
    final body  =
        'Hi $providerName, new $serviceType booking from $userName '
        'on ${_formatDate(date)} at $time. '
        'Amount ₹${totalAmount.toStringAsFixed(0)}';

    try {
      await _sendNotification(
        receiverId: providerUserId,
        role:       'provider',
        orderId:    orderId,
        title:      title,
        body:       body,
        type:       NotificationType.newBooking,
      );

      final fcmToken =
          (providerData['fcmToken'] ?? '').toString().trim();
      if (fcmToken.isNotEmpty) {
        await _db.collection('fcm_queue').add({
          'token':       fcmToken,
          'receiverId':  providerUserId,
          'providerId':  providerId,
          'orderId':     orderId,
          'title':       title,
          'body':        body,
          'type':        NotificationType.newBooking,
          'data': {
            'type':       NotificationType.newBooking,
            'orderId':    orderId,
            'receiverId': providerUserId,
          },
          'sent':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[OrderService] _notifyProvider error: $e');
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

      final userDoc =
          await _db.collection('users').doc(userId).get();
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