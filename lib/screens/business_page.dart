import 'dart:io';
import 'package:callme/models/resort_provider.dart';
import 'package:callme/screens/plumbing_provider.dart';
import 'package:callme/screens/resort_provider_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:callme/models/cleaning_provider.dart';
import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/screens/service_provider_form.dart';
import 'package:provider/provider.dart'; // ✅ COMMON FORM

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  final ImagePicker _picker = ImagePicker();

  List<ServiceCategory> businessCategories = [
    ServiceCategory(name: 'Salon', icon: Icons.content_cut),
    ServiceCategory(name: 'Plumbing', icon: Icons.plumbing),
    ServiceCategory(name: 'Resorts', icon: Icons.hotel),
    ServiceCategory(name: 'Real Estate', icon: Icons.house),
    ServiceCategory(name: 'Photography', icon: Icons.camera_alt),
    ServiceCategory(name: 'Cleaning', icon: Icons.cleaning_services),
    ServiceCategory(name: 'Carpenter', icon: Icons.carpenter),
    ServiceCategory(name: 'Laundry', icon: Icons.local_laundry_service),
    ServiceCategory(name: 'Mechanic', icon: Icons.car_repair),
  ];

  void _handleCategoryTap(ServiceCategory service) {
    String type = service.name.toLowerCase();

    /// ✅ CLEANING → separate page
    if (type == "cleaning") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CleaningProvider(),
        ),
      );
    }

    /// ✅ PLUMBING → separate page
    else if (type == "plumbing") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlumbingProvider(),
        ),
      );
    }

    /// ✅ RESORTS → MULTI-STEP FORM (YOUR WIREFRAME)
    else if (type == "resorts") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => ResortProvider(),
            child: const ResortProviderPage(),
          ),
        ),
      );
    }

    /// ✅ COMMON FORM SERVICES
    else if (type == "salon" || type == "laundry") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceProviderForm(type: type),
        ),
      );
    }

    /// ❌ OTHER SERVICES → dialog
    else {
      _showAddServiceDialog(service);
    }
  }

  /// 🔹 DIALOG (unchanged)
  void _showAddServiceDialog(ServiceCategory service) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    File? pickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Add ${service.name} Details'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Icon(
                      service.icon,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile No',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Id',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// IMAGE PICKER
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (image != null) {
                          setStateDialog(() {
                            pickedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: pickedImage == null
                            ? const Center(child: Text('Tap to select image'))
                            : Image.file(pickedImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter business name'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Business Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: businessCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
