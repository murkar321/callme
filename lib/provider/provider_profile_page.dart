import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../provider/service_config.dart';

class ProviderProfilePage extends StatefulWidget {

  final String providerId;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
  });

  @override
  State<ProviderProfilePage> createState() =>
      _ProviderProfilePageState();
}

class _ProviderProfilePageState
    extends State<ProviderProfilePage> {

  /// =====================================================
  /// FIREBASE
  /// =====================================================

  final firestore =
      FirebaseFirestore.instance;

  final storage =
      FirebaseStorage.instance;

  /// =====================================================
  /// STATE
  /// =====================================================

  bool isLoading = false;

  File? profileImage;

  String imageUrl = "";

  bool ownTools = false;

  bool isActive = true;

  List<String> selectedCategories = [];

  List<String> allCategories = [];

  /// =====================================================
  /// CONTROLLERS
  /// =====================================================

  final businessController =
      TextEditingController();

  final ownerController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final addressController =
      TextEditingController();

  final cityController =
      TextEditingController();

  final stateController =
      TextEditingController();

  final pincodeController =
      TextEditingController();

  final bankHolderController =
      TextEditingController();

  final accountController =
      TextEditingController();

  final ifscController =
      TextEditingController();

  final upiController =
      TextEditingController();

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {
    super.initState();
    loadProvider();
  }

  /// =====================================================
  /// LOAD PROVIDER
  /// =====================================================

  Future<void> loadProvider() async {

    try {

      setState(() {
        isLoading = true;
      });

      final snap = await firestore
          .collection("providers")
          .doc(widget.providerId)
          .get();

      if (!snap.exists) return;

      final data = snap.data()!;

      final business =
          data['business'] ?? {};

      final service =
          data['service'] ?? {};

      final bank =
          data['bank'] ?? {};

      businessController.text =
          business['businessName'] ?? "";

      ownerController.text =
          business['ownerName'] ?? "";

      phoneController.text =
          business['phone'] ?? "";

      emailController.text =
          business['email'] ?? "";

      addressController.text =
          business['address'] ?? "";

      cityController.text =
          business['city'] ?? "";

      stateController.text =
          business['state'] ?? "";

      pincodeController.text =
          business['pincode'] ?? "";

      imageUrl =
          business['image'] ?? "";

      ownTools =
          service['ownTools'] ?? false;

      bankHolderController.text =
          bank['accountHolder'] ?? "";

      accountController.text =
          bank['accountNumber'] ?? "";

      ifscController.text =
          bank['ifsc'] ?? "";

      upiController.text =
          bank['upi'] ?? "";

      isActive =
          data['isActive'] ?? true;

      selectedCategories =
          List<String>.from(
        data['categories'] ?? [],
      );

      final serviceType =
          data['serviceType'] ?? "";

      if (serviceConfigs.containsKey(
          serviceType)) {

        allCategories =
            List<String>.from(
          serviceConfigs[serviceType]!
              .serviceCategories,
        );
      }

    } catch (e) {

      debugPrint(e.toString());

      showMsg(
        "Failed to load profile",
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// =====================================================
  /// IMAGE PICK
  /// =====================================================

  Future<void> pickImage() async {

    try {

      final picked =
          await ImagePicker().pickImage(

        source: ImageSource.gallery,

        imageQuality: 70,
      );

      if (picked != null) {

        setState(() {
          profileImage =
              File(picked.path);
        });
      }

    } catch (e) {

      showMsg("Image pick failed");
    }
  }

  /// =====================================================
  /// SAVE PROFILE
  /// =====================================================

  Future<void> saveProfile() async {

    try {

      setState(() {
        isLoading = true;
      });

      String updatedImage =
          imageUrl;

      /// IMAGE UPLOAD

      if (profileImage != null) {

        final ref = storage
            .ref()
            .child(
          "provider_images/${widget.providerId}.jpg",
        );

        await ref.putFile(
          profileImage!,
        );

        updatedImage =
            await ref.getDownloadURL();
      }

      /// UPDATE FIRESTORE

      await firestore
          .collection("providers")
          .doc(widget.providerId)
          .update({

        "updatedAt":
            FieldValue.serverTimestamp(),

        "isActive":
            isActive,

        "categories":
            selectedCategories,

        "providerName":
            businessController.text.trim(),

        "ownerName":
            ownerController.text.trim(),

        "phone":
            phoneController.text.trim(),

        "business": {

          "businessName":
              businessController.text.trim(),

          "ownerName":
              ownerController.text.trim(),

          "phone":
              phoneController.text.trim(),

          "email":
              emailController.text.trim(),

          "address":
              addressController.text.trim(),

          "city":
              cityController.text.trim(),

          "state":
              stateController.text.trim(),

          "pincode":
              pincodeController.text.trim(),

          "image":
              updatedImage,
        },

        "service": {

          "ownTools":
              ownTools,
        },

        "bank": {

          "accountHolder":
              bankHolderController.text.trim(),

          "accountNumber":
              accountController.text.trim(),

          "ifsc":
              ifscController.text.trim(),

          "upi":
              upiController.text.trim(),
        },
      });

      imageUrl = updatedImage;

      showMsg(
        "Profile Updated Successfully",
      );

      setState(() {});

    } catch (e) {

      debugPrint(e.toString());

      showMsg(
        "Profile update failed",
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// =====================================================
  /// SNACKBAR
  /// =====================================================

  void showMsg(String msg) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(msg),
      ),
    );
  }

  /// =====================================================
  /// IMAGE PROVIDER
  /// =====================================================

  ImageProvider? buildImageProvider() {

    if (profileImage != null) {
      return FileImage(profileImage!);
    }

    if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }

    return null;
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF4F7FC),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
        Colors.white,

        centerTitle: true,

        title: const Text(

          "Provider Profile",

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),

        actions: [

          Padding(

            padding:
            const EdgeInsets.only(
              right: 12,
            ),

            child: ElevatedButton.icon(

              onPressed:
              isLoading
                  ? null
                  : saveProfile,

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                Colors.deepPurple,

                foregroundColor:
                Colors.white,

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),

              icon:
              const Icon(Icons.save),

              label:
              const Text("Save"),
            ),
          ),
        ],
      ),

      body: Stack(

        children: [

          SingleChildScrollView(

            padding:
            const EdgeInsets.all(16),

            child: Column(

              children: [

                /// PROFILE CARD

                Container(

                  width: double.infinity,

                  padding:
                  const EdgeInsets.all(24),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(24),
                  ),

                  child: Column(

                    children: [

                      GestureDetector(

                        onTap: pickImage,

                        child: Stack(

                          children: [

                            CircleAvatar(

                              radius: 55,

                              backgroundColor:
                              Colors.deepPurple
                                  .withOpacity(0.1),

                              backgroundImage:
                              buildImageProvider(),

                              child:

                              profileImage == null &&
                                  imageUrl.isEmpty

                                  ? const Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: Colors.deepPurple,
                              )

                                  : null,
                            ),

                            Positioned(

                              bottom: 0,

                              right: 0,

                              child: Container(

                                padding:
                                const EdgeInsets.all(8),

                                decoration:
                                const BoxDecoration(

                                  color:
                                  Colors.deepPurple,

                                  shape:
                                  BoxShape.circle,
                                ),

                                child: const Icon(

                                  Icons.edit,

                                  size: 16,

                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(

                        businessController.text.isEmpty
                            ? "Business Name"
                            : businessController.text,

                        style: const TextStyle(

                          fontSize: 22,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(

                        widget.providerId,

                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                buildSection(

                  title: "Business Information",

                  child: Column(

                    children: [

                      buildField(
                        businessController,
                        "Business Name",
                        Icons.store,
                      ),

                      buildField(
                        ownerController,
                        "Owner Name",
                        Icons.person,
                      ),

                      buildField(
                        phoneController,
                        "Phone",
                        Icons.phone,
                        keyboard:
                        TextInputType.phone,
                      ),

                      buildField(
                        emailController,
                        "Email",
                        Icons.email,
                        keyboard:
                        TextInputType.emailAddress,
                      ),

                      buildField(
                        addressController,
                        "Address",
                        Icons.location_on,
                      ),

                      Row(

                        children: [

                          Expanded(
                            child: buildField(
                              cityController,
                              "City",
                              Icons.location_city,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: buildField(
                              stateController,
                              "State",
                              Icons.map,
                            ),
                          ),
                        ],
                      ),

                      buildField(
                        pincodeController,
                        "Pincode",
                        Icons.pin_drop,
                        keyboard:
                        TextInputType.number,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                buildSection(

                  title: "Services",

                  child: Column(

                    children: [

                      SwitchListTile(

                        value: ownTools,

                        activeColor:
                        Colors.deepPurple,

                        title: const Text(
                          "Own Tools & Equipment",
                        ),

                        onChanged: (v) {

                          setState(() {
                            ownTools = v;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      Wrap(

                        spacing: 10,

                        runSpacing: 10,

                        children:
                        allCategories.map(

                              (service) {

                            final selected =
                            selectedCategories.contains(
                              service,
                            );

                            return FilterChip(

                              label:
                              Text(service),

                              selected:
                              selected,

                              selectedColor:
                              Colors.deepPurple
                                  .withOpacity(0.15),

                              onSelected:
                                  (value) {

                                setState(() {

                                  if (value) {

                                    selectedCategories.add(
                                      service,
                                    );

                                  } else {

                                    selectedCategories.remove(
                                      service,
                                    );
                                  }
                                });
                              },
                            );
                          },
                        ).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                buildSection(

                  title: "Bank Details",

                  child: Column(

                    children: [

                      buildField(
                        bankHolderController,
                        "Account Holder",
                        Icons.person,
                      ),

                      buildField(
                        accountController,
                        "Account Number",
                        Icons.account_balance_wallet,
                        keyboard:
                        TextInputType.number,
                      ),

                      buildField(
                        ifscController,
                        "IFSC Code",
                        Icons.code,
                      ),

                      buildField(
                        upiController,
                        "UPI ID",
                        Icons.qr_code,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          if (isLoading)

            Container(

              color:
              Colors.black.withOpacity(0.2),

              child:
              const Center(

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

  Widget buildSection({

    required String title,

    required Widget child,
  }) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(24),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(

            title,

            style: const TextStyle(

              fontSize: 18,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  /// =====================================================
  /// FIELD
  /// =====================================================

  Widget buildField(
      TextEditingController controller,
      String hint,
      IconData icon, {

        TextInputType keyboard =
            TextInputType.text,
      }) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),

      child: TextField(

        controller: controller,

        keyboardType:
        keyboard,

        decoration:
        InputDecoration(

          hintText: hint,

          prefixIcon:
          Icon(
            icon,
            color:
            Colors.deepPurple,
          ),

          filled: true,

          fillColor:
          const Color(0xFFF7F8FC),

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 18,
          ),

          border:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(18),

            borderSide:
            BorderSide.none,
          ),
        ),
      ),
    );
  }
}