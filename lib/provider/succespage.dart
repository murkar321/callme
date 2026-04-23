import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'provider_dashboard.dart';

class SuccessPage extends StatefulWidget {
  final String businessName;
  final String providerType;
  final String serviceType;

  const SuccessPage({
    super.key,
    required this.businessName,
    required this.providerType,
    required this.serviceType,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {

  String approvalStatus = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  /// 🔥 Fetch provider approval status
  Future<void> _fetchStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      final snapshot = await FirebaseFirestore.instance
          .collection("providers")
          .where("userId", isEqualTo: user!.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          approvalStatus = snapshot.docs.first['approvalStatus'] ?? "Pending";
        });
      } else {
        setState(() => approvalStatus = "Pending");
      }
    } catch (e) {
      setState(() => approvalStatus = "Error");
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(approvalStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// ✅ Success Icon
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

              /// ✅ Title
              const Text(
                "Registration Submitted",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// ✅ Subtitle
              Text(
                "Your business has been successfully registered.\nOur team will review your profile.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 28),

              /// 🔹 Business Info Card
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
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.businessName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text("Provider Type: ${widget.providerType}"),
                    Text("Service: ${widget.serviceType.toUpperCase()}"),

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
                        approvalStatus,
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

              /// 🔥 ACTION BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {

                    /// 🔥 Optional logic (recommended)
                    if (approvalStatus != "Approved") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Your account is under review. Dashboard access will be enabled once approved.",
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessDashboardPage(
                          businessName: widget.businessName,
                          categoryRoute: widget.serviceType, providerId: '',
                        ),
                      ),
                    );
                  },
                  child: const Text("Go to Dashboard"),
                ),
              ),

              const SizedBox(height: 12),

              /// 🔹 Refresh Status
              TextButton(
                onPressed: _fetchStatus,
                child: const Text("Refresh Status"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}