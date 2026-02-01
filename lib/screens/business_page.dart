import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  List<ServiceCategory> businessCategories = [
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/images/plumbing.png'),
    ServiceCategory(name: 'Electrician', imagePath: 'assets/images/electrician.png'),
  ];

  final ImagePicker _picker = ImagePicker();

  // Function to show dialog to add new service
  void _showAddServiceDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    File? pickedImage;
    String? selectedCategory; // Dropdown selection

    // Predefined categories
    List<String> categories = ['Plumbing', 'Electrician', 'Carpentry', 'Cleaning'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Service'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dropdown for selecting category
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Select Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Service Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mobile
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile No',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Id',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Address
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateDialog(() {
                            pickedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
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
                    if (nameController.text.isNotEmpty && selectedCategory != null) {
                      setState(() {
                        businessCategories.add(
                          ServiceCategory(
                            name: '${selectedCategory!} - ${nameController.text}',
                            imagePath: pickedImage?.path ?? 'assets/images/default.png',
                          ),
                        );
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name and select category')),
                      );
                    }
                  },
                  child: const Text('Add'),
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
        title: const Text('Business Services'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: businessCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final category = businessCategories[index];
            return CategoryCard(
              name: category.name,
              imagePath: category.imagePath,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
