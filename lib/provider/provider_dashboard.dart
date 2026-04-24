import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessDashboardPage extends StatefulWidget {
  final String businessName;
  final String categoryRoute;
  final String providerId;

  const BusinessDashboardPage({
    super.key,
    required this.businessName,
    required this.categoryRoute,
    required this.providerId,
  });

  @override
  State<BusinessDashboardPage> createState() =>
      _BusinessDashboardPageState();
}

class _BusinessDashboardPageState
    extends State<BusinessDashboardPage> {

  final CollectionReference ordersRef =
      FirebaseFirestore.instance.collection('orders');

  bool isApproved = false;
  bool loading = true;

  /// ================= CHECK APPROVAL =================
  Future<void> checkApproval() async {
    final doc = await FirebaseFirestore.instance
        .collection("providers")
        .doc(widget.providerId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        isApproved = data['isActive'] == true;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    checkApproval();
  }

  /// ================= ORDERS STREAM =================
  Stream<QuerySnapshot> getOrders() {
    return ordersRef
        .where('serviceType', isEqualTo: widget.categoryRoute)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ================= ACCEPT ORDER =================
  Future<void> acceptOrder(String id) async {
    final docSnap = await ordersRef.doc(id).get();
    final data = docSnap.data() as Map<String, dynamic>;

    if (data['providerId'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already accepted")),
      );
      return;
    }

    await ordersRef.doc(id).update({
      "providerId": widget.providerId,
      "providerName": widget.businessName,
      "status": "accepted",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ================= UPDATE STATUS =================
  Future<void> updateStatus(String id, String status) async {
    await ordersRef.doc(id).update({
      "status": status,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ================= STATUS COLOR =================
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

    /// 🔄 LOADING
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ❌ NOT APPROVED
    if (!isApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dashboard")),
        body: const Center(
          child: Text("⏳ Waiting for Admin Approval"),
        ),
      );
    }

    /// ✅ APPROVED DASHBOARD
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: Text("${widget.categoryRoute.toUpperCase()} Dashboard"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// 🔹 HEADER
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.store, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Welcome, ${widget.businessName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 ORDERS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOrders(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                /// 🔥 FILTER LOGIC (IMPORTANT)
                final allDocs = snapshot.data!.docs;

                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final providerId = data['providerId'];

                  return providerId == null ||
                      providerId == widget.providerId;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No orders available"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {

                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    final status =
                        (data['status'] ?? "pending").toString();

                    final user =
                        (data['user'] ?? {}) as Map<String, dynamic>;

                    final location =
                        (data['location'] ?? {}) as Map<String, dynamic>;

                    final schedule =
                        (data['schedule'] ?? {}) as Map<String, dynamic>;

                    final payment =
                        (data['payment'] ?? {}) as Map<String, dynamic>;

                    final isMine =
                        data['providerId'] == widget.providerId;

                    final isUnassigned =
                        data['providerId'] == null;

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

                          /// TOP
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                user['name'] ?? "User",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              _statusChip(status),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text("📞 ${user['phone'] ?? ""}"),
                          Text("📍 ${location['address'] ?? ""}"),

                          const SizedBox(height: 6),

                          Text(
                            "🛠 ${(data['services'] as List?)?.join(", ") ?? ""}",
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "📅 ${schedule['date'] is Timestamp
                                ? (schedule['date'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split(" ")[0]
                                : ""}",
                          ),

                          Text("⏰ ${schedule['time'] ?? ""}"),

                          const SizedBox(height: 6),

                          Text(
                            "₹${payment['totalAmount'] ?? 0}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// ACTIONS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [

                              if (isUnassigned) ...[
                                _actionBtn("Accept", Colors.green,
                                    () => acceptOrder(doc.id)),
                                const SizedBox(width: 8),
                                _actionBtn("Reject", Colors.red,
                                    () => updateStatus(doc.id, "rejected")),
                              ],

                              if (isMine && status == "accepted")
                                _actionBtn("Complete", Colors.blue,
                                    () => updateStatus(doc.id, "completed")),
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
    );
  }

  /// ================= STATUS CHIP =================
  Widget _statusChip(String status) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// ================= BUTTON =================
  Widget _actionBtn(
      String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(70, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(text),
    );
  }
}