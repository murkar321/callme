import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../provider/service_config.dart';
import '../provider/succespage.dart';

class ServiceProviderForm extends StatefulWidget {
  final String type;
  final String providerType;

  const ServiceProviderForm({
    super.key,
    required this.type,
    required this.providerType,
  });

  @override
  State<ServiceProviderForm> createState() =>
      _ServiceProviderFormState();
}

class _ServiceProviderFormState extends State<ServiceProviderForm> {
  int currentStep = 0;
  bool isLoading = false;

  final List<String> selectedCategories = [];
  Map<String, String> uploadedDocs = {};

  bool ownTools = false;

  File? businessImage;

  /// CONTROLLERS
  final businessController = TextEditingController();
  final ownerController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final priceController = TextEditingController();
  final bankHolderController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  /// ================= IMAGE PICK =================
  Future<void> pickBusinessImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        businessImage = File(picked.path);
      });
    }
  }

  /// ================= LOCATION =================
  Future<void> fillLocation() async {
    try {
      await Geolocator.requestPermission();

      Position pos = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
              pos.latitude, pos.longitude);

      final place = placemarks.first;

      setState(() {
        addressController.text =
            "${place.street}, ${place.locality}";
        cityController.text = place.locality ?? "";
        stateController.text = place.administrativeArea ?? "";
        pincodeController.text = place.postalCode ?? "";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location failed")),
      );
    }
  }

  /// ================= FILE UPLOAD =================
  Future<void> _uploadDocument(String docName) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      final file = File(result.files.single.path!);
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance
          .ref()
          .child("provider_docs/$userId/$docName");

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() {
        uploadedDocs[docName] = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$docName uploaded")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed")),
      );
    }
  }

  /// ================= SUBMIT =================
  Future<void> _submitForm() async {
    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw "User not logged in";
      if (businessController.text.trim().isEmpty)
        throw "Business name required";
      if (selectedCategories.isEmpty)
        throw "Select at least one category";

      /// 🔥 IMAGE UPLOAD
      String imageUrl = "";
      if (businessImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("provider_images/${user.uid}.jpg");

        await ref.putFile(businessImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final providerRef =
          FirebaseFirestore.instance.collection("providers").doc();

      await providerRef.set({
        "providerId": providerRef.id,
        "userId": user.uid,

        "providerName": businessController.text.trim(),
        "ownerName": ownerController.text.trim(),
        "phone": phoneController.text.trim(),

        "serviceType": widget.type,
        "providerType": widget.providerType,
        "categories": selectedCategories,

        "business": {
          "businessName": businessController.text.trim(),
          "ownerName": ownerController.text.trim(),
          "phone": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "address": addressController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
          "image": imageUrl,
        },

        "service": {
          "price": priceController.text.trim(),
          "ownTools": ownTools,
        },

        "bank": {
          "accountHolder": bankHolderController.text.trim(),
          "accountNumber": accountController.text.trim(),
          "ifsc": ifscController.text.trim(),
          "upi": upiController.text.trim(),
        },

        "documents": uploadedDocs,

        "status": "pending",
        "isActive": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            businessName: businessController.text.trim(),
            providerType: widget.providerType,
            serviceType: widget.type,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void nextStep() {
    if (currentStep < 4) {
      setState(() => currentStep++);
    } else {
      _submitForm();
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final config = serviceConfigs[widget.type]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("${widget.type} Registration"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (currentStep + 1) / 5,
                ),
                const SizedBox(height: 20),
                _buildStep(config),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: isLoading ? null : nextStep,
                child: Text(currentStep == 4 ? "Submit" : "Continue"),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  /// ================= STEPS =================
  Widget _buildStep(config) {
    switch (currentStep) {

      case 0:
        return _card("Categories", Icons.category, Column(
          children: config.serviceCategories.map<Widget>((cat) {
            return CheckboxListTile(
              title: Text(cat),
              value: selectedCategories.contains(cat),
              onChanged: (val) {
                setState(() {
                  val!
                      ? selectedCategories.add(cat)
                      : selectedCategories.remove(cat);
                });
              },
            );
          }).toList(),
        ));

      case 1:
        return _card("Business Info", Icons.business, Column(
          children: [

            GestureDetector(
              onTap: pickBusinessImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                businessImage != null ? FileImage(businessImage!) : null,
                child: businessImage == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),

            const SizedBox(height: 15),

            _field(businessController, "Business Name", Icons.store),
            _field(ownerController, "Owner Name", Icons.person),
            _field(phoneController, "Phone", Icons.phone),
            _field(emailController, "Email", Icons.email),

            Row(
              children: [
                Expanded(
                  child: _field(addressController, "Address", Icons.location_on),
                ),
                IconButton(
                  onPressed: fillLocation,
                  icon: const Icon(Icons.my_location),
                )
              ],
            ),

            _field(cityController, "City", Icons.location_city),
            _field(stateController, "State", Icons.map),
            _field(pincodeController, "Pincode", Icons.pin),
          ],
        ));

      case 2:
        return _card("Service", Icons.build, Column(
          children: [
            _field(priceController, "Price", Icons.currency_rupee),
            SwitchListTile(
              title: const Text("Own Tools"),
              value: ownTools,
              onChanged: (v) => setState(() => ownTools = v),
            ),
          ],
        ));

      case 3:
        return _card("Bank Details", Icons.account_balance, Column(
          children: [
            _field(bankHolderController, "Holder Name", Icons.person),
            _field(accountController, "Account Number", Icons.numbers),
            _field(ifscController, "IFSC", Icons.code),
            _field(upiController, "UPI", Icons.qr_code),
          ],
        ));

      case 4:
        return _card("Documents", Icons.upload_file, Column(
          children: config.requiredDocuments.map<Widget>((doc) {
            final uploaded = uploadedDocs.containsKey(doc);

            return ListTile(
              title: Text(doc),
              trailing: ElevatedButton(
                onPressed: () => _uploadDocument(doc),
                child: Text(uploaded ? "Update" : "Upload"),
              ),
            );
          }).toList(),
        ));

      default:
        return const SizedBox();
    }
  }

  /// ================= UI HELPERS =================
  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}