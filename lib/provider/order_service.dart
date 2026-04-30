import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final _db = FirebaseFirestore.instance;

  static Future<DocumentReference> placeOrder({
    required String serviceType,
    required List<String> services,

    /// 👤 CUSTOMER
    required String userId,
    required String userName,
    required String phone,
    String? email,

    /// 🔥 WHO CREATED
    required String createdBy,
    required String createdByRole,

    /// 📍 LOCATION
    required String address,
    String? note,

    /// 📅 SCHEDULE
    required DateTime date,
    required String time,

    /// 💰 PAYMENT
    required double totalAmount,

    /// OPTIONAL
    int? adults,
    int? children,
    String? visitType,

    /// 🔧 PROVIDER (OPTIONAL)
    String? providerId,
    String? providerName,

    /// ENQUIRY
    bool isEnquiry = false,
  }) async {

    final docRef = _db.collection("orders").doc();

    await docRef.set({

      /// 🔑 IDS
      "orderId": docRef.id,
      "userId": userId,

      /// 🔥 FIXED PROVIDER LOGIC (NO NULL EVER)
      "providerId": providerId ?? "",
      "providerName": providerName ?? "",

      /// 🔥 CREATOR INFO
      "createdBy": createdBy,
      "createdByRole": createdByRole,

      /// 🧾 SERVICE
      "serviceType": serviceType,
      "services": services,

      /// 👤 USER SNAPSHOT
      "user": {
        "name": userName,
        "phone": phone,
        "email": email ?? "",
      },

      /// 📅 SCHEDULE
      "schedule": {
        "date": Timestamp.fromDate(date),
        "time": time,
      },

      /// 📍 LOCATION
      "location": {
        "address": address.isEmpty ? "Not Provided" : address,
        "note": note ?? "",
      },

      /// 🧠 META
      "meta": {
        "adults": adults ?? 0,
        "children": children ?? 0,
        "visitType": visitType ?? "",
        "isEnquiry": isEnquiry,
      },

      /// 💳 PAYMENT
      "payment": {
        "totalAmount": totalAmount,
        "paid": isEnquiry ? false : true,
        "method": isEnquiry ? "enquiry" : "upi",
      },

      /// 📦 STATUS
      "status": isEnquiry ? "enquiry" : "pending",

      /// ⏱ TIME
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return docRef;
  }
}