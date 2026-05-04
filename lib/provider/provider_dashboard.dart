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

class _BusinessDashboardPageState
    extends State<BusinessDashboardPage> {
  final ordersRef = FirebaseFirestore.instance.collection('orders');
  final providersRef =
      FirebaseFirestore.instance.collection('providers');

  final user = FirebaseAuth.instance.currentUser;

  /// 🔥 NORMALIZER (VERY IMPORTANT)
  String normalize(String s) => s.trim().toLowerCase();

  /// ================= PROVIDER =================
  Stream<DocumentSnapshot> providerStream() {
    return providersRef.doc(widget.providerId).snapshots();
  }

  /// ================= AVAILABLE JOBS =================
  Stream<QuerySnapshot> availableJobs() {
    return ordersRef
        .where('serviceType',
            isEqualTo: normalize(widget.serviceType))

        /// ONLY UNASSIGNED
        .where('providerUserId', isEqualTo: "")

        /// OPEN JOBS
        .where('status', whereIn: ["pending", "enquiry"])

        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ================= MY JOBS (🔥 FIXED) =================
  Stream<QuerySnapshot> myJobs() {
    return ordersRef
        /// ONLY MY JOBS
        .where('providerUserId', isEqualTo: user!.uid)

        /// 🔥 CRITICAL FIX (NO MIXING)
        .where('serviceType',
            isEqualTo: normalize(widget.serviceType))

        /// ONLY ACTIVE/COMPLETED
        .where('status',
            whereIn: ["accepted", "completed"])

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

        /// 🔥 PREVENT DOUBLE ACCEPT
        if ((data['providerUserId'] ?? "") != "") {
          throw Exception("Already taken");
        }

        tx.update(ref, {
          "providerId": widget.providerId,
          "providerUserId": user!.uid,
          "providerName": widget.businessName,
          "status": "accepted",
          "isAssigned": true,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      _msg("✅ Order accepted");
    } catch (e) {
      _msg("❌ Already taken");
    }
  }

  /// ✅ COMPLETE
  Future<void> completeOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "completed",
      "isCompleted": true,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _msg("✅ Job completed");
  }

  /// ❌ CANCEL
  Future<void> cancelOrder(String id) async {
    await ordersRef.doc(id).update({
      "status": "pending",

      /// 🔥 RESET FULLY
      "providerId": "",
      "providerUserId": "",
      "providerName": "",

      "isAssigned": false,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _msg("❌ Job cancelled & reopened");
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  /// ================= UI HELPERS =================

  Color getColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "completed":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String getStatusMessage(String status) {
    switch (status) {
      case "accepted":
        return "Contact customer & start work";
      case "completed":
        return "Work completed successfully";
      case "enquiry":
        return "Customer requested callback";
      default:
        return "New job available";
    }
  }

  /// ================= MAIN UI =================
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

        /// 🔒 APPROVAL CHECK
        if (provider?['status'] != "approved") {
          return Scaffold(
            appBar: AppBar(title: const Text("Dashboard")),
            body: const Center(
              child: Text("⏳ Waiting for admin approval"),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6FA),

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
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No jobs found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data =
                doc.data() as Map<String, dynamic>;

            final userData = data['user'] ?? {};
            final payment = data['payment'] ?? {};
            final schedule = data['schedule'] ?? {};
            final services = (data['services'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    userData['name'] ?? "No Name",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14),
                      const SizedBox(width: 6),
                      Text(userData['phone'] ?? ""),
                    ],
                  ),

                  const SizedBox(height: 4),

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

                  const SizedBox(height: 6),

                  Text(services.join(", ")),

                  const SizedBox(height: 4),

                  Text("📅 ${schedule['time'] ?? ""}"),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹${payment['totalAmount'] ?? 0}"),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: getColor(status),
                          borderRadius:
                              BorderRadius.circular(20),
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

                  const SizedBox(height: 6),

                  Text(
                    getStatusMessage(status),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [

                      if (isAvailable)
                        ElevatedButton(
                          onPressed: () =>
                              acceptOrder(doc.id),
                          child: const Text("Accept"),
                        ),

                      if (!isAvailable &&
                          status == "accepted")
                        ElevatedButton(
                          onPressed: () =>
                              completeOrder(doc.id),
                          child: const Text("Complete"),
                        ),

                      const SizedBox(width: 8),

                      if (!isAvailable &&
                          status == "accepted")
                        OutlinedButton(
                          onPressed: () =>
                              cancelOrder(doc.id),
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