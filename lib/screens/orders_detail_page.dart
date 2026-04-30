import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final schedule = data['schedule'] ?? {};
    final payment = data['payment'] ?? {};
    final location = data['location'] ?? {};
    final user = data['user'] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              data['serviceType'] ?? "",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("Services: ${(data['services'] as List?)?.join(", ")}"),

            const Divider(),

            Text("👤 ${user['name'] ?? ""}"),
            Text("📞 ${user['phone'] ?? ""}"),
            Text("📧 ${user['email'] ?? ""}"),

            const Divider(),

            Text("📍 ${location['address'] ?? ""}"),

            const Divider(),

            Text("📅 ${schedule['date'] ?? ""}"),
            Text("⏰ ${schedule['time'] ?? ""}"),

            const Divider(),

            Text("💰 ₹${payment['totalAmount'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ],
        ),
      ),
    );
  }
}