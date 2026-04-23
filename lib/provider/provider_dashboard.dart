import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessDashboardPage extends StatelessWidget {
  final String businessName;
  final String categoryRoute;
  final String providerId; // 🔥 NEW

  const BusinessDashboardPage({
    super.key,
    required this.businessName,
    required this.categoryRoute,
    required this.providerId,
  });

  /// 🔥 COLLECTION
  CollectionReference get ordersRef =>
      FirebaseFirestore.instance.collection('orders');

  /// ✅ ONLY PROVIDER ORDERS
  Stream<QuerySnapshot> getOrders() {
    return ordersRef
        .where('serviceType', isEqualTo: categoryRoute)
        .where('providerId', isEqualTo: providerId) // 🔥 FIX
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ UPDATE STATUS
  Future<void> updateStatus(String id, String status) async {
    await ordersRef.doc(id).update({
      "status": status,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🎨 STATUS COLOR
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
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: Text("$categoryRoute Dashboard"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade300],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Welcome, $businessName 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 ORDERS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getOrders(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No assigned orders yet"),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;

                      final status = data['status'] ?? "pending";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// 👤 USER
                            Text(
                              data['userName'] ?? "User",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text("📞 ${data['phone'] ?? ""}"),
                            Text("📍 ${data['address'] ?? ""}"),

                            const SizedBox(height: 8),

                            /// 🛠 SERVICES
                            Text(
                              "Services: ${(data['services'] as List?)?.join(", ") ?? ""}",
                            ),

                            const SizedBox(height: 6),

                            /// 📅 DATE
                            Text(
                              "Date: ${data['date'] != null ? (data['date'] as Timestamp).toDate().toString().split(" ")[0] : ""}",
                            ),

                            Text("Time: ${data['time'] ?? ""}"),

                            const SizedBox(height: 6),

                            /// 💰
                            Text(
                              "₹${data['totalAmount'] ?? 0}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// 🔥 STATUS + ACTIONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                /// STATUS BADGE
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                /// ACTIONS
                                if (status == "pending")
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green),
                                        onPressed: () =>
                                            updateStatus(doc.id, "accepted"),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () =>
                                            updateStatus(doc.id, "rejected"),
                                      ),
                                    ],
                                  ),

                                if (status == "accepted")
                                  TextButton(
                                    onPressed: () =>
                                        updateStatus(doc.id, "completed"),
                                    child: const Text("Mark Completed"),
                                  ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}