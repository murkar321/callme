import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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

  /// =========================================================
  /// FIREBASE
  /// =========================================================

  final firestore =
      FirebaseFirestore.instance;

  final storage =
      FirebaseStorage.instance;

  /// =========================================================
  /// FORM
  /// =========================================================

  final formKey =
      GlobalKey<FormState>();

  /// =========================================================
  /// STATE
  /// =========================================================

  bool isLoading = true;

  bool isSaving = false;

  bool ownTools = false;

  bool isActive = true;

  String providerStatus = "pending";

  String providerType = "";

  String serviceType = "";

  String imageUrl = "";

  File? profileImage;

  List<String> selectedCategories = [];

  List<String> allCategories = [];

  Map<String, dynamic> documents = {};

  Timestamp? createdAt;

  /// =========================================================
  /// CONTROLLERS
  /// =========================================================

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

  /// =========================================================
  /// INIT
  /// =========================================================

  @override
  void initState() {
    super.initState();
    loadProvider();
  }

  @override
  void dispose() {

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

  /// =========================================================
  /// LOAD
  /// =========================================================

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
          data["business"] ?? {};

      final service =
          data["service"] ?? {};

      final bank =
          data["bank"] ?? {};

      businessController.text =
          business["businessName"] ?? "";

      ownerController.text =
          business["ownerName"] ?? "";

      phoneController.text =
          business["phone"] ?? "";

      emailController.text =
          business["email"] ?? "";

      addressController.text =
          business["address"] ?? "";

      cityController.text =
          business["city"] ?? "";

      stateController.text =
          business["state"] ?? "";

      pincodeController.text =
          business["pincode"] ?? "";

      imageUrl =
          business["image"] ?? "";

      ownTools =
          service["ownTools"] ?? false;

      bankHolderController.text =
          bank["accountHolder"] ?? "";

      accountController.text =
          bank["accountNumber"] ?? "";

      ifscController.text =
          bank["ifsc"] ?? "";

      upiController.text =
          bank["upi"] ?? "";

      providerType =
          data["providerType"] ?? "";

      serviceType =
          data["serviceType"] ?? "";

      providerStatus =
          data["status"] ?? "pending";

      isActive =
          data["isActive"] ?? true;

      createdAt =
          data["createdAt"];

      selectedCategories =
          List<String>.from(
        data["categories"] ?? [],
      );

      documents =
          Map<String, dynamic>.from(
        data["documents"] ?? {},
      );

      if (serviceConfigs.containsKey(
          serviceType)) {

        allCategories =
            List<String>.from(
          serviceConfigs[serviceType]!
              .serviceCategories,
        );
      }

    } catch (e) {

      showMsg(
        "Failed to load profile",
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// =========================================================
  /// IMAGE PICK
  /// =========================================================

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

  /// =========================================================
  /// IMAGE PROVIDER
  /// =========================================================

  ImageProvider? buildImageProvider() {

    if (profileImage != null) {
      return FileImage(profileImage!);
    }

    if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    }

    return null;
  }

  /// =========================================================
  /// DOCUMENT UPLOAD
  /// =========================================================

  Future<void> uploadDocument(
      String docName) async {

    try {

      final result =
          await FilePicker.platform
              .pickFiles();

      if (result == null) return;

      final file = File(
        result.files.single.path!,
      );

      final cleanName =
      docName.replaceAll(
        " ",
        "_",
      );

      final ref = storage
          .ref()
          .child(
        "provider_docs/${widget.providerId}/$cleanName",
      );

      await ref.putFile(file);

      final url =
          await ref.getDownloadURL();

      setState(() {
        documents[docName] = url;
      });

      await firestore
          .collection("providers")
          .doc(widget.providerId)
          .update({
        "documents.$docName":
        url,
      });

      showMsg(
        "$docName uploaded",
      );

    } catch (e) {

      showMsg(
        "Upload failed",
      );
    }
  }

  /// =========================================================
  /// DELETE DOC
  /// =========================================================

  Future<void> deleteDocument(
      String docName) async {

    try {

      setState(() {
        documents.remove(docName);
      });

      await firestore
          .collection("providers")
          .doc(widget.providerId)
          .update({
        "documents.$docName":
        FieldValue.delete(),
      });

      showMsg(
        "Document removed",
      );

    } catch (e) {

      showMsg(
        "Delete failed",
      );
    }
  }

  /// =========================================================
  /// SAVE
  /// =========================================================

  Future<void> saveProfile() async {

    if (!formKey.currentState!
        .validate()) {
      return;
    }

    try {

      setState(() {
        isSaving = true;
      });

      String updatedImage =
          imageUrl;

      if (profileImage != null) {

        final ref = storage
            .ref()
            .child(
          "provider_images/${widget.providerId}/${DateTime.now().millisecondsSinceEpoch}.jpg",
        );

        await ref.putFile(
          profileImage!,
        );

        updatedImage =
            await ref.getDownloadURL();
      }

      await firestore
          .collection("providers")
          .doc(widget.providerId)
          .update({

        "updatedAt":
        FieldValue.serverTimestamp(),

        "providerName":
        businessController.text.trim(),

        "ownerName":
        ownerController.text.trim(),

        "phone":
        phoneController.text.trim(),

        "categories":
        selectedCategories,

        "isActive":
        isActive,

        "business.businessName":
        businessController.text.trim(),

        "business.ownerName":
        ownerController.text.trim(),

        "business.phone":
        phoneController.text.trim(),

        "business.email":
        emailController.text.trim(),

        "business.address":
        addressController.text.trim(),

        "business.city":
        cityController.text.trim(),

        "business.state":
        stateController.text.trim(),

        "business.pincode":
        pincodeController.text.trim(),

        "business.image":
        updatedImage,

        "service.ownTools":
        ownTools,

        "bank.accountHolder":
        bankHolderController.text.trim(),

        "bank.accountNumber":
        accountController.text.trim(),

        "bank.ifsc":
        ifscController.text.trim(),

        "bank.upi":
        upiController.text.trim(),
      });

      imageUrl =
          updatedImage;

      showMsg(
        "Profile updated successfully",
      );

    } catch (e) {

      showMsg(
        "Profile update failed",
      );

    } finally {

      setState(() {
        isSaving = false;
      });
    }
  }

  /// =========================================================
  /// DELETE PROFILE
  /// =========================================================

  Future<void> deleteProfile() async {

    final confirm =
        await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          title:
          const Text(
            "Delete Profile?",
          ),

          content:
          const Text(
            "This action cannot be undone.",
          ),

          actions: [

            TextButton(

              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
              const Text("Cancel"),
            ),

            ElevatedButton(

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
              const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {

      setState(() {
        isSaving = true;
      });

      await firestore
          .collection("providers")
          .doc(widget.providerId)
          .delete();

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      showMsg(
        "Delete failed",
      );

    } finally {

      setState(() {
        isSaving = false;
      });
    }
  }

  /// =========================================================
  /// PROFILE %
  /// =========================================================

  int profileCompletion() {

    int score = 0;

    if (imageUrl.isNotEmpty ||
        profileImage != null) {
      score += 15;
    }

    if (businessController
        .text
        .isNotEmpty) {
      score += 15;
    }

    if (selectedCategories
        .isNotEmpty) {
      score += 15;
    }

    if (documents.isNotEmpty) {
      score += 20;
    }

    if (bankHolderController
        .text
        .isNotEmpty) {
      score += 15;
    }

    if (upiController
        .text
        .isNotEmpty) {
      score += 20;
    }

    return score;
  }

  /// =========================================================
  /// SNACKBAR
  /// =========================================================

  void showMsg(String msg) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  /// =========================================================
  /// UI
  /// =========================================================

  @override
  Widget build(BuildContext context) {

    final size =
        MediaQuery.of(context).size;

    final isTablet =
        size.width > 700;

    return Scaffold(

      backgroundColor:
      const Color(0xFFF4F6FB),

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : SafeArea(

        child: Form(

          key: formKey,

          child: Stack(

            children: [

              SingleChildScrollView(

                padding:
                EdgeInsets.only(
                  left:
                  isTablet
                      ? 30
                      : 16,
                  right:
                  isTablet
                      ? 30
                      : 16,
                  top: 16,
                  bottom: 120,
                ),

                child: Center(

                  child: ConstrainedBox(

                    constraints:
                    const BoxConstraints(
                      maxWidth: 950,
                    ),

                    child: Column(

                      children: [

                        /// HEADER

                        buildHeader(
                          isTablet,
                        ),

                        const SizedBox(
                            height: 22),

                        /// BUSINESS

                        buildSection(

                          title:
                          "Business Information",

                          icon:
                          Icons.storefront,

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
                                "Phone Number",
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

                          title:
                          "Services",

                          icon:
                          Icons.miscellaneous_services,

                          child: Column(

                            children: [

                              SwitchListTile(

                                value:
                                ownTools,

                                activeColor:
                                Colors.deepPurple,

                                title:
                                const Text(
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
                                      (cat) {

                                    final selected =
                                    selectedCategories
                                        .contains(cat);

                                    return FilterChip(

                                      label:
                                      Text(cat),

                                      selected:
                                      selected,

                                      selectedColor:
                                      Colors.deepPurple
                                          .withOpacity(0.15),

                                      checkmarkColor:
                                      Colors.deepPurple,

                                      onSelected:
                                          (v) {

                                        setState(() {

                                          if (v) {

                                            selectedCategories.add(cat);

                                          } else {

                                            selectedCategories.remove(cat);
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

                        /// DOCUMENTS

                        buildSection(

                          title:
                          "Documents",

                          icon:
                          Icons.description,

                          child: Column(

                            children:
                            documents.keys.map(
                                  (doc) {

                                return Container(

                                  margin:
                                  const EdgeInsets.only(
                                    bottom: 14,
                                  ),

                                  padding:
                                  const EdgeInsets.all(16),

                                  decoration:
                                  BoxDecoration(

                                    color:
                                    Colors.grey.shade50,

                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),

                                  child: Row(

                                    children: [

                                      const Icon(
                                        Icons.file_present,
                                        color:
                                        Colors.deepPurple,
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(

                                        child: Text(
                                          doc,
                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      IconButton(

                                        onPressed: () =>
                                            uploadDocument(doc),

                                        icon:
                                        const Icon(
                                          Icons.edit,
                                        ),
                                      ),

                                      IconButton(

                                        onPressed: () =>
                                            deleteDocument(doc),

                                        icon:
                                        const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),

                        const SizedBox(height: 22),

                        /// BANK

                        buildSection(

                          title:
                          "Bank Details",

                          icon:
                          Icons.account_balance,

                          child: Column(

                            children: [

                              buildField(
                                bankHolderController,
                                "Account Holder",
                                Icons.person_outline,
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

                        const SizedBox(height: 22),

                        /// DANGER

                        buildSection(

                          title:
                          "Danger Zone",

                          icon:
                          Icons.warning_amber_rounded,

                          child: Column(

                            children: [

                              ListTile(

                                contentPadding:
                                EdgeInsets.zero,

                                leading:
                                const CircleAvatar(

                                  backgroundColor:
                                  Color(0xFFFFE7E7),

                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),

                                title:
                                const Text(
                                  "Delete Provider Profile",
                                ),

                                subtitle:
                                const Text(
                                  "This action cannot be undone",
                                ),

                                trailing:
                                ElevatedButton(

                                  onPressed:
                                  deleteProfile,

                                  style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Colors.red,
                                  ),

                                  child:
                                  const Text(
                                    "Delete",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// SAVE BUTTON

              Positioned(

                left: 16,

                right: 16,

                bottom: 16,

                child: SafeArea(

                  child: Container(

                    padding:
                    const EdgeInsets.all(14),

                    decoration:
                    BoxDecoration(

                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius.circular(24),

                      boxShadow: [

                        BoxShadow(

                          color:
                          Colors.black.withOpacity(0.08),

                          blurRadius: 16,
                        ),
                      ],
                    ),

                    child: ElevatedButton(

                      onPressed:
                      isSaving
                          ? null
                          : saveProfile,

                      style:
                      ElevatedButton.styleFrom(

                        backgroundColor:
                        Colors.deepPurple,

                        foregroundColor:
                        Colors.white,

                        minimumSize:
                        const Size(
                          double.infinity,
                          58,
                        ),

                        shape:
                        RoundedRectangleBorder(

                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),

                      child:
                      isSaving

                          ? const SizedBox(

                        height: 22,

                        width: 22,

                        child:
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )

                          : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// HEADER
  /// =========================================================

  Widget buildHeader(bool isTablet) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(24),

      decoration:
      BoxDecoration(

        gradient:
        const LinearGradient(

          colors: [
            Color(0xFF6D5DF6),
            Color(0xFF8E7BFF),
          ],
        ),

        borderRadius:
        BorderRadius.circular(32),
      ),

      child: Column(

        children: [

          GestureDetector(

            onTap: pickImage,

            child: Stack(

              children: [

                CircleAvatar(

                  radius:
                  isTablet
                      ? 62
                      : 52,

                  backgroundColor:
                  Colors.white,

                  backgroundImage:
                  buildImageProvider(),

                  child:
                  buildImageProvider() == null

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

                    child:
                    const Icon(
                      Icons.camera_alt,
                      color:
                      Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(

            businessController.text
                .isEmpty
                ? "Business Name"
                : businessController.text,

            style:
            TextStyle(

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

          Text(

            widget.providerId,

            style:
            const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 20),

          Row(

            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              buildBadge(
                providerStatus.toUpperCase(),
              ),

              const SizedBox(width: 10),

              buildBadge(
                providerType,
              ),

              const SizedBox(width: 10),

              buildBadge(
                serviceType,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(

            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              const Text(
                "Active",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              Switch(

                value:
                isActive,

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

          const SizedBox(height: 10),

          Text(

            "Profile Completion ${profileCompletion()}%",

            style:
            const TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================================================
  /// BADGE
  /// =========================================================

  Widget buildBadge(String text) {

    return Container(

      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration:
      BoxDecoration(

        color:
        Colors.white.withOpacity(0.16),

        borderRadius:
        BorderRadius.circular(30),
      ),

      child: Text(

        text,

        style:
        const TextStyle(
          color: Colors.white,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  /// =========================================================
  /// SECTION
  /// =========================================================

  Widget buildSection({

    required String title,

    required IconData icon,

    required Widget child,
  }) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(22),

      decoration:
      BoxDecoration(

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

          Row(

            children: [

              CircleAvatar(

                backgroundColor:
                Colors.deepPurple
                    .withOpacity(0.1),

                child: Icon(
                  icon,
                  color:
                  Colors.deepPurple,
                ),
              ),

              const SizedBox(width: 14),

              Text(

                title,

                style:
                const TextStyle(

                  fontSize: 20,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          child,
        ],
      ),
    );
  }

  /// =========================================================
  /// FIELD
  /// =========================================================

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

      child: TextFormField(

        controller:
        controller,

        keyboardType:
        keyboard,

        validator: (v) {

          if (v == null ||
              v.trim().isEmpty) {

            return "Required";
          }

          return null;
        },

        decoration:
        InputDecoration(

          hintText:
          hint,

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
            horizontal: 18,
            vertical: 18,
          ),

          border:
          OutlineInputBorder(

            borderRadius:
            BorderRadius.circular(18),

            borderSide:
            BorderSide.none,
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
              color:
              Colors.deepPurple,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}