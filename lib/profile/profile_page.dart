import 'dart:io';

import 'package:callme/screens/logo_page.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  /// =====================================================
  /// CONTROLLERS
  /// =====================================================

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

  User? get currentUser =>
      auth.currentUser;

  /// =====================================================
  /// STATE
  /// =====================================================

  bool isLoading = true;

  File? imageFile;

  String networkImage = "";

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {
    super.initState();

    loadUserData();
  }

  /// =====================================================
  /// LOAD USER DATA
  /// =====================================================

  Future<void> loadUserData() async {
    try {
      final user = currentUser;

      if (user == null) return;

      setState(() {
        isLoading = true;
      });

      /// ===============================================
      /// GET FIRESTORE USER
      /// ===============================================

      final doc = await firestore
          .collection("users")
          .doc(user.uid)
          .get();

      /// ===============================================
      /// AUTH DATA
      /// ===============================================

      phoneController.text =
          user.phoneNumber ??
              widget.phone;

      emailController.text =
          user.email ?? "";

      if (user.displayName != null &&
          user.displayName!
              .trim()
              .isNotEmpty) {
        final names = user
            .displayName!
            .trim()
            .split(" ");

        firstNameController.text =
            names.first;

        if (names.length > 1) {
          lastNameController.text =
              names
                  .sublist(1)
                  .join(" ");
        }
      }

      /// ===============================================
      /// FIRESTORE DATA
      /// ===============================================

      if (doc.exists) {
        final data =
            doc.data() ?? {};

        firstNameController.text =
            data["firstName"] ?? "";

        lastNameController.text =
            data["lastName"] ?? "";

        emailController.text =
            data["email"] ??
                emailController.text;

        phoneController.text =
            data["phone"] ??
                phoneController.text;

        addressController.text =
            data["address"] ?? "";

        networkImage =
            data["photo"] ?? "";
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        "LOAD USER ERROR : $e",
      );

      showMsg(
        "Failed to load profile",
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
          imageFile =
              File(picked.path);
        });
      }
    } catch (e) {
      debugPrint(
        "IMAGE PICK ERROR : $e",
      );
    }
  }

  /// =====================================================
  /// OPEN MAP
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
      final user = currentUser;

      if (user == null) {
        showMsg(
          "User not found",
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      final fullName =
          "${firstNameController.text.trim()} ${lastNameController.text.trim()}";

      /// ===============================================
      /// UPDATE AUTH
      /// ===============================================

      await user.updateDisplayName(
        fullName,
      );

      await user.reload();

      /// ===============================================
      /// SAVE FIRESTORE
      /// ===============================================

      await firestore
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "uid": user.uid,

          "firstName":
              firstNameController.text
                  .trim(),

          "lastName":
              lastNameController.text
                  .trim(),

          "name": fullName,

          "email":
              emailController.text
                  .trim(),

          "phone":
              phoneController.text
                  .trim(),

          "address":
              addressController.text
                  .trim(),

          "photo": networkImage,

          "role": "user",

          "updatedAt":
              FieldValue.serverTimestamp(),

          "createdAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      await loadUserData();

      showMsg(
        "Profile Updated Successfully",
      );
    } catch (e) {
      debugPrint(
        "SAVE PROFILE ERROR : $e",
      );

      showMsg(
        "Failed to update profile",
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
    try {
      await auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LogoPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        "LOGOUT ERROR : $e",
      );
    }
  }

  /// =====================================================
  /// MESSAGE
  /// =====================================================

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        content: Text(msg),
      ),
    );
  }

  /// =====================================================
  /// IMAGE
  /// =====================================================

  ImageProvider buildImage() {
    if (imageFile != null) {
      return FileImage(imageFile!);
    }

    if (networkImage.isNotEmpty) {
      return NetworkImage(
        networkImage,
      );
    }

    return const AssetImage(
      "assets/user.jfif",
    );
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context)
            .size
            .width;

    final isTablet =
        width > 700;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.transparent,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    isTablet ? 28 : 16,
                vertical: 16,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 850,
                  ),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      children: [
                        /// PROFILE CARD

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .all(24),

                          decoration:
                              BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(
                                    0xFF5B67F1),
                                Color(
                                    0xFF7D89FF),
                              ],
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              30,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .indigo
                                    .withOpacity(
                                        0.2),

                                blurRadius: 18,

                                offset:
                                    const Offset(
                                        0, 8),
                              ),
                            ],
                          ),

                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .all(4),

                                    decoration:
                                        BoxDecoration(
                                      shape:
                                          BoxShape
                                              .circle,

                                      border:
                                          Border.all(
                                        color: Colors
                                            .white,

                                        width: 3,
                                      ),
                                    ),

                                    child:
                                        CircleAvatar(
                                      radius:
                                          isTablet
                                              ? 62
                                              : 55,

                                      backgroundImage:
                                          buildImage(),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 0,
                                    right: 0,

                                    child:
                                        InkWell(
                                      onTap:
                                          pickImage,

                                      child:
                                          Container(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          10,
                                        ),

                                        decoration:
                                            const BoxDecoration(
                                          color:
                                              Colors.white,

                                          shape:
                                              BoxShape.circle,
                                        ),

                                        child:
                                            const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color:
                                              Colors.indigo,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                  height: 18),

                              Text(
                                "${firstNameController.text} ${lastNameController.text}",

                                textAlign:
                                    TextAlign
                                        .center,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,

                                  fontSize: 24,

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                  height: 8),

                              Text(
                                phoneController
                                    .text,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 24),

                        /// FORM

                        _section(
                          title:
                              "Personal Information",

                          child: Column(
                            children: [
                              isTablet
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child:
                                              _field(
                                            firstNameController,
                                            "First Name",
                                            Icons
                                                .person,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                16),

                                        Expanded(
                                          child:
                                              _field(
                                            lastNameController,
                                            "Last Name",
                                            Icons
                                                .person_outline,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _field(
                                          firstNameController,
                                          "First Name",
                                          Icons
                                              .person,
                                        ),

                                        _field(
                                          lastNameController,
                                          "Last Name",
                                          Icons
                                              .person_outline,
                                        ),
                                      ],
                                    ),

                              _field(
                                emailController,
                                "Email Address",
                                Icons.email,
                                keyboard:
                                    TextInputType
                                        .emailAddress,
                              ),

                              _field(
                                phoneController,
                                "Mobile Number",
                                Icons.phone,
                                keyboard:
                                    TextInputType
                                        .phone,
                              ),

                              _field(
                                addressController,
                                "Address",
                                Icons
                                    .location_on,
                                maxLines: 3,
                              ),

                              Align(
                                alignment:
                                    Alignment
                                        .centerRight,

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
                                    "Pick From Map",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 28),

                        /// SAVE BUTTON

                        SizedBox(
                          width:
                              double.infinity,
                          height: 56,

                          child:
                              ElevatedButton.icon(
                            onPressed:
                                saveProfile,

                            icon:
                                const Icon(
                              Icons.save,
                            ),

                            label:
                                const Text(
                              "Save Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              elevation: 0,

                              backgroundColor:
                                  Colors
                                      .indigo,

                              foregroundColor:
                                  Colors
                                      .white,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 16),

                        /// LOGOUT

                        SizedBox(
                          width:
                              double.infinity,
                          height: 56,

                          child:
                              OutlinedButton.icon(
                            onPressed:
                                logout,

                            icon:
                                const Icon(
                              Icons.logout,
                            ),

                            label:
                                const Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  Colors.red,

                              side:
                                  BorderSide(
                                color: Colors
                                    .red
                                    .shade200,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                            height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black
                  .withOpacity(0.2),

              child: const Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// =====================================================
  /// SECTION
  /// =====================================================

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),

            blurRadius: 14,

            offset:
                const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 22),

          child,
        ],
      ),
    );
  }

  /// =====================================================
  /// FIELD
  /// =====================================================

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboard =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: TextFormField(
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
          hintText: hint,

          prefixIcon: Icon(
            icon,
            color: Colors.indigo,
          ),

          filled: true,

          fillColor:
              const Color(0xFFF7F8FC),

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),

            borderSide: BorderSide(
              color:
                  Colors.grey.shade200,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),

            borderSide:
                const BorderSide(
              color: Colors.indigo,
              width: 1.3,
            ),
          ),
        ),
      ),
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
}