import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  /// 🔹 CONTROLLERS
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
        SnackBar(content: Text("Upload failed")),
      );
    }
  }

  /// ================= SUBMIT =================
  Future<void> _submitForm() async {
    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw "User not logged in";
      }

      if (businessController.text.trim().isEmpty) {
        throw "Business name required";
      }

      if (selectedCategories.isEmpty) {
        throw "Select at least one category";
      }

      final providerRef =
          FirebaseFirestore.instance.collection("providers").doc();

      final businessName = businessController.text.trim();
      final ownerName = ownerController.text.trim();
      final phone = phoneController.text.trim();

      await providerRef.set({
        /// 🔑 IDS
        "providerId": providerRef.id,
        "userId": user.uid,

        /// 🔥 BASIC INFO
        "providerName": businessName,
        "ownerName": ownerName,
        "phone": phone,

        /// 🔥 TYPE
        "serviceType": widget.type,
        "providerType": widget.providerType,
        "categories": selectedCategories,

        /// 🏢 BUSINESS INFO
        "business": {
          "businessName": businessName,
          "ownerName": ownerName,
          "phone": phone,
          "email": emailController.text.trim(),
          "address": addressController.text.trim(),
          "city": cityController.text.trim(),
          "state": stateController.text.trim(),
          "pincode": pincodeController.text.trim(),
        },

        /// 🔧 SERVICE
        "service": {
          "price": priceController.text.trim(),
          "ownTools": ownTools,
        },

        /// 💳 BANK
        "bank": {
          "accountHolder": bankHolderController.text.trim(),
          "accountNumber": accountController.text.trim(),
          "ifsc": ifscController.text.trim(),
          "upi": upiController.text.trim(),
        },

        /// 📂 DOCUMENTS
        "documents": uploadedDocs,

        /// 🔥 STATUS
        "status": "pending",
        "isActive": false,

        /// ⏱ META
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            businessName: businessName,
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
                /// STEP INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    return CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          i <= currentStep ? Colors.blue : Colors.grey,
                      child: Text("${i + 1}",
                          style: const TextStyle(color: Colors.white)),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(config),
                ),
              ],
            ),
          ),

          /// BUTTON
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
        return _card(
          "Categories",
          Icons.category,
          Column(
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
          ),
        );

      case 1:
        return _card(
          "Business Info",
          Icons.business,
          Column(
            children: [
              _field(businessController, "Business Name"),
              _field(ownerController, "Owner Name"),
              _field(phoneController, "Phone"),
              _field(emailController, "Email"),
              _field(addressController, "Address"),
            ],
          ),
        );

      case 2:
        return _card(
          "Service",
          Icons.build,
          Column(
            children: [
              _field(priceController, "Price"),
              SwitchListTile(
                title: const Text("Own Tools"),
                value: ownTools,
                onChanged: (v) => setState(() => ownTools = v),
              ),
            ],
          ),
        );

      case 3:
        return _card(
          "Bank Details",
          Icons.account_balance,
          Column(
            children: [
              _field(bankHolderController, "Holder Name"),
              _field(accountController, "Account Number"),
              _field(ifscController, "IFSC"),
              _field(upiController, "UPI"),
            ],
          ),
        );

      case 4:
        return _card(
          "Documents",
          Icons.upload_file,
          Column(
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
          ),
        );

      default:
        return const SizedBox();
    }
  }

  /// ================= HELPERS =================
  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      key: ValueKey(title),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon),
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

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}