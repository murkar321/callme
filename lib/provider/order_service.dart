import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================
  // ORDER ID GENERATOR
  // ===========================================================

  static String generateOrderId(String userName) {
    final cleanName = userName.trim().toLowerCase().replaceAll(" ", "");
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "${cleanName}_$timestamp";
  }

  // ===========================================================
  // PLACE ORDER
  // ===========================================================

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

    String? providerId,
    String? providerName,
    String? providerUserId,

    bool isEnquiry = false,
  }) async {

    final orderId = generateOrderId(userName);
    final docRef = _db.collection("orders").doc(orderId);

    final now = FieldValue.serverTimestamp();
    final normalizedServiceType = serviceType.trim().toLowerCase();

    // ===========================================================
    // SAVE ORDER (UNCHANGED LOGIC)
    // ===========================================================

    await docRef.set({
      "orderId": orderId,
      "userId": userId,

      "userName": userName,
      "phone": phone,
      "email": email ?? "",

      "user": {
        "id": userId,
        "name": userName,
        "phone": phone,
        "email": email ?? "",
      },

      "providerId": providerId ?? "",
      "providerUserId": providerUserId ?? "",
      "providerName": providerName ?? "",

      "provider": {
        "providerId": providerId ?? "",
        "providerUserId": providerUserId ?? "",
        "providerName": providerName ?? "",
      },

      "serviceType": normalizedServiceType,
      "serviceName": normalizedServiceType,
      "services": services,

      "date": Timestamp.fromDate(date),
      "time": time,

      "schedule": {
        "date": Timestamp.fromDate(date),
        "time": time,
      },

      "address": address.isEmpty ? "Not Provided" : address,
      "note": note ?? "",

      "location": {
        "address": address.isEmpty ? "Not Provided" : address,
        "note": note ?? "",
      },

      "totalAmount": totalAmount,

      "payment": {
        "totalAmount": totalAmount,
        "paid": !isEnquiry,
        "method": isEnquiry ? "enquiry" : "upi",
      },

      "adults": adults ?? 0,
      "children": children ?? 0,
      "visitType": visitType ?? "",

      "isEnquiry": isEnquiry,

      "status": isEnquiry ? "enquiry" : "pending",
      "isAssigned": false,
      "isCompleted": false,

      "createdBy": createdBy,
      "createdByRole": createdByRole,

      "createdAt": now,
      "updatedAt": now,
    });

    // ===========================================================
    // 🔥 CREATE NOTIFICATION FOR PROVIDER
    // ===========================================================

    if (providerId != null && providerId.isNotEmpty) {
      await _createProviderNotification(
        providerId: providerId,
        providerName: providerName ?? "Provider",
        orderId: orderId,
        serviceType: normalizedServiceType,
        userName: userName,
        date: date,
        time: time,
        totalAmount: totalAmount,
      );
    }

    return docRef;
  }

  // ===========================================================
  // NOTIFICATION CREATOR (FIXED FOR YOUR PAGE)
  // ===========================================================

  static Future<void> _createProviderNotification({
    required String providerId,
    required String providerName,
    required String orderId,
    required String serviceType,
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
  }) async {
    try {
      final title = "New Order Received 📦";

      final body =
          "Hi $providerName, new $serviceType order from $userName "
          "scheduled on ${_formatDate(date)} at $time. "
          "Amount ₹${totalAmount.toStringAsFixed(0)}";

      // ===========================================================
      // 🔥 IN-APP NOTIFICATION (IMPORTANT FIX)
      // matches YOUR NotificationPage structure
      // ===========================================================

      await _db.collection("notifications").add({
        "receiverId": providerId,     // 🔥 FIXED (matches your page)
        "role": "provider",
        "orderId": orderId,

        "title": title,
        "body": body,

        "type": "new_order",
        "read": false,

        "createdAt": FieldValue.serverTimestamp(),
      });

      // ===========================================================
      // 🔥 FCM QUEUE (for push notification later)
      // ===========================================================

      final providerDoc =
          await _db.collection("providers").doc(providerId).get();

      final fcmToken =
          (providerDoc.data()?["fcmToken"] ?? "").toString();

      if (fcmToken.isNotEmpty) {
        await _db.collection("fcm_queue").add({
          "token": fcmToken,
          "title": title,
          "body": body,
          "type": "new_order",
          "orderId": orderId,
          "receiverId": providerId,
          "sent": false,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("NOTIFICATION ERROR: $e");
    }
  }

  // ===========================================================
  // DATE FORMATTER
  // ===========================================================

  static String _formatDate(DateTime date) {
    const months = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    return "${date.day} ${months[date.month]} ${date.year}";
  }
}