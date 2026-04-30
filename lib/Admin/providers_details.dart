import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProvidersPage extends StatelessWidget {
  final ref = FirebaseFirestore.instance.collection("providers");

  ProvidersPage({super.key});

  Color getColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Providers")),

      body: StreamBuilder<QuerySnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No providers found"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {

              final data = docs[i].data() as Map<String, dynamic>;
              final business = data['business'] ?? {};
              final status = data['status'] ?? "pending";

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(business['businessName'] ?? "No Name"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Owner: ${business['ownerName'] ?? ""}"),
                      Text("Phone: ${business['phone'] ?? ""}"),
                      Text("Service: ${data['serviceType'] ?? ""}"),
                    ],
                  ),
                  trailing: Container(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}