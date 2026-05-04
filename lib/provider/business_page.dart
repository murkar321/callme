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

  /// 📍 LOCATION
  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();

      Position pos = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      setState(() {
        city = placemarks.first.locality ?? "";
        loadingLocation = false;
      });
    } catch (e) {
      loadingLocation = false;
    }
  }

  /// 🔥 NORMALIZE SERVICE TYPE
  String normalize(String s) => s.trim().toLowerCase();

  String _getServiceType(String name) {
    if (name == "Educational Services") return "education";
    return normalize(name);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ================= TAP =================
  void _handleTap(
    ServiceCategory service,
    Map<String, dynamic>? provider,
  ) {
    final serviceType = _getServiceType(service.name);

    if (user == null) {
      _showMessage("Please login to continue");
      return;
    }

    /// 🔥 NO PROVIDER → REGISTER
    if (provider == null) {
      _showProviderTypeSelector(service);
      return;
    }

    final status = provider['status'] ?? "pending";

    if (status == "pending") {
      _showMessage("⏳ Under review");
      return;
    }

    if (status == "rejected") {
      _showRejectedDialog(
        service,
        provider['rejectReason'] ?? "No reason provided",
      );
      return;
    }

    /// ✅ APPROVED → DASHBOARD
    if (status == "approved") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(
            providerId: provider['providerId'],
            businessName:
                provider['business']?['businessName'] ?? "My Business",
            serviceType: serviceType,
          ),
        ),
      );
    }
  }

  /// ================= REJECT =================
  void _showRejectedDialog(
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
              _showProviderTypeSelector(service);
            },
            child: const Text("Reapply"),
          ),
        ],
      ),
    );
  }

  /// ================= TYPE =================
  void _showProviderTypeSelector(ServiceCategory service) {
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

              _typeTile(service, "Individual", Icons.person),
              _typeTile(service, "Agency", Icons.groups),
              _typeTile(service, "Business", Icons.business),
            ],
          ),
        );
      },
    );
  }

  Widget _typeTile(
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
              gradient: const LinearGradient(
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

          /// 🔥 SINGLE STREAM (IMPORTANT FIX)
          Expanded(
            child: user == null
                ? _buildGrid({}, size)
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("providers")
                        .where("userId", isEqualTo: user!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {

                      Map<String, Map<String, dynamic>> providerMap = {};

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final type = normalize(data['serviceType'] ?? "");
                          providerMap[type] = data;
                        }
                      }

                      return _buildGrid(providerMap, size);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 🔥 GRID BUILDER
  Widget _buildGrid(
    Map<String, Map<String, dynamic>> providerMap,
    Size size,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: businessCategories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.width < 600 ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, i) {
        final category = businessCategories[i];
        final serviceType = _getServiceType(category.name);

        final provider = providerMap[serviceType];

        return GestureDetector(
          onTap: () => _handleTap(category, provider),
          child: CategoryCard(
            name: category.name,
            icon: category.icon,
            showName: true,
            imagePath: '',
          ),
        );
      },
    );
  }
}