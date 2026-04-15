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
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services),
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing),
    ServiceCategory(name: 'Hotel', icon: Icons.hotel),
    ServiceCategory(name: 'Resort', icon: Icons.holiday_village),
    ServiceCategory(name: 'Laundry', icon: Icons.local_laundry_service),
    ServiceCategory(name: 'Water', icon: Icons.water_drop),
    ServiceCategory(name: 'Civil', icon: Icons.construction),
  ];

  void _showProviderTypeSelector(ServiceCategory service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Provider Type",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              _buildTypeTile(service, "Individual", Icons.person),
              _buildTypeTile(service, "Agency", Icons.groups),
              _buildTypeTile(service, "Business", Icons.business),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeTile(
    ServiceCategory service,
    String providerType,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(providerType),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProviderForm(
              type: service.name.toLowerCase(),
              providerType: providerType,
            ),
          ),
        );
      },
    );
  }

  void _handleCategoryTap(ServiceCategory service) {
    _showProviderTypeSelector(service);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Business Service'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: businessCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
    );
  }
}