import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// ORDER SERVICE
/// Handles order creation and FCM notifications to provider
/// when a new order is placed.
/// ============================================================

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================
  // GENERATE ORDER ID
  // ===========================================================

  static String generateOrderId(String userName) {
    final cleanName = userName
        .trim()
        .toLowerCase()
        .replaceAll(" ", "");

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return "${cleanName}_$timestamp";
  }

  // ===========================================================
  // PLACE ORDER
  // All original fields preserved exactly.
  // Added: notifies assigned provider via FCM after save.
  // ===========================================================

  static Future<DocumentReference> placeOrder({
    required String       serviceType,
    required List<String> services,

    required String userId,
    required String userName,
    required String phone,

    String? email,

    required String createdBy,
    required String createdByRole,

    required String address,
    String?         note,

    required DateTime date,
    required String   time,

    required double totalAmount,

    int?    adults,
    int?    children,
    String? visitType,

    String? providerId,
    String? providerName,
    String? providerUserId,

    bool isEnquiry = false,
  }) async {
    final orderId = generateOrderId(userName);
    final docRef  = _db.collection("orders").doc(orderId);

    final normalizedServiceType = serviceType.trim().toLowerCase();
    final now = FieldValue.serverTimestamp();

    // ── Build order payload (identical to original) ──────────

    await docRef.set({
      // IDS
      "orderId": orderId,
      "userId":  userId,

      // USER DATA
      "userName": userName,
      "phone":    phone,
      "email":    email ?? "",
      "user": {
        "id":    userId,
        "name":  userName,
        "phone": phone,
        "email": email ?? "",
      },

      // PROVIDER
      "providerId":     providerId     ?? "",
      "providerUserId": providerUserId ?? "",
      "providerName":   providerName   ?? "",
      "provider": {
        "providerId":     providerId     ?? "",
        "providerUserId": providerUserId ?? "",
        "providerName":   providerName   ?? "",
      },

      // SERVICE
      "serviceType": normalizedServiceType,
      "serviceName": normalizedServiceType,
      "services":    services,

      // SCHEDULE
      "date":     Timestamp.fromDate(date),
      "time":     time,
      "schedule": {
        "date": Timestamp.fromDate(date),
        "time": time,
      },

      // LOCATION
      "address":  address.isEmpty ? "Not Provided" : address,
      "note":     note ?? "",
      "location": {
        "address": address.isEmpty ? "Not Provided" : address,
        "note":    note ?? "",
      },

      // PAYMENT
      "totalAmount": totalAmount,
      "payment": {
        "totalAmount": totalAmount,
        "paid":        !isEnquiry,
        "method":      isEnquiry ? "enquiry" : "upi",
      },

      // META
      "adults":    adults   ?? 0,
      "children":  children ?? 0,
      "visitType": visitType ?? "",
      "isEnquiry": isEnquiry,
      "meta": {
        "adults":    adults   ?? 0,
        "children":  children ?? 0,
        "visitType": visitType ?? "",
        "isEnquiry": isEnquiry,
      },

      // STATUS
      "status":      isEnquiry ? "enquiry" : "pending",
      "isAssigned":  false,
      "isCompleted": false,

      // TRACKING
      "createdBy":     createdBy,
      "createdByRole": createdByRole,
      "lastActionBy":  "user",
      "lastActionAt":  now,
      "createdAt":     now,
      "updatedAt":     now,
    });

    // ── Notify assigned provider about new order ─────────────

    if (providerId != null && providerId.isNotEmpty) {
      await _notifyProviderNewOrder(
        providerId:   providerId,
        providerName: providerName ?? "Provider",
        orderId:      orderId,
        serviceType:  normalizedServiceType,
        userName:     userName,
        date:         date,
        time:         time,
        totalAmount:  totalAmount,
      );
    }

    return docRef;
  }

  // ===========================================================
  // NOTIFY PROVIDER — NEW ORDER ASSIGNED
  // Fetches provider FCM token and queues push + in-app alert.
  // ===========================================================

  static Future<void> _notifyProviderNewOrder({
    required String   providerId,
    required String   providerName,
    required String   orderId,
    required String   serviceType,
    required String   userName,
    required DateTime date,
    required String   time,
    required double   totalAmount,
  }) async {
    try {
      final providerDoc = await _db
          .collection("providers")
          .doc(providerId)
          .get();

      if (!providerDoc.exists) return;

      final fcmToken =
          (providerDoc.data()?["fcmToken"] ?? "").toString().trim();

      final String title = "📦 New Order Received!";
      final String body  =
          "Hi $providerName, you have a new $serviceType order from "
          "$userName scheduled on "
          "${_formatDate(date)} at $time. "
          "Amount: ₹${totalAmount.toStringAsFixed(0)}";

      // In-app notification
      await _db.collection("notifications").add({
        "userType":    "provider",
        "providerId":  providerId,
        "orderId":     orderId,
        "title":       title,
        "body":        body,
        "type":        "new_order",
        "read":        false,
        "createdAt":   FieldValue.serverTimestamp(),
      });

      // FCM push via queue
      if (fcmToken.isNotEmpty) {
        await _db.collection("fcm_queue").add({
          "token":      fcmToken,
          "title":      title,
          "body":       body,
          "type":       "new_order",
          "orderId":    orderId,
          "providerId": providerId,
          "sent":       false,
          "createdAt":  FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Non-fatal — order was already saved successfully
      print("ORDER NOTIFY ERROR: $e");
    }
  }

  // ===========================================================
  // DATE FORMATTER (internal helper)
  // ===========================================================

  static String _formatDate(DateTime date) {
    const months = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }
}