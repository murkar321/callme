import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  /// 🔥 COMMON ORDER SAVE (USED BY ALL BOOKING PAGES)
  static Future<void> placeOrder({
    required String serviceType,
    required List<String> services,

    required String userName,
    required String phone,
    String? email,

    required String address,
    String? note,

    required DateTime date,
    required String time,

    required double totalAmount,

    /// OPTIONAL
    int? adults,
    int? children,
    String? visitType,
    String? providerId,

  }) async {
    final docRef = _db.collection("orders").doc();

    await docRef.set({
      "orderId": docRef.id, // 🔥 IMPORTANT FOR TRACKING

      /// ================= CORE INFO =================
      "serviceType": serviceType,
      "services": services,

      /// ================= USER INFO =================
      "user": {
        "name": userName,
        "phone": phone,
        "email": email ?? "",
      },

      /// ================= BOOKING INFO =================
      "schedule": {
        "date": Timestamp.fromDate(date),
        "time": time,
      },

      "location": {
        "address": address.isEmpty ? "Not Provided" : address,
      },

      /// ================= SERVICE SPECIFIC =================
      "meta": {
        "adults": adults ?? 0,
        "children": children ?? 0,
        "visitType": visitType ?? "standard",
        "providerId": providerId ?? "",
      },

      /// ================= PAYMENT =================
      "payment": {
        "totalAmount": totalAmount,
        "currency": "INR",
        "paid": false,
      },

      /// ================= STATUS =================
      "status": "pending", // pending → accepted → completed → rejected

      /// ================= TIMESTAMP =================
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 UPDATE STATUS (FOR PROVIDER / ADMIN LATER)
  static Future<void> updateStatus(
      String orderId,
      String status,
      ) async {
    await _db.collection("orders").doc(orderId).update({
      "status": status,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 MARK PAYMENT (FUTURE)
  static Future<void> markPaid(String orderId) async {
    await _db.collection("orders").doc(orderId).update({
      "payment.paid": true,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}