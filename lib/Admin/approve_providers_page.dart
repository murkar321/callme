import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveProvidersPage extends StatelessWidget {
  ApproveProvidersPage({super.key});

  final CollectionReference providersRef =
      FirebaseFirestore.instance.collection("providers");

  /// ================= STREAM =================

  Stream<QuerySnapshot> pendingProvidersStream() {
    return providersRef
        .where("status", isEqualTo: "pending")
        .snapshots();
  }

  /// ================= ACTIONS =================

  Future<void> approveProvider(String id, BuildContext context) async {
    try {
      await providersRef.doc(id).update({
        "status": "approved",
        "isActive": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provider approved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> rejectProvider(String id, BuildContext context) async {
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
              try {
                await providersRef.doc(id).update({
                  "status": "rejected",
                  "isActive": false,
                  "rejectReason": reason,
                  "updatedAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Provider rejected")),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
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
        title: const Text("Provider Approvals"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: pendingProvidersStream(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("No pending providers"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,

            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final business =
                  (data['business'] as Map<String, dynamic>?) ?? {};

              final serviceType = data['serviceType'] ?? "Not specified";
              final providerType = data['providerType'] ?? "Not specified";

              final createdAt = data['createdAt'] as Timestamp?;

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
                      offset: const Offset(0, 3),
                    )
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ================= HEADER =================
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (createdAt != null)
                          Text(
                            createdAt.toDate().toString().split(" ")[0],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// ================= DETAILS =================
                    Text("👤 Owner: ${business['ownerName'] ?? ""}"),
                    Text("📞 ${business['phone'] ?? ""}"),

                    if (business['email'] != null)
                      Text("📧 ${business['email']}"),

                    if (business['address'] != null)
                      Text("📍 ${business['address']}"),

                    const SizedBox(height: 6),

                    Text("🛠 Service: $serviceType"),
                    Text("🏷 Type: $providerType"),

                    const SizedBox(height: 12),

                    /// ================= ACTIONS =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              rejectProvider(doc.id, context),
                        ),

                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () =>
                              approveProvider(doc.id, context),
                        ),
                      ],
                    ),
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