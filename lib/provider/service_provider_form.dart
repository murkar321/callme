import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

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

class _ServiceProviderFormState
    extends State<ServiceProviderForm> {
  int currentStep = 0;
  bool isLoading = false;

  final PageController _pageController =
      PageController();

  final List<String> selectedCategories = [];

  Map<String, String> uploadedDocs =
      {};

  bool ownTools = false;

  File? businessImage;

  /// CONTROLLERS
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

  /// ================= IMAGE PICK =================
  Future<void> pickBusinessImage() async {
    final picked =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        businessImage =
            File(picked.path);
      });
    }
  }

  /// ================= LOCATION =================
  Future<void> fillLocation() async {
    try {
      LocationPermission permission =
          await Geolocator
              .requestPermission();

      if (permission ==
              LocationPermission
                  .denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        return;
      }

      Position pos =
          await Geolocator
              .getCurrentPosition();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      final place = placemarks.first;

      setState(() {
        addressController.text =
            "${place.street}, ${place.subLocality}";

        cityController.text =
            place.locality ?? "";

        stateController.text =
            place.administrativeArea ??
                "";

        pincodeController.text =
            place.postalCode ?? "";
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Location fetched"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Location failed"),
        ),
      );
    }
  }

  /// ================= FILE UPLOAD =================
  Future<void> _uploadDocument(
      String docName) async {
    try {
      final result =
          await FilePicker.platform
              .pickFiles();

      if (result == null) return;

      final file = File(
        result.files.single.path!,
      );

      final userId =
          FirebaseAuth.instance
              .currentUser!
              .uid;

      final ref =
          FirebaseStorage.instance
              .ref()
              .child(
                "provider_docs/$userId/$docName",
              );

      await ref.putFile(file);

      final url =
          await ref.getDownloadURL();

      setState(() {
        uploadedDocs[docName] = url;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("$docName uploaded"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text("Upload failed"),
        ),
      );
    }
  }

  /// ================= SUBMIT =================
  Future<void> _submitForm() async {
    try {
      setState(() => isLoading = true);

      final user =
          FirebaseAuth
              .instance.currentUser;

      if (user == null) {
        throw "User not logged in";
      }

      if (businessController.text
          .trim()
          .isEmpty) {
        throw "Business name required";
      }

      if (selectedCategories
          .isEmpty) {
        throw "Select at least one category";
      }

      /// IMAGE UPLOAD
      String imageUrl = "";

      if (businessImage != null) {
        final ref =
            FirebaseStorage.instance
                .ref()
                .child(
                  "provider_images/${user.uid}.jpg",
                );

        await ref.putFile(
            businessImage!);

        imageUrl =
            await ref.getDownloadURL();
      }

      final providerRef =
          FirebaseFirestore.instance
              .collection(
                "providers",
              )
              .doc();

      await providerRef.set({
        "providerId":
            providerRef.id,

        "userId": user.uid,

        "providerName":
            businessController.text
                .trim(),

        "ownerName":
            ownerController.text
                .trim(),

        "phone":
            phoneController.text
                .trim(),

        "serviceType":
            widget.type,

        "providerType":
            widget.providerType,

        "categories":
            selectedCategories,

        "business": {
          "businessName":
              businessController
                  .text
                  .trim(),

          "ownerName":
              ownerController.text
                  .trim(),

          "phone":
              phoneController.text
                  .trim(),

          "email":
              emailController.text
                  .trim(),

          "address":
              addressController.text
                  .trim(),

          "city":
              cityController.text
                  .trim(),

          "state":
              stateController.text
                  .trim(),

          "pincode":
              pincodeController.text
                  .trim(),

          "image": imageUrl,
        },

        "service": {
          "ownTools": ownTools,
        },

        "bank": {
          "accountHolder":
              bankHolderController
                  .text
                  .trim(),

          "accountNumber":
              accountController.text
                  .trim(),

          "ifsc":
              ifscController.text
                  .trim(),

          "upi":
              upiController.text
                  .trim(),
        },

        "documents":
            uploadedDocs,

        "status": "pending",

        "isActive": false,

        "createdAt":
            FieldValue
                .serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            businessName:
                businessController
                    .text
                    .trim(),

            providerType:
                widget.providerType,

            serviceType:
                widget.type,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(e.toString()),
        ),
      );
    } finally {
      setState(
          () => isLoading = false);
    }
  }

  void nextStep() {
    if (currentStep < 4) {
      setState(() {
        currentStep++;
      });

      _pageController.animateToPage(
        currentStep,
        duration: const Duration(
            milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      _pageController.animateToPage(
        currentStep,
        duration: const Duration(
            milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final config =
        serviceConfigs[widget.type]!;

    final width =
        MediaQuery.of(context)
            .size
            .width;

    final isDesktop =
        width > 900;

    final isTablet =
        width > 600;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,

        title: Text(
          "${widget.type} Registration",

          style: const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1100,
                ),

                child: Row(
                  children: [
                    /// LEFT PANEL
                    if (isDesktop)
                      Expanded(
                        flex: 2,

                        child: Container(
                          margin:
                              const EdgeInsets.all(
                            20,
                          ),

                          decoration:
                              BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(
                                  0xFF6C63FF,
                                ),
                                Color(
                                  0xFF8E7CFF,
                                ),
                              ],
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              32,
                            ),
                          ),

                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              40,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [
                                const Icon(
                                  Icons
                                      .verified_user_rounded,
                                  color:
                                      Colors.white,
                                  size: 70,
                                ),

                                const SizedBox(
                                    height:
                                        24),

                                Text(
                                  "Become a Verified ${widget.providerType}",

                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        34,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        20),

                                Text(
                                  "Complete your registration and start receiving bookings instantly.",

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                      0.9,
                                    ),

                                    fontSize:
                                        16,
                                    height:
                                        1.6,
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        40),

                                _sideStep(
                                  0,
                                  "Select Categories",
                                ),

                                _sideStep(
                                  1,
                                  "Business Information",
                                ),

                                _sideStep(
                                  2,
                                  "Service Details",
                                ),

                                _sideStep(
                                  3,
                                  "Bank Details",
                                ),

                                _sideStep(
                                  4,
                                  "Documents Upload",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    /// FORM AREA
                    Expanded(
                      flex: 3,

                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          isTablet
                              ? 24
                              : 16,
                        ),

                        child: Column(
                          children: [
                            if (!isDesktop)
                              _mobileHeader(),

                            const SizedBox(
                                height:
                                    14),

                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                100,
                              ),

                              child:
                                  LinearProgressIndicator(
                                minHeight:
                                    10,

                                value:
                                    (currentStep +
                                            1) /
                                        5,

                                backgroundColor:
                                    Colors
                                        .grey
                                        .shade300,

                                color: Colors
                                    .deepPurple,
                              ),
                            ),

                            const SizedBox(
                                height:
                                    24),

                            Expanded(
                              child:
                                  PageView(
                                controller:
                                    _pageController,

                                physics:
                                    const NeverScrollableScrollPhysics(),

                                children: [
                                  _categoriesStep(
                                    config,
                                  ),

                                  _businessStep(),

                                  _serviceStep(),

                                  _bankStep(),

                                  _documentsStep(
                                    config,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                height:
                                    18),

                            Row(
                              children: [
                                if (currentStep >
                                    0)
                                  Expanded(
                                    child:
                                        OutlinedButton(
                                      onPressed:
                                          previousStep,

                                      style:
                                          OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size(
                                          double
                                              .infinity,
                                          58,
                                        ),

                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),

                                      child:
                                          const Text(
                                        "Back",
                                      ),
                                    ),
                                  ),

                                if (currentStep >
                                    0)
                                  const SizedBox(
                                      width:
                                          14),

                                Expanded(
                                  flex: 2,

                                  child:
                                      ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : nextStep,

                                    style:
                                        ElevatedButton.styleFrom(
                                      elevation:
                                          0,

                                      backgroundColor:
                                          Colors
                                              .deepPurple,

                                      foregroundColor:
                                          Colors
                                              .white,

                                      minimumSize:
                                          const Size(
                                        double
                                            .infinity,
                                        58,
                                      ),

                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                      ),
                                    ),

                                    child:
                                        Text(
                                      currentStep ==
                                              4
                                          ? "Submit Registration"
                                          : "Continue",

                                      style:
                                          const TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black
                  .withOpacity(0.4),

              child: const Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// ================= MOBILE HEADER =================
  Widget _mobileHeader() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8E7CFF),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              14,
            ),

            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.2),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  widget.providerType,

                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(
                    height: 4),

                Text(
                  "Complete all steps to activate your provider profile",

                  style: TextStyle(
                    color: Colors
                        .white
                        .withOpacity(
                      0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SIDE STEP =================
  Widget _sideStep(
      int index,
      String title) {
    final active =
        currentStep == index;

    final completed =
        currentStep > index;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 22,
      ),

      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 300,
            ),

            width: 34,
            height: 34,

            decoration:
                BoxDecoration(
              color: completed
                  ? Colors.green
                  : active
                      ? Colors.white
                      : Colors.white24,

              shape: BoxShape.circle,
            ),

            child: Icon(
              completed
                  ? Icons.check
                  : Icons.circle,

              size: 16,

              color: completed
                  ? Colors.white
                  : active
                      ? Colors
                          .deepPurple
                      : Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,

              style: TextStyle(
                color:
                    Colors.white,

                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight
                        .w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CATEGORY STEP =================
  Widget _categoriesStep(
      dynamic config) {
    return _glassCard(
      title: "Select Categories",

      subtitle:
          "Choose the services you provide",

      child: Wrap(
        spacing: 12,
        runSpacing: 12,

        children: config
            .serviceCategories
            .map<Widget>(
          (cat) {
            final selected =
                selectedCategories
                    .contains(cat);

            return GestureDetector(
              onTap: () {
                setState(() {
                  selected
                      ? selectedCategories
                          .remove(cat)
                      : selectedCategories
                          .add(cat);
                });
              },

              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds:
                      250,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),

                decoration:
                    BoxDecoration(
                  color: selected
                      ? Colors
                          .deepPurple
                      : Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),

                  border:
                      Border.all(
                    color: selected
                        ? Colors
                            .deepPurple
                        : Colors.grey
                            .shade300,
                  ),
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize
                          .min,

                  children: [
                    Icon(
                      selected
                          ? Icons
                              .check_circle
                          : Icons
                              .circle_outlined,

                      color: selected
                          ? Colors
                              .white
                          : Colors
                              .grey,
                    ),

                    const SizedBox(
                        width:
                            10),

                    Text(
                      cat,

                      style:
                          TextStyle(
                        color: selected
                            ? Colors
                                .white
                            : Colors
                                .black87,

                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  /// ================= BUSINESS STEP =================
  Widget _businessStep() {
    return _glassCard(
      title: "Business Information",

      subtitle:
          "Fill your professional details",

      child: Column(
        children: [
          GestureDetector(
            onTap:
                pickBusinessImage,

            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,

                  backgroundColor:
                      Colors
                          .deepPurple
                          .withOpacity(
                    0.1,
                  ),

                  backgroundImage:
                      businessImage !=
                              null
                          ? FileImage(
                              businessImage!,
                            )
                          : null,

                  child: businessImage ==
                          null
                      ? const Icon(
                          Icons
                              .camera_alt,
                          size: 34,
                          color: Colors
                              .deepPurple,
                        )
                      : null,
                ),

                Positioned(
                  right: 0,
                  bottom: 0,

                  child: Container(
                    padding:
                        const EdgeInsets
                            .all(8),

                    decoration:
                        const BoxDecoration(
                      color: Colors
                          .deepPurple,

                      shape: BoxShape
                          .circle,
                    ),

                    child:
                        const Icon(
                      Icons.edit,
                      color:
                          Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          _field(
            businessController,
            "Business Name",
            Icons.storefront_rounded,
          ),

          _field(
            ownerController,
            "Owner Name",
            Icons.person_outline,
          ),

          _field(
            phoneController,
            "Phone Number",
            Icons.phone_outlined,
            keyboard:
                TextInputType.phone,
          ),

          _field(
            emailController,
            "Email Address",
            Icons.email_outlined,
            keyboard: TextInputType
                .emailAddress,
          ),

          Row(
            children: [
              Expanded(
                child: _field(
                  addressController,
                  "Business Address",
                  Icons
                      .location_on_outlined,
                ),
              ),

              const SizedBox(
                  width: 10),

              Container(
                height: 58,
                width: 58,

                decoration:
                    BoxDecoration(
                  color: Colors
                      .deepPurple,

                  borderRadius:
                      BorderRadius
                          .circular(
                    16,
                  ),
                ),

                child: IconButton(
                  onPressed:
                      fillLocation,

                  icon: const Icon(
                    Icons
                        .my_location,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _field(
                  cityController,
                  "City",
                  Icons
                      .location_city,
                ),
              ),

              const SizedBox(
                  width: 12),

              Expanded(
                child: _field(
                  stateController,
                  "State",
                  Icons
                      .map_outlined,
                ),
              ),
            ],
          ),

          _field(
            pincodeController,
            "Pincode",
            Icons
                .pin_drop_outlined,
            keyboard:
                TextInputType.number,
          ),
        ],
      ),
    );
  }

  /// ================= SERVICE STEP =================
  Widget _serviceStep() {
    return _glassCard(
      title: "Service Details",

      subtitle:
          "Configure your working preferences",

      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade100,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,

              value: ownTools,

              activeColor:
                  Colors.deepPurple,

              title: const Text(
                "I have my own tools & equipment",

                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              subtitle: const Text(
                "Customers will know you're fully equipped",
              ),

              onChanged: (v) {
                setState(() {
                  ownTools = v;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= BANK STEP =================
  Widget _bankStep() {
    return _glassCard(
      title: "Bank Details",

      subtitle:
          "Secure payout information",

      child: Column(
        children: [
          _field(
            bankHolderController,
            "Account Holder Name",
            Icons.person_outline,
          ),

          _field(
            accountController,
            "Account Number",
            Icons
                .account_balance_wallet,
            keyboard:
                TextInputType.number,
          ),

          _field(
            ifscController,
            "IFSC Code",
            Icons.code,
          ),

          _field(
            upiController,
            "UPI ID",
            Icons
                .qr_code_2_outlined,
          ),
        ],
      ),
    );
  }

  /// ================= DOCUMENT STEP =================
  Widget _documentsStep(
      dynamic config) {
    return _glassCard(
      title: "Upload Documents",

      subtitle:
          "Required verification documents",

      child: Column(
        children: config
            .requiredDocuments
            .map<Widget>((doc) {
          final uploaded =
              uploadedDocs
                  .containsKey(doc);

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade50,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              border: Border.all(
                color: uploaded
                    ? Colors.green
                    : Colors.grey
                        .shade300,
              ),
            ),

            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .all(12),

                  decoration:
                      BoxDecoration(
                    color: uploaded
                        ? Colors.green
                            .withOpacity(
                            0.1,
                          )
                        : Colors
                            .deepPurple
                            .withOpacity(
                            0.08,
                          ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),

                  child: Icon(
                    uploaded
                        ? Icons
                            .check_circle
                        : Icons
                            .upload_file,

                    color: uploaded
                        ? Colors.green
                        : Colors
                            .deepPurple,
                  ),
                ),

                const SizedBox(
                    width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        doc,

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                          height:
                              4),

                      Text(
                        uploaded
                            ? "Uploaded Successfully"
                            : "Tap upload button",

                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () =>
                      _uploadDocument(
                    doc,
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        uploaded
                            ? Colors
                                .green
                            : Colors
                                .deepPurple,

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: Text(
                    uploaded
                        ? "Update"
                        : "Upload",
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= GLASS CARD =================
  Widget _glassCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: 2,
            offset:
                const Offset(0, 10),
            color: Colors.black
                .withOpacity(0.05),
          ),
        ],
      ),

      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            Text(
              title,

              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,

              style: TextStyle(
                color: Colors
                    .grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(
                height: 28),

            child,
          ],
        ),
      ),
    );
  }

  /// ================= FIELD =================
  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboard =
        TextInputType.text,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),

      child: TextField(
        controller: c,
        keyboardType: keyboard,

        decoration: InputDecoration(
          hintText: hint,

          prefixIcon: Icon(
            icon,
            color:
                Colors.deepPurple,
          ),

          filled: true,

          fillColor:
              const Color(
            0xFFF7F8FC,
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),

            borderSide:
                BorderSide(
              color: Colors
                  .grey.shade300,
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
              color:
                  Colors.deepPurple,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}