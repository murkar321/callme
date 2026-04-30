import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/provider/service_provider_form.dart';
import 'package:callme/provider/provider_dashboard.dart';

class BusinessPage extends StatelessWidget {
  BusinessPage({super.key});

  final user = FirebaseAuth.instance.currentUser;

  final List<ServiceCategory> businessCategories = [
    ServiceCategory(name: 'Salon', icon: Icons.content_cut),
    ServiceCategory(name: 'Educational Services', icon: Icons.school),
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services),
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing),
    ServiceCategory(name: 'Hotel', icon: Icons.hotel),
    ServiceCategory(name: 'Resort', icon: Icons.holiday_village),
    ServiceCategory(name: 'Laundry', icon: Icons.local_laundry_service),
    ServiceCategory(name: 'Water', icon: Icons.water_drop),
    ServiceCategory(name: 'Civil', icon: Icons.construction),
  ];

  /// ================= SERVICE TYPE MAP =================

  String _getServiceType(String name) {
    switch (name) {
      case "Educational Services":
        return "education";
      case "Salon":
        return "salon";
      case "Cleaning":
        return "cleaning";
      case "Plumbing":
        return "plumbing";
      case "Hotel":
        return "hotel";
      case "Resort":
        return "resort";
      case "Laundry":
        return "laundry";
      case "Water":
        return "water";
      case "Civil":
        return "civil";
      default:
        return name.toLowerCase();
    }
  }

  /// ================= MESSAGE =================

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// ================= MAIN TAP LOGIC =================

  void _handleTap(
    BuildContext context,
    ServiceCategory service,
    Map<String, dynamic>? provider,
  ) {
    final serviceType = _getServiceType(service.name);

    /// ❌ NOT REGISTERED
    if (provider == null) {
      _showProviderTypeSelector(context, service);
      return;
    }

    final status = provider['status'] ?? "pending";
    final rejectReason = provider['rejectReason'] ?? "No reason provided";

    /// ⏳ PENDING
    if (status == "pending") {
      _showMessage(context, "⏳ Your application is under review");
      return;
    }

    /// ❌ REJECTED
    if (status == "rejected") {
      _showRejectedDialog(context, service, rejectReason);
      return;
    }

    /// ✅ APPROVED → PROVIDER DASHBOARD
    if (status == "approved") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(
            providerId: provider['providerId'] ?? "",
            businessName:
                provider['business']?['businessName'] ?? "My Business",
            serviceType: serviceType,
          ),
        ),
      );
    }
  }

  /// ================= REJECTED DIALOG =================

  void _showRejectedDialog(
    BuildContext context,
    ServiceCategory service,
    String reason,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Application Rejected ❌"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your application was rejected."),

            const SizedBox(height: 10),

            Text(
              "Reason: $reason",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showProviderTypeSelector(context, service);
            },
            child: const Text("Reapply"),
          ),
        ],
      ),
    );
  }

  /// ================= PROVIDER TYPE SELECTOR =================

  void _showProviderTypeSelector(
    BuildContext context,
    ServiceCategory service,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),

              Text(
                "Register as ${service.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _typeTile(context, service, "Individual", Icons.person),
              _typeTile(context, service, "Agency", Icons.groups),
              _typeTile(context, service, "Business", Icons.business),
            ],
          ),
        );
      },
    );
  }

  Widget _typeTile(
    BuildContext context,
    ServiceCategory service,
    String type,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(type),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProviderForm(
              type: _getServiceType(service.name),
              providerType: type,
            ),
          ),
        );
      },
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Become a Provider",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade500, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Start Your Business 🚀",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Register your service and start earning.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Service Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: businessCategories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width < 600 ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),

              itemBuilder: (_, i) {
                final category = businessCategories[i];
                final serviceType = _getServiceType(category.name);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("providers")
                      .where("userId", isEqualTo: user!.uid)
                      .where("serviceType", isEqualTo: serviceType)
                      .limit(1)
                      .snapshots(),

                  builder: (context, snapshot) {
                    Map<String, dynamic>? provider;

                    if (snapshot.hasData &&
                        snapshot.data!.docs.isNotEmpty) {
                      provider =
                          snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                    }

                    return GestureDetector(
                      onTap: () =>
                          _handleTap(context, category, provider),

                      child: CategoryCard(
                        name: category.name,
                        icon: category.icon,
                        showName: true,
                        imagePath: '',
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
}