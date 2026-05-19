import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:callme/screens/map_picker_page.dart';

class ProfilePage extends StatefulWidget {

  final String phone;

  const ProfilePage({
    super.key,
    required this.phone,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {

  /// =====================================================
  /// FORM
  /// =====================================================

  final _formKey =
      GlobalKey<FormState>();

  final firstNameController =
      TextEditingController();

  final lastNameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final addressController =
      TextEditingController();

  /// =====================================================
  /// FIREBASE
  /// =====================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  User? get user =>
      auth.currentUser;

  /// =====================================================
  /// STATE
  /// =====================================================

  bool isLoading = false;

  File? _image;

  String? _networkImage;

  /// IMPORTANT
  /// THIS STORES ORIGINAL FIRESTORE DOC ID
  String? userDocId;

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// =====================================================
  /// FIND EXISTING USER DOCUMENT
  /// =====================================================

  Future<DocumentSnapshot?> getUserDoc() async {

    try {

      if (user == null) {
        return null;
      }

      /// FIND EXISTING DOC
      final query =
          await firestore
              .collection("users")
              .where(
                "authUid",
                isEqualTo: user!.uid,
              )
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return null;
      }

      /// STORE ORIGINAL DOC ID
      userDocId =
          query.docs.first.id;

      return query.docs.first;

    } catch (e) {

      debugPrint(
        "Get User Doc Error: $e",
      );

      return null;
    }
  }

  /// =====================================================
  /// LOAD USER DATA
  /// =====================================================

  Future<void> loadUserData() async {

    try {

      if (user == null) return;

      /// AUTH DATA
      emailController.text =
          user!.email ?? "";

      phoneController.text =
          user!.phoneNumber ??
              widget.phone;

      if (user!.displayName != null &&
          user!.displayName!
              .trim()
              .isNotEmpty) {

        final parts =
            user!.displayName!
                .trim()
                .split(" ");

        firstNameController.text =
            parts.first;

        if (parts.length > 1) {

          lastNameController.text =
              parts
                  .sublist(1)
                  .join(" ");
        }
      }

      /// FIRESTORE DATA
      final doc =
          await getUserDoc();

      if (doc != null &&
          doc.exists) {

        final data =
            doc.data()
                as Map<String, dynamic>;

        firstNameController.text =
            data['firstName'] ?? "";

        lastNameController.text =
            data['lastName'] ?? "";

        emailController.text =
            data['email'] ?? "";

        phoneController.text =
            data['phone'] ?? "";

        addressController.text =
            data['address'] ?? "";

        _networkImage =
            data['photo'];
      }

      if (mounted) {
        setState(() {});
      }

    } catch (e) {

      debugPrint(
        "Load Error: $e",
      );
    }
  }

  /// =====================================================
  /// PICK IMAGE
  /// =====================================================

  Future<void> pickImage() async {

    try {

      final picked =
          await ImagePicker()
              .pickImage(
        source:
            ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked != null) {

        setState(() {

          _image =
              File(picked.path);
        });
      }

    } catch (e) {

      debugPrint(
        "Pick Image Error: $e",
      );
    }
  }

  /// =====================================================
  /// MAP PICKER
  /// =====================================================

  Future<void> openMap() async {

    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MapPickerPage(),
      ),
    );

    if (result != null &&
        result is String) {

      setState(() {

        addressController.text =
            result;
      });
    }
  }

  /// =====================================================
  /// SAVE PROFILE
  /// =====================================================

