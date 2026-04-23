import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfilePage extends StatefulWidget {
  final String phone; // ✅ FIXED

  const ProfilePage({
    super.key,
    required this.phone,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  File? _image;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// ================= LOAD USER =================
  Future<void> loadUserData() async {
    try {
      if (user != null) {
        final doc =
            await firestore.collection('users').doc(user!.uid).get();

        if (doc.exists) {
          final data = doc.data()!;

          firstNameController.text = data['firstName'] ?? "";
          lastNameController.text = data['lastName'] ?? "";
          emailController.text =
              data['email'] ?? user!.email ?? "";
          phoneController.text =
              data['phone'] ?? widget.phone;
          addressController.text = data['address'] ?? "";
        } else {
          /// fallback
          emailController.text = user!.email ?? "";
          phoneController.text = widget.phone;
        }
      } else {
        /// if no firebase auth (phone login/manual)
        phoneController.text = widget.phone;
      }
    } catch (e) {
      debugPrint("Load user error: $e");
    }
  }

  /// ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  /// ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      /// 🔥 use uid if available else phone
      final docId = user?.uid ?? widget.phone;

      await firestore.collection('users').doc(docId).set({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),

        /// (future ready)
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout Failed")),
      );
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    /// 👤 PROFILE IMAGE
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : const AssetImage("assets/user.jfif")
                                  as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.indigo,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// NAME
                    Row(
                      children: [
                        Expanded(
                          child: _field(firstNameController, "First Name"),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(lastNameController, "Last Name"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// EMAIL
                    _field(emailController, "Email",
                        keyboard: TextInputType.emailAddress),

                    const SizedBox(height: 15),

                    /// PHONE
                    _field(phoneController, "Mobile Number",
                        keyboard: TextInputType.phone),

                    const SizedBox(height: 15),

                    /// ADDRESS
                    _field(addressController, "Address", maxLines: 3),

                    const SizedBox(height: 25),

                    /// SAVE
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                        ),
                        child: const Text("Save Profile"),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// LOGOUT
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text("Logout",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 🔹 FIELD
  Widget _field(TextEditingController c, String label,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}