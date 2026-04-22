import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();

  File? imageFile;
  String imageUrl = "";

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // ================= LOAD USER =================

  Future<void> loadUserData() async {
    if (user == null) return;

    final doc =
        await firestore.collection('users').doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;

      firstName.text = data['firstName'] ?? "";
      lastName.text = data['lastName'] ?? "";
      phone.text = data['phone'] ?? "";
      email.text = data['email'] ?? user!.email ?? "";
      address.text = data['address'] ?? "";
      imageUrl = data['photo'] ?? "";

      setState(() {});
    }
  }

  // ================= PICK IMAGE =================

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ================= UPLOAD IMAGE =================

  Future<String> uploadImage() async {
    if (imageFile == null) return imageUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user!.uid}.jpg');

    await ref.putFile(imageFile!);

    return await ref.getDownloadURL();
  }

  // ================= SAVE DATA =================

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final uploadedImage = await uploadImage();

      await firestore.collection('users').doc(user!.uid).set({
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'address': address.text.trim(),
        'photo': uploadedImage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // ================= PROFILE IMAGE =================

              Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!)
                        : (imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage("assets/user.jfif")
                                as ImageProvider),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),

              // ================= FORM =================

              _field("First Name", firstName),
              _field("Last Name", lastName),
              _field("Mobile Number", phone,
                  keyboard: TextInputType.phone),
              _field("Email", email,
                  keyboard: TextInputType.emailAddress),
              _field("Address", address, maxLines: 3),

              const SizedBox(height: 20),

              // ================= SAVE BUTTON =================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : saveProfile,
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text("Save Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================

  Widget _field(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}