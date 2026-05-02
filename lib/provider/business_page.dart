import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/provider/service_provider_form.dart';
import 'package:callme/provider/provider_dashboard.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {

  User? get user => FirebaseAuth.instance.currentUser;

  String city = "";
  bool loadingLocation = true;

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

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  /// 📍 FAST LOCATION (NON-BLOCKING)
  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();

      Position pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5));

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
              pos.latitude, pos.longitude);

      setState(() {
        city = placemarks.first.locality ?? "";
        loadingLocation = false;
      });
    } catch (e) {
      loadingLocation = false;
    }
  }

  /// ================= SERVICE TYPE =================
  String _getServiceType(String name) {
    switch (name) {
      case "Educational Services":
        return "education";
      default:
        return name.toLowerCase();
    }
  }

  /// ================= MESSAGE =================
  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= MAIN TAP =================
  void _handleTap(
      BuildContext context,
      ServiceCategory service,
      Map<String, dynamic>? provider,
      ) {

    final serviceType = _getServiceType(service.name);

    if (user == null) {
      _showMessage(context, "Please login to continue");
      return;
    }

    if (provider == null) {
      _showProviderTypeSelector(context, service);
      return;
    }

    final status = provider['status'] ?? "pending";
    final rejectReason =
        provider['rejectReason'] ?? "No reason provided";

    if (status == "pending") {
      _showMessage(context, "⏳ Under review");
      return;
    }

    if (status == "rejected") {
      _showRejectedDialog(context, service, rejectReason);
      return;
    }

    if (status == "approved") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(
            providerId: provider['providerId'] ?? "",
            businessName:
                provider['business']?['businessName'] ??
                    "My Business",
            serviceType: serviceType,
          ),
        ),
      );
    }
  }

  /// ================= REJECTED =================
  void _showRejectedDialog(
      BuildContext context,
      ServiceCategory service,
      String reason,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rejected ❌"),
        content: Text("Reason: $reason"),
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

  /// ================= TYPE SELECTOR =================
  void _showProviderTypeSelector(
      BuildContext context,
      ServiceCategory service,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Register as ${service.name}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
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
      leading: Icon(icon),
      title: Text(type),
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
        title: const Text("Become a Provider",
            style: TextStyle(color: Colors.black)),
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
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              loadingLocation
                  ? "Detecting location..."
                  : "Available in $city",
              style: const TextStyle(color: Colors.white),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Service Category",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 10),

          /// GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: businessCategories.length,
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width < 600 ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),

              itemBuilder: (_, i) {
                final category = businessCategories[i];
                final serviceType =
                _getServiceType(category.name);

                /// ✅ GUEST → NO STREAM
                if (user == null) {
                  return GestureDetector(
                    onTap: () =>
                        _handleTap(context, category, null),
                    child: CategoryCard(
                      name: category.name,
                      icon: category.icon,
                      showName: true,
                      imagePath: '',
                    ),
                  );
                }

                /// ✅ USER → STREAM SAFE
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("providers")
                      .where("userId",
                      isEqualTo: user?.uid)
                      .where("serviceType",
                      isEqualTo: serviceType)
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
                      onTap: () => _handleTap(
                          context, category, provider),
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