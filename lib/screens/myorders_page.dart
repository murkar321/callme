import 'package:callme/screens/orders_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key, required String phone});

  /// 🔥 GET USER ORDERS
  Stream<QuerySnapshot> getMyOrders() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  /// 🎨 STATUS COLOR
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

  /// 📅 FORMAT DATE
  String formatDate(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        return "${d.day}/${d.month}/${d.year}";
      }
    } catch (_) {}
    return "-";
  }

  /// ❌ CANCEL ORDER
  Future<void> cancelOrder(BuildContext context, String orderId) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({
      "status": "cancelled",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order cancelled")),
    );
  }

  /// 🧠 STATUS MESSAGE (NEW 🔥)
  String getStatusMessage(String status) {
    switch (status) {
      case "accepted":
        return "Provider assigned & will contact you";
      case "completed":
        return "Service completed successfully";
      case "cancelled":
        return "Order cancelled";
      case "rejected":
        return "Request rejected by provider";
      default:
        return "Waiting for provider to accept";
    }
  }

  /// 🧱 ORDER CARD
  Widget _orderCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final schedule = (data['schedule'] ?? {}) as Map<String, dynamic>;
    final payment = (data['payment'] ?? {}) as Map<String, dynamic>;
    final location = (data['location'] ?? {}) as Map<String, dynamic>;

    final status = (data['status'] ?? "pending").toString();

    final services = (data['services'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    /// 🔥 PROVIDER INFO (NEW)
    final providerName = data['providerName'] ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['serviceType'] ?? "Service",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// 🔹 SERVICES
            Text(services.join(", ")),

            const SizedBox(height: 10),

            /// 📅 DATE
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 6),
                Text(formatDate(schedule['date'])),
              ],
            ),

            const SizedBox(height: 4),

            /// ⏰ TIME
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 6),
                Text(schedule['time'] ?? "-"),
              ],
            ),

            const SizedBox(height: 4),

            /// 📍 LOCATION
            Row(
              children: [
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location['address'] ?? "",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// 🔥 PROVIDER INFO (NEW COMMUNICATION)
            if (providerName.toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.business, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Provider: $providerName",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),

            const SizedBox(height: 6),

            /// 🧠 STATUS MESSAGE (NEW UX)
            Text(
              getStatusMessage(status),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            /// 💰 PRICE + ACTION
            Row(
              children: [
                Text(
                  "₹${payment['totalAmount'] ?? 0}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const Spacer(),

                if (status == "pending")
                  TextButton(
                    onPressed: () => cancelOrder(context, doc.id),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getMyOrders(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No orders yet"),
            );
          }

          /// 🔽 SORT LOCALLY
          orders.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _orderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }
}