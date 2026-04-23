import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyOrdersPage extends StatelessWidget {
  final String phone;

  const MyOrdersPage({
    super.key,
    required this.phone,
  });

  /// 🔥 FIXED QUERY (USES FLAT FIELD)
  Stream<QuerySnapshot> getMyOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userPhone', isEqualTo: phone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color getStatusColor(String status) {
    switch (status) {
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
      appBar: AppBar(
        title: const Text("My Orders"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getMyOrders(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(
              child: Text("Query Error - check Firestore index"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              final user = data['user'] ?? {};
              final schedule = data['schedule'] ?? {};
              final payment = data['payment'] ?? {};
              final location = data['location'] ?? {};

              final status = data['status'] ?? "pending";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        data['serviceType'] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        (data['services'] as List?)?.join(", ") ?? "",
                      ),

                      const SizedBox(height: 6),

                      Text("👤 ${user['name'] ?? ''}"),
                      Text("📞 ${user['phone'] ?? ''}"),

                      const SizedBox(height: 6),

                      Text("📍 ${location['address'] ?? ''}"),

                      const SizedBox(height: 6),

                      Text(
                        "Date: ${schedule['date'] != null
                            ? (schedule['date'] as Timestamp)
                                .toDate()
                                .toString()
                                .split(" ")[0]
                            : ''}",
                      ),

                      Text("Time: ${schedule['time'] ?? ''}"),

                      const SizedBox(height: 6),

                      Text(
                        "₹${payment['totalAmount'] ?? 0}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
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