import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({
    super.key,
    required String phone,
  });

  /// =========================================================
  /// GET USER ORDERS
  /// =========================================================

  Stream<QuerySnapshot> getMyOrders() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  /// =========================================================
  /// STATUS COLOR
  /// =========================================================

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;

      case "completed":
        return Colors.blue;

      case "cancelled":
        return Colors.grey;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  /// =========================================================
  /// FORMAT DATE
  /// =========================================================

  String formatDate(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();

        return "${d.day}/${d.month}/${d.year}";
      }
    } catch (_) {}

    return "-";
  }

  /// =========================================================
  /// CANCEL ORDER
  /// =========================================================

  Future<void> cancelOrder(
    BuildContext context,
    String orderId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("orders")
          .doc(orderId)
          .update({
        "status": "cancelled",
        "updatedAt": FieldValue.serverTimestamp(),
        "cancelledBy": "user",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order cancelled successfully"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel order : $e"),
        ),
      );
    }
  }

  /// =========================================================
  /// STATUS MESSAGE
  /// =========================================================

  String getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return "Provider assigned and will contact you soon";

      case "completed":
        return "Service completed successfully";

      case "cancelled":
        return "This order has been cancelled";

      case "rejected":
        return "Request rejected by provider";

      default:
        return "Waiting for provider response";
    }
  }

  /// =========================================================
  /// ORDER CARD
  /// =========================================================

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final schedule =
        (data['schedule'] ?? {}) as Map<String, dynamic>;

    final payment =
        (data['payment'] ?? {}) as Map<String, dynamic>;

    final location =
        (data['location'] ?? {}) as Map<String, dynamic>;

    final status =
        (data['status'] ?? "pending").toString();

    final services =
        (data['services'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    final providerName =
        data['providerName'] ?? "";

    final providerCancelNote =
        (data['providerCancelNote'] ?? "")
            .toString()
            .trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// =================================================
          /// HEADER
          /// =================================================

          Row(
            children: [

              /// SERVICE ICON
              Container(
                height: 52,
                width: 52,

                decoration: BoxDecoration(
                  color: const Color(0xff4A6CF7)
                      .withOpacity(0.1),

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.home_repair_service,
                  color: Color(0xff4A6CF7),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              /// SERVICE NAME
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['serviceType'] ?? "Service",

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      getStatusMessage(status),

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              /// STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: getStatusColor(status),

                  borderRadius:
                      BorderRadius.circular(30),
                ),

                child: Text(
                  status.toUpperCase(),

                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// =================================================
          /// SERVICES
          /// =================================================

          if (services.isNotEmpty)
            _infoRow(
              icon: Icons.miscellaneous_services,
              text: services.join(", "),
            ),

          const SizedBox(height: 10),

          /// DATE
          _infoRow(
            icon: Icons.calendar_today,
            text: formatDate(schedule['date']),
          ),

          const SizedBox(height: 10),

          /// TIME
          _infoRow(
            icon: Icons.access_time,
            text: schedule['time'] ?? "-",
          ),

          const SizedBox(height: 10),

          /// LOCATION
          _infoRow(
            icon: Icons.location_on_outlined,
            text: location['address'] ?? "",
          ),

          const SizedBox(height: 10),

          /// PROVIDER
          if (providerName.toString().isNotEmpty)
            _infoRow(
              icon: Icons.business,
              text: "Provider : $providerName",
            ),

          /// =================================================
          /// CANCEL NOTE
          /// =================================================

          if (providerCancelNote.isNotEmpty &&
              status.toLowerCase() == "cancelled") ...[

            const SizedBox(height: 18),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),

                borderRadius:
                    BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: const [

                      Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 18,
                      ),

                      SizedBox(width: 8),

                      Text(
                        "Cancellation Reason",

                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    providerCancelNote,

                    style: const TextStyle(
                      color: Colors.red,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          /// =================================================
          /// PRICE + BUTTON
          /// =================================================

          Row(
            children: [

              /// PRICE
              Text(
                "₹${payment['totalAmount'] ?? 0}",

                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              const Spacer(),

              /// CANCEL BUTTON
              if (status.toLowerCase() == "pending")
                ElevatedButton(
                  onPressed: () {
                    cancelOrder(
                      context,
                      doc.id,
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red.withOpacity(0.1),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    "Cancel",

                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// INFO ROW
  /// =========================================================

  Widget _infoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,

            style: TextStyle(
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// =========================================================
  /// UI
  /// =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        centerTitle: true,

        title: const Text(
          "My Orders",

          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getMyOrders(),

        builder: (context, snapshot) {

          /// ERROR
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error loading orders",
              ),
            );
          }

          /// LOADING
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          /// EMPTY
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "No Orders Yet",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Your bookings will appear here",

                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          /// SORT LATEST FIRST
          orders.sort((a, b) {

            final aTime =
                (a['createdAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;

            final bTime =
                (b['createdAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;

            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            physics:
                const BouncingScrollPhysics(),

            itemCount: orders.length,

            itemBuilder: (context, index) {

              return _orderCard(
                context,
                orders[index],
              );
            },
          );
        },
      ),
    );
  }
}