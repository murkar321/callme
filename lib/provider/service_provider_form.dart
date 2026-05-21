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

  bool ownTools = false;

  File? businessImage;

  final PageController _pageController =
      PageController();

  final List<String> selectedCategories = [];

  final Map<String, String> uploadedDocs =
      {};

  /// ================= CONTROLLERS =================

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

  @override
  void dispose() {
    _pageController.dispose();

    businessController.dispose();
    ownerController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    bankHolderController.dispose();
    accountController.dispose();
    ifscController.dispose();
    upiController.dispose();

    super.dispose();
  }

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
              LocationPermission.denied ||
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
            place.administrativeArea ?? "";

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

  /// ================= DOCUMENT UPLOAD =================

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

  /// ================= PROVIDER ID =================

  String generateProviderId() {
    final now = DateTime.now();

    final type =
        widget.type.substring(0, 3)
            .toUpperCase();

    final random =
        now.millisecondsSinceEpoch
            .toString()
            .substring(7);

    return "$type-$random";
  }

  /// ================= AGREEMENT POPUP =================

  Future<void> _showAgreementDialog() async {
    bool accepted = false;

    final result = await showModalBottomSheet<
        bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setStateDialog) {
            return SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.88,
                minChildSize: 0.75,
                maxChildSize: 0.95,
                expand: false,
                builder: (
                  context,
                  scrollController,
                ) {
                  return Container(
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(
                        top: Radius.circular(
                          32,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                            height: 12),

                        Container(
                          width: 60,
                          height: 6,
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .grey.shade300,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              100,
                            ),
                          ),
                        ),

                        Expanded(
                          child:
                              SingleChildScrollView(
                            controller:
                                scrollController,
                            padding:
                                EdgeInsets.only(
                              left: 22,
                              right: 22,
                              top: 24,
                              bottom:
                                  MediaQuery.of(
                                        context,
                                      )
                                          .viewInsets
                                          .bottom +
                                      24,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .all(18),
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .deepPurple
                                        .withOpacity(
                                      0.08,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      24,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          14,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .deepPurple,
                                          borderRadius:
                                              BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .verified_user_rounded,
                                          color: Colors
                                              .white,
                                          size: 32,
                                        ),
                                      ),

                                      const SizedBox(
                                          width: 16),

                                      const Expanded(
                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              "Provider Agreement",
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    24,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                                height:
                                                    6),
                                            Text(
                                              "Please review before submission",
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                    height: 28),

                                _agreementTile(
                                  Icons
                                      .verified_outlined,
                                  "All submitted information and documents are authentic and valid.",
                                ),

                                _agreementTile(
                                  Icons
                                      .gpp_bad_outlined,
                                  "Fraudulent activity or fake documents may permanently suspend the account.",
                                ),

                                _agreementTile(
                                  Icons
                                      .support_agent,
                                  "Professional and respectful service behavior must be maintained.",
                                ),

                                _agreementTile(
                                  Icons
                                      .fact_check_outlined,
                                  "Your profile will be manually reviewed before approval.",
                                ),

                                const SizedBox(
                                    height: 24),

                                Container(
                                  padding:
                                      const EdgeInsets
                                          .all(18),
                                  decoration:
                                      BoxDecoration(
                                    color: accepted
                                        ? Colors.green
                                            .withOpacity(
                                            0.08,
                                          )
                                        : Colors
                                            .grey
                                            .shade100,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      22,
                                    ),
                                    border: Border.all(
                                      color: accepted
                                          ? Colors
                                              .green
                                          : Colors
                                              .grey
                                              .shade300,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Checkbox(
                                        value:
                                            accepted,
                                        activeColor:
                                            Colors
                                                .deepPurple,
                                        onChanged:
                                            (v) {
                                          setStateDialog(
                                            () {
                                              accepted =
                                                  v ??
                                                      false;
                                            },
                                          );
                                        },
                                      ),

                                      const Expanded(
                                        child:
                                            Padding(
                                          padding:
                                              EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child:
                                              Text(
                                            "I confirm that all details provided are genuine and I agree to the provider terms.",
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  15,
                                              fontWeight:
                                                  FontWeight.w600,
                                              height:
                                                  1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                    height: 32),

                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          OutlinedButton(
                                        onPressed:
                                            () {
                                          Navigator.pop(
                                            context,
                                            false,
                                          );
                                        },
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
                                          "Cancel",
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                        width: 14),

                                    Expanded(
                                      flex: 2,
                                      child:
                                          ElevatedButton(
                                        onPressed:
                                            accepted
                                                ? () {
                                                    Navigator.pop(
                                                      context,
                                                      true,
                                                    );
                                                  }
                                                : null,
                                        style:
                                            ElevatedButton.styleFrom(
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
                                            const Text(
                                          "Accept & Submit",
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
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      _submitForm();
    }
  }

  Widget _agreementTile(
    IconData icon,
    String text,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8F8FC),
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple
                  .withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

      if (selectedCategories
          .isEmpty) {
        throw "Select at least one category";
      }

      final providerId =
          generateProviderId();

      String imageUrl = "";

      if (businessImage != null) {
        final ref =
            FirebaseStorage.instance
                .ref()
                .child(
                  "provider_images/$providerId.jpg",
                );

        await ref.putFile(
            businessImage!);

        imageUrl =
            await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection("providers")
          .doc(providerId)
          .set({
        "providerId": providerId,
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
              businessController.text
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

        "agreementAccepted":
            true,

        "agreementAcceptedAt":
            FieldValue
                .serverTimestamp(),

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
                businessController.text
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

  /// ================= NAVIGATION =================

  void nextStep() async {
    if (currentStep < 4) {
      setState(() {
        currentStep++;
      });

      _pageController.animateToPage(
        currentStep,
        duration: const Duration(
          milliseconds: 350,
        ),
        curve: Curves.easeInOut,
      );
    } else {
      await _showAgreementDialog();
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
          milliseconds: 350,
        ),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    final config =
        serviceConfigs[widget.type]!;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        centerTitle: true,
        title: Text(
          "${widget.type} Registration",
        ),
      ),

      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Column(
                children: [
                  /// ================= PROGRESS =================

                  Row(
                    children: List.generate(
                      5,
                      (index) {
                        final active =
                            index <=
                                currentStep;

                        return Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(
                              right:
                                  index == 4
                                      ? 0
                                      : 8,
                            ),
                            height: 10,
                            decoration:
                                BoxDecoration(
                              color: active
                                  ? Colors
                                      .deepPurple
                                  : Colors
                                      .grey
                                      .shade300,
                              borderRadius:
                                  BorderRadius.circular(
                                100,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  Expanded(
                    child: PageView(
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
                      height: 16),

                  Row(
                    children: [
                      if (currentStep > 0)
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

                      if (currentStep > 0)
                        const SizedBox(
                            width: 12),

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
                          child: Text(
                            currentStep == 4
                                ? "Submit Registration"
                                : "Continue",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child:
                    CircularProgressIndicator(),
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
          "Choose services you provide",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: config
            .serviceCategories
            .map<Widget>((cat) {
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
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? Colors.deepPurple
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: selected
                      ? Colors.deepPurple
                      : Colors.grey
                          .shade300,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black87,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= BUSINESS STEP =================

  Widget _businessStep() {
    return _glassCard(
      title: "Business Information",
      subtitle:
          "Enter business details",
      child: Column(
        children: [
          GestureDetector(
            onTap:
                pickBusinessImage,
            child: CircleAvatar(
              radius: 56,
              backgroundColor:
                  Colors.deepPurple
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
                      Icons.camera_alt,
                      size: 34,
                      color:
                          Colors.deepPurple,
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          _field(
            businessController,
            "Business Name",
            Icons.store,
          ),

          _field(
            ownerController,
            "Owner Name",
            Icons.person,
          ),

          _field(
            phoneController,
            "Phone Number",
            Icons.phone,
          ),

          _field(
            emailController,
            "Email Address",
            Icons.email,
          ),

          Row(
            children: [
              Expanded(
                child: _field(
                  addressController,
                  "Business Address",
                  Icons.location_on,
                ),
              ),

              const SizedBox(
                  width: 10),

              Container(
                height: 58,
                width: 58,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.deepPurple,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: IconButton(
                  onPressed:
                      fillLocation,
                  icon: const Icon(
                    Icons.my_location,
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
                  Icons.location_city,
                ),
              ),

              const SizedBox(
                  width: 12),

              Expanded(
                child: _field(
                  stateController,
                  "State",
                  Icons.map,
                ),
              ),
            ],
          ),

          _field(
            pincodeController,
            "Pincode",
            Icons.pin_drop,
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
          "Configure preferences",
      child: Container(
        padding:
            const EdgeInsets.all(
          8,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF8F8FC),
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
        child: SwitchListTile(
          value: ownTools,
          activeColor:
              Colors.deepPurple,
          title: const Text(
            "I have my own tools & equipment",
          ),
          onChanged: (v) {
            setState(() {
              ownTools = v;
            });
          },
        ),
      ),
    );
  }

  /// ================= BANK STEP =================

  Widget _bankStep() {
    return _glassCard(
      title: "Bank Details",
      subtitle:
          "Secure payout details",
      child: Column(
        children: [
          _field(
            bankHolderController,
            "Account Holder",
            Icons.person,
          ),

          _field(
            accountController,
            "Account Number",
            Icons.account_balance,
          ),

          _field(
            ifscController,
            "IFSC Code",
            Icons.code,
          ),

          _field(
            upiController,
            "UPI ID",
            Icons.qr_code,
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
          "Verification documents",
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
                Expanded(
                  child: Text(
                    doc,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
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
                  ),
                  child: Text(
                    uploaded
                        ? "Uploaded"
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
          const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 2,
            offset:
                const Offset(0, 10),
            color: Colors.black
                .withOpacity(0.04),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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

            const SizedBox(
                height: 6),

            Text(
              subtitle,
              style: TextStyle(
                color: Colors
                    .grey.shade600,
              ),
            ),

            const SizedBox(
                height: 24),

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
    IconData icon,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: TextField(
        controller: c,
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
            horizontal: 18,
            vertical: 18,
          ),

          border:
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
            ),
          ),
        ),
      ),
    );
  }
}