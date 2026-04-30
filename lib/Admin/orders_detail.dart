import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final ref = FirebaseFirestore.instance.collection("orders");

  String search = "";
  String filter = "all";

  Color getColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "completed":
        return Colors.blue;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Orders")),

      body: Column(
        children: [

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (val) => setState(() => search = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search orders...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          /// 🎯 FILTER
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip("all"),
                _chip("pending"),
                _chip("accepted"),
                _chip("completed"),
                _chip("rejected"),
              ],
            ),
          ),

          /// 📋 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref.snapshots(), // ✅ NO orderBy (fix buffering)
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found"));
                }

                final docs = snapshot.data!.docs;

                /// ✅ SAFE SORT
                docs.sort((a, b) {
                  final aTime = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final bTime = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return bTime.compareTo(aTime);
                });

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final user = data['user'] ?? {};

                  final service = (data['serviceType'] ?? "").toLowerCase();
                  final name = (user['name'] ?? "").toLowerCase();
                  final phone = (user['phone'] ?? "").toString();

                  final matchesSearch =
                      service.contains(search) ||
                      name.contains(search) ||
                      phone.contains(search);

                  final matchesFilter =
                      filter == "all" || data['status'] == filter;

                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {

                    final data = filtered[i].data() as Map<String, dynamic>;
                    final user = data['user'] ?? {};
                    final meta = data['meta'] ?? {};
                    final status = data['status'] ?? "pending";

                    final providerName =
                        meta['providerName'] ?? "Not Assigned";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          data['serviceType'] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("👤 ${user['name'] ?? ""}"),
                            Text("📞 ${user['phone'] ?? ""}"),
                            Text("🧑‍🔧 $providerName"),
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
          ),
        ],
      ),
    );
  }

  Widget _chip(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(value.toUpperCase()),
        selected: filter == value,
        onSelected: (_) => setState(() => filter = value),
      ),
    );
  }
}