  Future<void> saveProfile() async {

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    try {

      setState(() {
        isLoading = true;
      });

      if (user == null) {
        throw Exception(
            "User not logged in");
      }

      /// GET ORIGINAL DOC
      final doc =
          await getUserDoc();

      if (doc == null) {

        throw Exception(
          "User document not found",
        );
      }

      /// IMPORTANT
      /// USE EXISTING DOC ID
      final docId =
          doc.id;

      final fullName =
          "${firstNameController.text.trim()} ${lastNameController.text.trim()}";

      /// UPDATE AUTH
      await user!
          .updateDisplayName(
        fullName,
      );

      /// UPDATE FIRESTORE
      await firestore
          .collection("users")
          .doc(docId)
          .update({

        "firstName":
            firstNameController.text
                .trim(),

        "lastName":
            lastNameController.text
                .trim(),

        "name":
            fullName,

        "email":
            emailController.text
                .trim(),

        "phone":
            phoneController.text
                .trim(),

        "address":
            addressController.text
                .trim(),

        "photo":
            _networkImage ?? "",

        "updatedAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Profile Updated Successfully",
          ),
        ),
      );

    } catch (e) {

      debugPrint(
        "Save Error: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// =====================================================
  /// LOGOUT
  /// =====================================================

  Future<void> logout() async {

    await GoogleSignIn()
        .signOut();

    await FirebaseAuth.instance
        .signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  /// =====================================================
  /// DISPOSE
  /// =====================================================

  @override
  void dispose() {

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(

        title:
            const Text("My Profile"),

        centerTitle: true,
      ),

      body: isLoading

          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : SingleChildScrollView(

              padding:
                  const EdgeInsets.all(16),

              child: Form(

                key: _formKey,

                child: Column(

                  children: [

                    /// PROFILE IMAGE

                    Stack(

                      children: [

                        CircleAvatar(

                          radius: 55,

                          backgroundColor:
                              Colors.grey.shade200,

                          backgroundImage:

                              _image != null

                                  ? FileImage(_image!)

                                  : _networkImage != null

                                      ? NetworkImage(
                                          _networkImage!,
                                        )

                                      : const AssetImage(
                                              "assets/user.jfif")
                                          as ImageProvider,
                        ),

                        Positioned(

                          bottom: 0,

                          right: 0,

                          child: InkWell(

                            onTap: pickImage,

                            child:
                                const CircleAvatar(

                              radius: 18,

                              backgroundColor:
                                  Colors.indigo,

                              child: Icon(

                                Icons.edit,

                                color:
                                    Colors.white,

                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(

                      children: [

                        Expanded(
                          child: _field(
                            firstNameController,
                            "First Name",
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _field(
                            lastNameController,
                            "Last Name",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _field(
                      emailController,
                      "Email",
                      keyboard:
                          TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 15),

                    _field(
                      phoneController,
                      "Mobile Number",
                      keyboard:
                          TextInputType.phone,
                    ),

                    const SizedBox(height: 15),

                    Column(

                      children: [

                        _field(
                          addressController,
                          "Address",
                          maxLines: 3,
                        ),

                        Align(

                          alignment:
                              Alignment.centerRight,

                          child:
                              TextButton.icon(

                            onPressed:
                                openMap,

                            icon:
                                const Icon(
                              Icons.map,
                            ),

                            label:
                                const Text(
                              "Select on Map",
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    SizedBox(

                      width: double.infinity,

                      height: 50,

                      child: ElevatedButton(

                        onPressed:
                            saveProfile,

                        child:
                            const Text(
                          "Save Profile",
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(

                      width: double.infinity,

                      height: 50,

                      child:
                          OutlinedButton.icon(

                        onPressed:
                            logout,

                        icon: const Icon(
                          Icons.logout,
                        ),

                        label:
                            const Text(
                          "Logout",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// =====================================================
  /// FIELD
  /// =====================================================

  Widget _field(
    TextEditingController c,
    String label, {

    TextInputType keyboard =
        TextInputType.text,

    int maxLines = 1,
  }) {

    return TextFormField(

      controller: c,

      keyboardType: keyboard,

      maxLines: maxLines,

      validator: (v) {

        if (v == null ||
            v.trim().isEmpty) {

          return "Required";
        }

        return null;
      },

      decoration: InputDecoration(

        labelText: label,

        filled: true,

        fillColor: Colors.white,

        border:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }
}