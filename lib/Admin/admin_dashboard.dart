import 'package:callme/Admin/orders_detail.dart';
import 'package:callme/Admin/providers_details.dart';
import 'package:callme/Admin/users_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'approve_providers_page.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});

  final usersRef = FirebaseFirestore.instance.collection("users");
  final providersRef = FirebaseFirestore.instance.collection("providers");
  final ordersRef = FirebaseFirestore.instance.collection("orders");

  /// ================= MASTER STREAM (NO BUFFERING) =================
  Stream<Map<String, dynamic>> dashboardStream() {
    return FirebaseFirestore.instance.collection("orders").snapshots().map((orderSnap) {

      int totalOrders = orderSnap.docs.length;
      int pending = 0, accepted = 0, completed = 0, rejected = 0;

      for (var doc in orderSnap.docs) {
        final s = doc['status'] ?? "pending";

        if (s == "pending") pending++;
        if (s == "accepted") accepted++;
        if (s == "completed") completed++;
        if (s == "rejected") rejected++;
      }

      return {
        "orders": totalOrders,
        "pending": pending,
        "accepted": accepted,
        "completed": completed,
        "rejected": rejected,
      };
    });
  }

  /// ================= COUNTS =================
  Stream<int> usersCount() =>
      usersRef.snapshots().map((s) => s.docs.length);

  Stream<int> providersCount() =>
      providersRef.snapshots().map((s) => s.docs.length);

  Stream<int> pendingProvidersCount() =>
      providersRef.where("status", isEqualTo: "pending")
          .snapshots()
          .map((s) => s.docs.length);

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔍 SEARCH BAR
            TextField(
              decoration: InputDecoration(
                hintText: "Search users, providers, orders...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 COUNTERS GRID
            Row(
              children: [
                Expanded(child: _navCard(context, "Users", Icons.people, Colors.blue, UsersPage(), usersCount())),
                const SizedBox(width: 10),
                Expanded(child: _navCard(context, "Providers", Icons.business, Colors.green, ProvidersPage(), providersCount())),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _navCard(context, "Orders", Icons.shopping_bag, Colors.orange, AdminOrdersPage(), null)),
                const SizedBox(width: 10),
                Expanded(child: _navCard(context, "Approvals", Icons.pending, Colors.red, ApproveProvidersPage(), pendingProvidersCount())),
              ],
            ),

            const SizedBox(height: 25),

            /// 📊 ORDER STATS + CHART
            StreamBuilder<Map<String, dynamic>>(
              stream: dashboardStream(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;

                return Column(
                  children: [

                    /// 🔢 STATS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat("Pending", data['pending'], Colors.orange),
                        _miniStat("Accepted", data['accepted'], Colors.green),
                        _miniStat("Done", data['completed'], Colors.blue),
                        _miniStat("Rejected", data['rejected'], Colors.red),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 📊 BAR CHART
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(show: false),
                          barGroups: [
                            _bar(0, data['pending']),
                            _bar(1, data['accepted']),
                            _bar(2, data['completed']),
                            _bar(3, data['rejected']),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            /// 🔔 NEW ORDER ALERT
            StreamBuilder<Map<String, dynamic>>(
              stream: dashboardStream(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) return const SizedBox();

                final pending = snapshot.data!['pending'];

                if (pending == 0) return const SizedBox();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text("$pending new pending orders"),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ================= NAV CARD =================
  Widget _navCard(BuildContext context, String title, IconData icon,
      Color color, Widget page, Stream<int>? countStream) {

    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, color: color),

            const SizedBox(height: 6),

            if (countStream != null)
              StreamBuilder<int>(
                stream: countStream,
                builder: (_, snap) {
                  return Text(
                    "${snap.data ?? 0}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color),
                  );
                },
              ),

            Text(title),
          ],
        ),
      ),
    );
  }

  /// ================= MINI STATS =================
  Widget _miniStat(String title, int value, Color color) {
    return Column(
      children: [
        Text("$value",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
        Text(title),
      ],
    );
  }

  /// ================= BAR =================
  BarChartGroupData _bar(int x, int value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: value.toDouble()),
      ],
    );
  }
}