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
        behavior: SnackBarBehavior.floating,
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

    final size =
        MediaQuery.of(context).size;

    final width =
        size.width;

    final isTablet =
        width >= 700;

    return Scaffold(

      backgroundColor:
      const Color(0xFFF3F5FA),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
        Colors.transparent,

        surfaceTintColor:
        Colors.transparent,

        centerTitle: true,

        title: const Text(

          "Provider Profile",

          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        actions: [

          Padding(

            padding:
            const EdgeInsets.only(
              right: 16,
            ),

            child: ElevatedButton.icon(

              onPressed:
              isLoading
                  ? null
                  : saveProfile,

              icon:
              const Icon(Icons.save),

              label:
              const Text("Save"),

              style:
              ElevatedButton.styleFrom(

                elevation: 0,

                backgroundColor:
                Colors.deepPurple,

                foregroundColor:
                Colors.white,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(

        children: [

          SafeArea(

            child: SingleChildScrollView(

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
                    maxWidth: 950,
                  ),

                  child: Column(

                    children: [

                      /// TOP PROFILE CARD

                      Container(

                        width: double.infinity,

                        padding:
                        EdgeInsets.all(
                          isTablet ? 30 : 22,
                        ),

                        decoration:
                        BoxDecoration(

                          gradient:
                          const LinearGradient(

                            colors: [
                              Color(0xFF6D5DF6),
                              Color(0xFF8E7BFF),
                            ],

                            begin:
                            Alignment.topLeft,

                            end:
                            Alignment.bottomRight,
                          ),

                          borderRadius:
                          BorderRadius.circular(30),

                          boxShadow: [

                            BoxShadow(

                              color:
                              Colors.deepPurple
                                  .withOpacity(0.18),

                              blurRadius: 18,

                              offset:
                              const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Column(

                          children: [

                            GestureDetector(

                              onTap: pickImage,

                              child: Stack(

                                children: [

                                  Container(

                                    padding:
                                    const EdgeInsets.all(4),

                                    decoration:
                                    BoxDecoration(

                                      shape:
                                      BoxShape.circle,

                                      border: Border.all(
                                        color:
                                        Colors.white,
                                        width: 3,
                                      ),
                                    ),

                                    child: CircleAvatar(

                                      radius:
                                      isTablet
                                          ? 62
                                          : 52,

                                      backgroundColor:
                                      Colors.white,

                                      backgroundImage:
                                      buildImageProvider(),

                                      child:
                                      profileImage == null &&
                                          imageUrl.isEmpty

                                          ? Icon(
                                        Icons.person,
                                        size:
                                        isTablet
                                            ? 55
                                            : 42,
                                        color:
                                        Colors.deepPurple,
                                      )

                                          : null,
                                    ),
                                  ),

                                  Positioned(

                                    bottom: 0,

                                    right: 0,

                                    child: Container(

                                      padding:
                                      const EdgeInsets.all(10),

                                      decoration:
                                      const BoxDecoration(

                                        color:
                                        Colors.white,

                                        shape:
                                        BoxShape.circle,
                                      ),

                                      child: const Icon(

                                        Icons.camera_alt,

                                        color:
                                        Colors.deepPurple,

                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(

                              businessController
                                  .text
                                  .isEmpty
                                  ? "Business Name"
                                  : businessController.text,

                              textAlign:
                              TextAlign.center,

                              style: TextStyle(

                                color: Colors.white,

                                fontSize:
                                isTablet
                                    ? 28
                                    : 22,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(

                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),

                              decoration:
                              BoxDecoration(

                                color:
                                Colors.white
                                    .withOpacity(0.18),

                                borderRadius:
                                BorderRadius.circular(30),
                              ),

                              child: Text(

                                widget.providerId,

                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(

                              mainAxisAlignment:
                              MainAxisAlignment.center,

                              children: [

                                Text(

                                  isActive
                                      ? "Active"
                                      : "Inactive",

                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Switch(

                                  value: isActive,

                                  activeColor:
                                  Colors.white,

                                  activeTrackColor:
                                  Colors.green,

                                  onChanged: (v) {

                                    setState(() {
                                      isActive = v;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// BUSINESS INFO

                      buildSection(

                        title:
                        "Business Information",

                        child: Column(

                          children: [

                            isTablet

                                ? Row(

                              children: [

                                Expanded(
                                  child: buildField(
                                    businessController,
                                    "Business Name",
                                    Icons.storefront,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: buildField(
                                    ownerController,
                                    "Owner Name",
                                    Icons.person,
                                  ),
                                ),
                              ],
                            )

                                : Column(

                              children: [

                                buildField(
                                  businessController,
                                  "Business Name",
                                  Icons.storefront,
                                ),

                                buildField(
                                  ownerController,
                                  "Owner Name",
                                  Icons.person,
                                ),
                              ],
                            ),

                            isTablet

                                ? Row(

                              children: [

                                Expanded(
                                  child: buildField(
                                    phoneController,
                                    "Phone",
                                    Icons.phone,
                                    keyboard:
                                    TextInputType.phone,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: buildField(
                                    emailController,
                                    "Email",
                                    Icons.email,
                                    keyboard:
                                    TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            )

                                : Column(

                              children: [

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
                              ],
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

                                const SizedBox(width: 14),

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

                      const SizedBox(height: 22),

                      /// SERVICES

                      buildSection(

                        title: "Services",

                        child: Column(

                          children: [

                            Container(

                              decoration:
                              BoxDecoration(

                                color:
                                Colors.deepPurple
                                    .withOpacity(0.06),

                                borderRadius:
                                BorderRadius.circular(18),
                              ),

                              child: SwitchListTile(

                                value: ownTools,

                                activeColor:
                                Colors.deepPurple,

                                title: const Text(

                                  "Own Tools & Equipment",

                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),

                                subtitle: const Text(
                                  "Provider has tools available",
                                ),

                                onChanged: (v) {

                                  setState(() {
                                    ownTools = v;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 22),

                            Align(

                              alignment:
                              Alignment.centerLeft,

                              child: Text(

                                "Service Categories",

                                style: TextStyle(

                                  fontSize: 15,

                                  fontWeight:
                                  FontWeight.w600,

                                  color:
                                  Colors.grey.shade700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Wrap(

                              spacing: 10,

                              runSpacing: 10,

                              children:
                              allCategories.map(

                                    (service) {

                                  final selected =
                                  selectedCategories
                                      .contains(
                                    service,
                                  );

                                  return FilterChip(

                                    label:
                                    Text(service),

                                    selected:
                                    selected,

                                    selectedColor:
                                    Colors.deepPurple
                                        .withOpacity(0.16),

                                    checkmarkColor:
                                    Colors.deepPurple,

                                    backgroundColor:
                                    Colors.grey.shade100,

                                    labelStyle:
                                    TextStyle(

                                      color:
                                      selected
                                          ? Colors.deepPurple
                                          : Colors.black87,

                                      fontWeight:
                                      FontWeight.w500,
                                    ),

                                    shape:
                                    RoundedRectangleBorder(

                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),

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

                      const SizedBox(height: 22),

                      /// BANK

                      buildSection(

                        title: "Bank Details",

                        child: Column(

                          children: [

                            buildField(
                              bankHolderController,
                              "Account Holder",
                              Icons.person_outline,
                            ),

                            isTablet

                                ? Row(

                              children: [

                                Expanded(
                                  child: buildField(
                                    accountController,
                                    "Account Number",
                                    Icons.account_balance_wallet,
                                    keyboard:
                                    TextInputType.number,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: buildField(
                                    ifscController,
                                    "IFSC Code",
                                    Icons.code,
                                  ),
                                ),
                              ],
                            )

                                : Column(

                              children: [

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
                              ],
                            ),

                            buildField(
                              upiController,
                              "UPI ID",
                              Icons.qr_code,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)

            Container(

              color:
              Colors.black.withOpacity(0.25),

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
      const EdgeInsets.all(22),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(28),

        boxShadow: [

          BoxShadow(

            color:
            Colors.black.withOpacity(0.04),

            blurRadius: 14,

            offset:
            const Offset(0, 5),
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

              fontSize: 19,

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

        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),

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
            horizontal: 18,
          ),

          enabledBorder:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(18),

            borderSide:
            BorderSide(
              color:
              Colors.grey.shade200,
            ),
          ),

          focusedBorder:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(18),

            borderSide:
            const BorderSide(
              color: Colors.deepPurple,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}          