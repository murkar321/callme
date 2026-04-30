import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessDashboardPage extends StatefulWidget {
  final String providerId;
  final String businessName;
  final String serviceType;

  const BusinessDashboardPage({
    super.key,
    required this.providerId,
    required this.businessName,
    required this.serviceType,
  });

  @override
  State<BusinessDashboardPage> createState() =>
      _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  final ordersRef = FirebaseFirestore.instance.collection('orders');
  final providersRef = FirebaseFirestore.instance.collection('providers');

  /// ================= PROVIDER STREAM =================
  Stream<DocumentSnapshot> providerStream() {
    return providersRef.doc(widget.providerId).snapshots();
  }

  /// ================= AVAILABLE JOBS =================
  Stream<QuerySnapshot> availableJobs() {
    return ordersRef
        .where('serviceType', isEqualTo: widget.serviceType)
        .where('status', isEqualTo: "pending")
        .where('providerId', isNull: true) // only unassigned jobs
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ================= MY JOBS =================
  Stream<QuerySnapshot> myJobs() {
    return ordersRef
        .where('providerId', isEqualTo: widget.providerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ================= ACCEPT ORDER =================
  Future<void> acceptOrder(String id) async {
    final ref = ordersRef.doc(id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>;

        final existingProvider = data['providerId'];

        if (existingProvider != null && existingProvider != "") {
          throw Exception("Already taken");
        }

        tx.update(ref, {
          "providerId": widget.providerId,
          "providerName": widget.businessName,
          "status": "accepted",
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      _msg("✅ Order Accepted");
    } catch (e) {
      _msg("❌ Already taken");
    }
  }

  /// ================= COMPLETE =================
  Future<void> completeOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "completed",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _msg("✅ Job Completed");
  }

  /// ================= CANCEL =================
  Future<void> cancelOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "cancelled",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _msg("❌ Job Cancelled");
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  Color getColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: providerStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final provider =
            snap.data!.data() as Map<String, dynamic>?;

        if (provider?['status'] != "approved") {
          return Scaffold(
            appBar: AppBar(title: const Text("Dashboard")),
            body: const Center(
              child: Text("⏳ Waiting for Admin Approval"),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              title: Text(widget.businessName),
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Available Jobs"),
                  Tab(text: "My Jobs"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _jobsList(availableJobs(), true),
                _jobsList(myJobs(), false),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= JOB LIST =================
  Widget _jobsList(Stream<QuerySnapshot> stream, bool isAvailable) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text("Error: ${snap.error}"));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("No jobs found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final user = data['user'] ?? {};
            final payment = data['payment'] ?? {};
            final status = data['status'] ?? "pending";

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? "No Name",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("📞 ${user['phone'] ?? ""}"),
                    Text("📍 ${data['location']?['address'] ?? ""}"),
                    Text("💰 ₹${payment['totalAmount'] ?? 0}"),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: getColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isAvailable)
                          ElevatedButton(
                            onPressed: () => acceptOrder(doc.id),
                            child: const Text("Accept"),
                          ),
                        if (!isAvailable && status == "accepted")
                          ElevatedButton(
                            onPressed: () => completeOrder(doc.id),
                            child: const Text("Complete"),
                          ),
                        const SizedBox(width: 8),
                        if (!isAvailable && status == "accepted")
                          OutlinedButton(
                            onPressed: () => cancelOrder(doc.id),
                            child: const Text("Cancel"),
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
    );
  }
}