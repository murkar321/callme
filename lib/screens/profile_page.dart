import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'map_picker_page.dart';

class ProfilePage extends StatefulWidget {
  final String phone;

  const ProfilePage({super.key, required this.phone});

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
  String? _networkImage;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// ================= MERGE OLD USERS =================
  Future<void> mergeOldUserIfExists(User user) async {
    final usersRef = firestore.collection('users');
    Map<String, dynamic> mergedData = {};

    /// CHECK PHONE
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      final phoneMatch = await usersRef
          .where('phone', isEqualTo: user.phoneNumber)
          .get();

      for (var doc in phoneMatch.docs) {
        if (doc.id != user.uid) {
          mergedData.addAll(doc.data());
          await usersRef.doc(doc.id).delete();
        }
      }
    }

    /// CHECK EMAIL
    if (user.email != null && user.email!.isNotEmpty) {
      final emailMatch = await usersRef
          .where('email', isEqualTo: user.email)
          .get();

      for (var doc in emailMatch.docs) {
        if (doc.id != user.uid) {
          mergedData.addAll(doc.data());
          await usersRef.doc(doc.id).delete();
        }
      }
    }

    if (mergedData.isNotEmpty) {
      await usersRef.doc(user.uid).set(
        mergedData,
        SetOptions(merge: true),
      );
    }
  }

  /// ================= LOAD USER =================
  Future<void> loadUserData() async {
    try {
      if (user != null) {
        emailController.text = user!.email ?? "";
        phoneController.text = user!.phoneNumber ?? widget.phone;

        if (user!.displayName != null) {
          final parts = user!.displayName!.split(" ");
          firstNameController.text = parts.first;
          if (parts.length > 1) {
            lastNameController.text = parts.sublist(1).join(" ");
          }
        }

        if (user!.photoURL != null) {
          _networkImage = user!.photoURL;
        }

        /// 🔄 FIRESTORE DATA
        final doc =
            await firestore.collection('users').doc(user!.uid).get();

        if (doc.exists) {
          final data = doc.data()!;

          firstNameController.text =
              data['firstName'] ?? firstNameController.text;
          lastNameController.text =
              data['lastName'] ?? lastNameController.text;
          addressController.text = data['address'] ?? "";
        }
      } else {
        phoneController.text = widget.phone;
      }

      setState(() {});
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  /// ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _networkImage = null;
      });
    }
  }

  /// ================= MAP =================
  Future<void> openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        addressController.text = result;
      });
    }
  }

  /// ================= SAVE =================
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      if (user == null) {
        throw Exception("User not logged in");
      }

      /// 🔥 MERGE BEFORE SAVE
      await mergeOldUserIfExists(user!);

      await firestore.collection('users').doc(user!.uid).set({
        'uid': user!.uid,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'photo': _networkImage ?? "",
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
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : _networkImage != null
                                  ? NetworkImage(_networkImage!)
                                  : const AssetImage("assets/user.jfif")
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: pickImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.indigo,
                              child: Icon(Icons.edit,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(child: _field(firstNameController, "First Name")),
                        const SizedBox(width: 10),
                        Expanded(child: _field(lastNameController, "Last Name")),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _field(emailController, "Email",
                        keyboard: TextInputType.emailAddress),

                    const SizedBox(height: 15),

                    _field(phoneController, "Mobile Number",
                        keyboard: TextInputType.phone),

                    const SizedBox(height: 15),

                    Column(
                      children: [
                        _field(addressController, "Address", maxLines: 3),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: openMap,
                            icon: const Icon(Icons.map),
                            label: const Text("Select on Map"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 111, 127, 217),
                        ),
                        child: const Text("Save Profile"),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout, color: Color.fromARGB(255, 185, 22, 10)),
                        label: const Text("Logout",
                            style: TextStyle(color: Color.fromARGB(255, 185, 22, 10))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

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