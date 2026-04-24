import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  /// 🔥 FIRESTORE
  final usersRef = FirebaseFirestore.instance.collection("users");
  final providersRef = FirebaseFirestore.instance.collection("providers");
  final ordersRef = FirebaseFirestore.instance.collection("orders");

  /// ================= COUNTS =================

  Stream<int> usersCount() =>
      usersRef.snapshots().map((s) => s.docs.length);

  Stream<int> providersCount() =>
      providersRef.snapshots().map((s) => s.docs.length);

  Stream<int> pendingProvidersCount() => providersRef
      .where("status", isEqualTo: "pending")
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> ordersCount() =>
      ordersRef.snapshots().map((s) => s.docs.length);

  Stream<int> pendingOrdersCount() => ordersRef
      .where("status", isEqualTo: "pending")
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> acceptedOrdersCount() => ordersRef
      .where("status", isEqualTo: "accepted")
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> completedOrdersCount() => ordersRef
      .where("status", isEqualTo: "completed")
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> rejectedOrdersCount() => ordersRef
      .where("status", isEqualTo: "rejected")
      .snapshots()
      .map((s) => s.docs.length);

  /// ================= PROVIDERS =================

  Stream<QuerySnapshot> pendingProviders() {
    return providersRef
        .where("status", isEqualTo: "pending")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// ✅ APPROVE (FIXED)
  Future<void> approveProvider(String id) async {
    await providersRef.doc(id).update({
      "status": "approved",
      "isActive": true,
      "providerId": id, // 🔥 IMPORTANT FIX
    });
  }

  /// ❌ REJECT
  Future<void> rejectProvider(String id) async {
    await providersRef.doc(id).update({
      "status": "rejected",
      "isActive": false,
    });
  }

  /// ================= ORDERS =================

  Stream<QuerySnapshot> allOrders() {
    return ordersRef
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// ================= COLOR =================

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

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 STATS
            StreamBuilder(
              stream: StreamZip([
                usersCount(),
                providersCount(),
                ordersCount(),
                pendingProvidersCount(),
                pendingOrdersCount(),
                acceptedOrdersCount(),
                completedOrdersCount(),
                rejectedOrdersCount(),
              ]),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final data = snapshot.data as List;

                return Column(
                  children: [

                    Row(
                      children: [
                        _statCard("Users", "${data[0]}", Icons.people, Colors.blue),
                        const SizedBox(width: 10),
                        _statCard("Providers", "${data[1]}", Icons.business, Colors.green),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _statCard("Orders", "${data[2]}", Icons.shopping_bag, Colors.orange),
                        const SizedBox(width: 10),
                        _statCard("Revenue", "N/A", Icons.currency_rupee, Colors.grey),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _statCard("Pending", "${data[4]}", Icons.hourglass_empty, Colors.orange),
                        const SizedBox(width: 10),
                        _statCard("Accepted", "${data[5]}", Icons.check_circle, Colors.green),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _statCard("Completed", "${data[6]}", Icons.task_alt, Colors.blue),
                        const SizedBox(width: 10),
                        _statCard("Rejected", "${data[7]}", Icons.cancel, Colors.red),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _statCard("Pending Providers", "${data[3]}", Icons.pending_actions, Colors.deepOrange),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            /// 🔥 APPROVE PROVIDERS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Approve Providers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: pendingProviders(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No pending providers");
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {

                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final business = (data['business'] ?? {}) as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.store),
                        ),

                        title: Text(
                          business['businessName'] ?? "No Name",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👤 ${business['ownerName'] ?? ''}"),
                            Text("📞 ${business['phone'] ?? ''}"),
                            Text("📍 ${business['address'] ?? ''}"),
                            Text("🛠 ${data['serviceType']} (${data['providerType']})"),
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveProvider(doc.id),
                            ),

                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectProvider(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            /// 🔥 ALL ORDERS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "All Orders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: allOrders(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {

                    final data = docs[i].data() as Map<String, dynamic>;
                    final user = (data['user'] ?? {}) as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.assignment),
                        title: Text(data['serviceType'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👤 ${user['name'] ?? ''}"),
                            Text("📞 ${user['phone'] ?? ''}"),
                            Text("🧑‍🔧 ${data['providerName'] ?? 'Not Assigned'}"),
                          ],
                        ),
                        trailing: Text(
                          (data['status'] ?? "pending").toUpperCase(),
                          style: TextStyle(
                            color: getStatusColor(data['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ================= CARD =================

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 6)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}