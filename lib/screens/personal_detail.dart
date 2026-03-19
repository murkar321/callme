import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'verification_screen.dart'; // make sure this file exists

class PersonalDetail extends StatefulWidget {
  final List<String> selectedServices;
  final String type;

  const PersonalDetail({
    super.key,
    required this.selectedServices,
    required this.type,
  });

  @override
  State<PersonalDetail> createState() => _PersonalDetailState();
}

class _PersonalDetailState extends State<PersonalDetail> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final experienceController = TextEditingController();

  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personal Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// 🔹 TYPE + SERVICES (Top Info)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Type: ${widget.type}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Services: ${widget.selectedServices.join(", ")}"),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              /// 🔹 FORM FIELDS
              buildField("Full Name", nameController),
              buildField("Phone No", phoneController,
                  keyboard: TextInputType.phone),
              buildField("Email ID", emailController,
                  keyboard: TextInputType.emailAddress),
              buildField("Address", addressController),
              buildField("City", cityController),
              buildField("Experience", experienceController),

              const SizedBox(height: 15),

              /// 🔹 PROFILE IMAGE
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Profile Photo",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: profileImage == null
                      ? const Center(child: Icon(Icons.camera_alt, size: 40))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(profileImage!, fit: BoxFit.cover),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 NEXT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerificationScreen(
                            name: nameController.text,
                            phone: phoneController.text,
                            email: emailController.text,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Next"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable Input Field
  Widget buildField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
