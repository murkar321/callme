import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'provider_dashboard.dart';

class SuccessPage extends StatelessWidget {
  final String businessName;
  final String providerType;
  final String serviceType;

  const SuccessPage({
    super.key,
    required this.businessName,
    required this.providerType,
    required this.serviceType,
  });

  /// 🔥 STREAM PROVIDER (REALTIME)
  Stream<QuerySnapshot> providerStream() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection("providers")
        .where("userId", isEqualTo: user!.uid)
        .limit(1)
        .snapshots();
  }

  Color _statusColor(String status) {
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
      backgroundColor: const Color(0xFFF4F6FA),

      body: StreamBuilder<QuerySnapshot>(
        stream: providerStream(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("Provider not found"));
          }

          final doc = snap.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          final status = data['status'] ?? "pending";
          final providerId = doc.id;

          final statusColor = _statusColor(status);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// ✅ ICON
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Registration Submitted",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Your business is under review.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 28),

                  /// 🔹 CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          data['providerName'] ?? businessName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text("Type: ${data['providerType'] ?? providerType}"),
                        Text("Service: ${data['serviceType'] ?? serviceType}"),

                        const SizedBox(height: 12),

                        /// 🔥 STATUS CHIP
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 DASHBOARD BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {

                        /// ❌ BLOCK IF NOT APPROVED
                        if (status != "approved") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Waiting for admin approval"),
                            ),
                          );
                          return;
                        }

                        /// ✅ PASS CORRECT providerId
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessDashboardPage(
                              providerId: providerId, // 🔥 FIX
                              businessName:
                                  data['providerName'] ?? businessName,
                              serviceType:
                                  data['serviceType'] ?? serviceType,
                            ),
                          ),
                        );
                      },
                      child: const Text("Go to Dashboard"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}