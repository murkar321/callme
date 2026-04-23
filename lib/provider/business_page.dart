import 'package:flutter/material.dart';
import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/provider/service_provider_form.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {

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

  /// ✅ FIX: Proper type mapping
  String _getServiceType(String name) {
    switch (name) {
      case "Educational Services":
        return "education"; // 🔥 FIXED
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

  /// 🔹 Show Provider Type Selector
  void _showProviderTypeSelector(ServiceCategory service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                "Register as ${service.name} Provider",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Choose how you want to provide services",
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 20),

              _buildTypeTile(service, "Individual", Icons.person),
              _buildTypeTile(service, "Agency", Icons.groups),
              _buildTypeTile(service, "Business", Icons.business),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Provider Type Tile
  Widget _buildTypeTile(
    ServiceCategory service,
    String providerType,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(providerType),
        subtitle: Text(
          providerType == "Individual"
              ? "Single person providing service"
              : providerType == "Agency"
                  ? "Multiple workers under you"
                  : "Registered company/business",
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceProviderForm(
                type: _getServiceType(service.name), // ✅ FIX USED HERE
                providerType: providerType,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔹 Handle Category Tap
  void _handleCategoryTap(ServiceCategory service) {
    _showProviderTypeSelector(service);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Become a Service Provider',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
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
                  "Join our platform, get customers, and grow your income.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Select Service Category",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: businessCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final category = businessCategories[index];

                return GestureDetector(
                  onTap: () => _handleCategoryTap(category),
                  child: CategoryCard(
                    name: category.name,
                    icon: category.icon,
                    showName: true,
                    imagePath: '',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}