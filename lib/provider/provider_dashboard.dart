import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final user = FirebaseAuth.instance.currentUser;

  /// ================= STREAMS =================

  Stream<DocumentSnapshot> providerStream() {
    return providersRef.doc(widget.providerId).snapshots();
  }

  /// 🔥 AVAILABLE JOBS (FIXED NULL ISSUE)
  Stream<QuerySnapshot> availableJobs() {
    return ordersRef
        .where('serviceType', isEqualTo: widget.serviceType)
        .where('status', isEqualTo: "pending")
        .where('providerId', isNull: true) // ✅ IMPORTANT FIX
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 🔥 MY JOBS (USE AUTH UID)
  Stream<QuerySnapshot> myJobs() {
    return ordersRef
        .where('providerUserId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ================= ACTIONS =================

  /// ✅ ACCEPT
  Future<void> acceptOrder(String id) async {
    final ref = ordersRef.doc(id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>;

        if (data['providerId'] != null) {
          throw Exception("Taken");
        }

        tx.update(ref, {
          "providerId": widget.providerId,        // old logic kept
          "providerUserId": user!.uid,            // 🔥 NEW (for rules)
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

  /// ✅ COMPLETE
  Future<void> completeOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "completed",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _msg("✅ Job Completed");
  }

  /// ❌ CANCEL
  Future<void> cancelOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "pending",
      "providerId": null,
      "providerUserId": null,
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
              body: Center(child: CircularProgressIndicator()));
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
            backgroundColor: const Color(0xFFF4F6FA),
            appBar: AppBar(
              elevation: 0,
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
                _jobList(availableJobs(), true),
                _jobList(myJobs(), false),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= JOB LIST =================

  Widget _jobList(Stream<QuerySnapshot> stream, bool isAvailable) {
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

            final userData = data['user'] ?? {};
            final payment = data['payment'] ?? {};
            final status = data['status'] ?? "pending";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.06),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    userData['name'] ?? "No Name",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  /// PHONE
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14),
                      const SizedBox(width: 6),
                      Text(userData['phone'] ?? ""),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// LOCATION
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data['location']?['address'] ?? "",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// PRICE + STATUS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${payment['totalAmount'] ?? 0}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: getColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// ACTIONS
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
            );
          },
        );
      },
    );
  }
}