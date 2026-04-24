import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key, required String phone});

  /// 🔥 BEST PRACTICE QUERY (FAST + RELIABLE)
  Stream<QuerySnapshot> getMyOrders() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid) // ✅ FIXED
        .orderBy('createdAt', descending: true)
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
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getMyOrders(),
        builder: (context, snapshot) {

          /// ❌ ERROR
          if (snapshot.hasError) {
            print("🔥 Firestore Error: ${snapshot.error}");
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          /// ⏳ LOADING
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          /// 📭 EMPTY STATE
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No orders yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {

              final data =
                  orders[index].data() as Map<String, dynamic>;

              /// 🔐 SAFE MAPS
              final schedule =
                  (data['schedule'] ?? {}) as Map<String, dynamic>;
              final payment =
                  (data['payment'] ?? {}) as Map<String, dynamic>;
              final location =
                  (data['location'] ?? {}) as Map<String, dynamic>;

              final status =
                  (data['status'] ?? "pending").toString();

              /// 📅 FORMAT DATE
              String date = "";
              if (schedule['date'] is Timestamp) {
                date = (schedule['date'] as Timestamp)
                    .toDate()
                    .toString()
                    .split(" ")[0];
              }

              return Container(
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

                    /// 🛠 SERVICE TYPE
                    Text(
                      data['serviceType'] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// 📋 SERVICES
                    Text(
                      (data['services'] as List?)
                              ?.join(", ") ??
                          "",
                    ),

                    const SizedBox(height: 8),

                    /// 📍 ADDRESS
                    Text("📍 ${location['address'] ?? ""}"),

                    const SizedBox(height: 6),

                    /// 📅 DATE & TIME
                    Text("📅 $date"),
                    Text("⏰ ${schedule['time'] ?? ""}"),

                    const SizedBox(height: 6),

                    /// 💰 PRICE
                    Text(
                      "₹${payment['totalAmount'] ?? 0}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// 📌 STATUS CHIP
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}