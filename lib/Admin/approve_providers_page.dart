import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveProvidersPage extends StatelessWidget {
  ApproveProvidersPage({super.key});

  final providersRef =
      FirebaseFirestore.instance.collection("providers");

  /// 🔥 SAFE QUERY (avoid index error)
  Stream<QuerySnapshot> getPendingProviders() {
    return providersRef
        .where("status", isEqualTo: "pending")
        .snapshots(); // ❗ removed orderBy (can break if index missing)
  }

  /// ✅ APPROVE PROVIDER
  Future<void> approve(String id, BuildContext context) async {
    try {
      await providersRef.doc(id).update({
        "status": "approved",
        "isActive": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Provider Approved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ❌ REJECT PROVIDER
  Future<void> reject(String id, BuildContext context) async {
    String reason = "";

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Provider"),
        content: TextField(
          decoration: const InputDecoration(
            hintText: "Enter reason (optional)",
          ),
          onChanged: (val) => reason = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await providersRef.doc(id).update({
                "status": "rejected",
                "isActive": false,
                "rejectReason": reason,
                "updatedAt": FieldValue.serverTimestamp(),
              });

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("❌ Provider Rejected")),
              );
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Approve Providers"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingProviders(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("No pending providers"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {

              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final business =
                  (data['business'] ?? {}) as Map<String, dynamic>;

              final serviceType = data['serviceType'] ?? "";
              final providerType = data['providerType'] ?? "";
              final createdAt = data['createdAt'];

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

                    /// 🏢 BUSINESS NAME + DATE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.business, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  business['businessName'] ?? "No Name",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (createdAt != null)
                          Text(
                            (createdAt as Timestamp)
                                .toDate()
                                .toString()
                                .split(" ")[0],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// 👤 OWNER
                    Text("👤 Owner: ${business['ownerName'] ?? ""}"),

                    /// 📞 PHONE
                    Text("📞 ${business['phone'] ?? ""}"),

                    /// 📧 EMAIL
                    if (business['email'] != null)
                      Text("📧 ${business['email']}"),

                    /// 📍 ADDRESS
                    if (business['address'] != null)
                      Text("📍 ${business['address']}"),

                    const SizedBox(height: 6),

                    /// 🛠 SERVICE
                    Text("🛠 Service: $serviceType"),

                    /// 🏷 TYPE
                    Text("🏷 Type: $providerType"),

                    const SizedBox(height: 10),

                    /// 🔥 ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        /// ❌ REJECT
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => reject(doc.id, context),
                        ),

                        /// ✅ APPROVE
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => approve(doc.id, context),
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
    );
  }
}