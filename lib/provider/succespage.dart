import 'package:flutter/material.dart';
import 'provider_dashboard.dart';

class SuccessPage extends StatelessWidget {
  final String businessName;
  final String providerType;
  final String serviceType; // 🔥 this is your route

  const SuccessPage({
    super.key,
    required this.businessName,
    required this.providerType,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 100,
              ),

              const SizedBox(height: 24),

              const Text(
                "Registration Successful",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "$businessName has been registered successfully.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Provider Type: $providerType"),
                      Text("Service: ${serviceType.toUpperCase()}"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// 🔥 FIXED BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessDashboardPage(
                          businessName: businessName,
                          categoryRoute: serviceType, // ✅ FIXED
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
      ),
    );
  }
}