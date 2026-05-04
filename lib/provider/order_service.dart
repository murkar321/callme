import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

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

    final docRef = _db.collection("orders").doc();

    /// 🔥 ALWAYS NORMALIZE
    final normalizedServiceType = serviceType.trim().toLowerCase();

    await docRef.set({
      "orderId": docRef.id,
      "userId": userId,

      /// ✅ ALWAYS EMPTY STRING (NEVER NULL)
      "providerId": providerId ?? "",
      "providerUserId": providerUserId ?? "",
      "providerName": providerName ?? "",

      /// 🔥 IMPORTANT FLAGS
      "isAssigned": false,
      "isCompleted": false,

      "createdBy": createdBy,
      "createdByRole": createdByRole,

      /// 🔥 SERVICE TYPE FIX
      "serviceType": normalizedServiceType,

      "services": services,

      "user": {
        "name": userName,
        "phone": phone,
        "email": email ?? "",
      },

      "schedule": {
        "date": Timestamp.fromDate(date),
        "time": time,
      },

      "location": {
        "address": address.isEmpty ? "Not Provided" : address,
        "note": note ?? "",
      },

      /// 🔥 META CLEAN STRUCTURE
      "meta": {
        "adults": adults ?? 0,
        "children": children ?? 0,
        "visitType": visitType ?? "",
        "isEnquiry": isEnquiry,
      },

      /// 💰 PAYMENT
      "payment": {
        "totalAmount": totalAmount,
        "paid": isEnquiry ? false : true,
        "method": isEnquiry ? "enquiry" : "upi",
      },

      /// 🔥 STATUS LOGIC
      "status": isEnquiry ? "enquiry" : "pending",

      /// 🔥 TRACKING
      "lastActionBy": "user",
      "lastActionAt": FieldValue.serverTimestamp(),

      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return docRef;
  }
}