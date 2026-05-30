import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  /// =========================================================
  /// GENERATE ORDER ID
  /// =========================================================

  static String generateOrderId(
    String userName,
  ) {
    final cleanName = userName
        .trim()
        .toLowerCase()
        .replaceAll(" ", "");

    final timestamp =
        DateTime.now()
            .millisecondsSinceEpoch;

    return "${cleanName}_$timestamp";
  }

  /// =========================================================
  /// PLACE ORDER
  /// =========================================================

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
    /// ORDER ID
    final orderId =
        generateOrderId(userName);

    final docRef = _db
        .collection("orders")
        .doc(orderId);

    /// NORMALIZE SERVICE TYPE
    final normalizedServiceType =
        serviceType
            .trim()
            .toLowerCase();

    final now =
        FieldValue.serverTimestamp();

    /// =====================================================
    /// SAVE ORDER
    /// =====================================================

    await docRef.set({
      /// =================================================
      /// IDS
      /// =================================================

      "orderId": orderId,
      "userId": userId,

      /// =================================================
      /// USER DATA
      /// =================================================

      "userName": userName,
      "phone": phone,
      "email": email ?? "",

      /// COMPLETE USER OBJECT
      "user": {
        "id": userId,
        "name": userName,
        "phone": phone,
        "email": email ?? "",
      },

      /// =================================================
      /// PROVIDER
      /// =================================================

      "providerId":
          providerId ?? "",

      "providerUserId":
          providerUserId ?? "",

      "providerName":
          providerName ?? "",

      "provider": {
        "providerId":
            providerId ?? "",

        "providerUserId":
            providerUserId ?? "",

        "providerName":
            providerName ?? "",
      },

      /// =================================================
      /// SERVICE
      /// =================================================

      "serviceType":
          normalizedServiceType,

      "serviceName":
          normalizedServiceType,

      "services": services,

      /// =================================================
      /// SCHEDULE
      /// =================================================

      "date":
          Timestamp.fromDate(date),

      "time": time,

      "schedule": {
        "date":
            Timestamp.fromDate(date),

        "time": time,
      },

      /// =================================================
      /// LOCATION
      /// =================================================

      "address":
          address.isEmpty
              ? "Not Provided"
              : address,

      "note": note ?? "",

      "location": {
        "address":
            address.isEmpty
                ? "Not Provided"
                : address,

        "note": note ?? "",
      },

      /// =================================================
      /// PAYMENT
      /// =================================================

      "totalAmount": totalAmount,

      "payment": {
        "totalAmount":
            totalAmount,

        "paid":
            !isEnquiry,

        "method":
            isEnquiry
                ? "enquiry"
                : "upi",
      },

      /// =================================================
      /// META
      /// =================================================

      "adults":
          adults ?? 0,

      "children":
          children ?? 0,

      "visitType":
          visitType ?? "",

      "isEnquiry":
          isEnquiry,

      "meta": {
        "adults":
            adults ?? 0,

        "children":
            children ?? 0,

        "visitType":
            visitType ?? "",

        "isEnquiry":
            isEnquiry,
      },

      /// =================================================
      /// STATUS
      /// =================================================

      "status":
          isEnquiry
              ? "enquiry"
              : "pending",

      "isAssigned": false,
      "isCompleted": false,

      /// =================================================
      /// TRACKING
      /// =================================================

      "createdBy":
          createdBy,

      "createdByRole":
          createdByRole,

      "lastActionBy":
          "user",

      "lastActionAt": now,
      "createdAt": now,
      "updatedAt": now,
    });

    return docRef;
  }
}