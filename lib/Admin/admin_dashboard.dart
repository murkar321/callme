import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// 🔥 STREAMS (REAL-TIME)
  Stream<int> usersCount() {
    return FirebaseFirestore.instance
        .collection("users")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> providersCount() {
    return FirebaseFirestore.instance
        .collection("providers")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> pendingProvidersCount() {
    return FirebaseFirestore.instance
        .collection("providers")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> ordersCount() {
    return FirebaseFirestore.instance
        .collection("orders")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> pendingOrdersCount() {
    return FirebaseFirestore.instance
        .collection("orders")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<double> revenueStream() {
    return FirebaseFirestore.instance
        .collection("orders")
        .where("status", whereIn: ["accepted", "completed"])
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc['totalAmount'] ?? 0).toDouble();
      }
      return total;
    });
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

            /// 🔥 STATS (REAL-TIME)
            StreamBuilder(
              stream: StreamZip([
                usersCount(),
                providersCount(),
                ordersCount(),
                revenueStream(),
                pendingProvidersCount(),
                pendingOrdersCount(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data as List;

                final users = data[0];
                final providers = data[1];
                final orders = data[2];
                final revenue = data[3];
                final pendingProviders = data[4];
                final pendingOrders = data[5];

                return Column(
                  children: [

                    /// ROW 1
                    Row(
                      children: [
                        _statCard("Users", "$users", Colors.blue),
                        const SizedBox(width: 10),
                        _statCard("Providers", "$providers", Colors.green),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// ROW 2
                    Row(
                      children: [
                        _statCard("Bookings", "$orders", Colors.orange),
                        const SizedBox(width: 10),
                        _statCard(
                          "Revenue",
                          "₹${revenue.toStringAsFixed(0)}",
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// 🔥 IMPORTANT ACTION CARDS
                    Row(
                      children: [
                        _statCard(
                          "Pending Providers",
                          "$pendingProviders",
                          Colors.red,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          "Pending Orders",
                          "$pendingOrders",
                          Colors.deepOrange,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            /// ================= ACTION GRID =================
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _gridItem(
                  icon: Icons.people,
                  title: "Manage Users",
                  color: Colors.blue,
                  onTap: () {
                    // TODO: navigate
                  },
                ),

                _gridItem(
                  icon: Icons.verified,
                  title: "Approve Providers",
                  color: Colors.green,
                  onTap: () {
                    // 👉 NEXT PAGE (very important)
                  },
                ),

                _gridItem(
                  icon: Icons.assignment,
                  title: "Assign Orders",
                  color: Colors.orange,
                  onTap: () {
                    // 👉 assign provider to order
                  },
                ),

                _gridItem(
                  icon: Icons.analytics,
                  title: "Reports",
                  color: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI WIDGETS =================

  Widget _statCard(String title, String value, Color color) {
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
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _gridItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 6)
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}