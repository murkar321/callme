import 'package:callme/screens/orders_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key, required String phone});

  /// 🔥 GET USER ORDERS (SAFE VERSION)
  Stream<QuerySnapshot> getMyOrders() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("❌ USER NOT LOGGED IN");
      return const Stream.empty();
    }

    debugPrint("🔥 CURRENT UID: ${user.uid}");

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        // ❗ TEMP REMOVE orderBy (until index ready)
        //.orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  /// 📅 FORMAT DATE (SAFE)
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
  Future<void> cancelOrder(String orderId) async {
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({
      "status": "cancelled",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),

      body: StreamBuilder<QuerySnapshot>(
        stream: getMyOrders(),
        builder: (context, snapshot) {

          /// ❌ ERROR
          if (snapshot.hasError) {
            debugPrint("🔥 ERROR: ${snapshot.error}");
            return const Center(child: Text("Error loading orders"));
          }

          /// ⏳ LOADING
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          /// 📭 EMPTY
          if (orders.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          /// 📋 LIST
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {

              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              /// ✅ SAFE MAP ACCESS
              final schedule = (data['schedule'] ?? {}) as Map<String, dynamic>;
              final payment = (data['payment'] ?? {}) as Map<String, dynamic>;

              final status = (data['status'] ?? "pending").toString();

              final services = (data['services'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                      )
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// SERVICE TYPE
                      Text(
                        data['serviceType'] ?? "Service",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// SERVICES
                      Text(services.join(", ")),

                      const SizedBox(height: 6),

                      /// DATE + TIME
                      Text("📅 ${formatDate(schedule['date'])}"),
                      Text("⏰ ${schedule['time'] ?? "-"}"),

                      const SizedBox(height: 6),

                      /// PRICE
                      Text(
                        "₹${payment['totalAmount'] ?? 0}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [

                          /// STATUS
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

                          const Spacer(),

                          /// CANCEL
                          if (status == "pending")
                            TextButton(
                              onPressed: () => cancelOrder(doc.id),
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
            },
          );
        },
      ),
    );
  }
}