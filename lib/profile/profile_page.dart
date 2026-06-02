import 'dart:io';

import 'package:callme/screens/logo_page.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/login/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String phone;

  const ProfilePage({
    super.key,
    required this.phone,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // =====================================================
  // SERVICES
  // =====================================================

  final AuthService _authService = AuthService();

  // =====================================================
  // FORM
  // =====================================================

  final _formKey = GlobalKey<FormState>();

  // =====================================================
  // CONTROLLERS
  // =====================================================

  final firstNameController = TextEditingController();
  final lastNameController   = TextEditingController();
  final emailController      = TextEditingController();
  final phoneController      = TextEditingController();
  final addressController    = TextEditingController();

  // =====================================================
  // STATE
  // =====================================================

  bool isLoading = true;
  bool _isUploading = false;

  File?   imageFile;
  String  networkImage = "";

  String _collection = "users";
  String _docId      = "";

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // =====================================================
  // LOAD USER DATA
  // =====================================================

  Future<void> loadUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => isLoading = true);

      _collection = "users";
      _docId = (user.email ?? "").trim().toLowerCase();

      if (_docId.isEmpty) {
        showMsg("Email not found");
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(_docId)
          .get();

      phoneController.text = user.phoneNumber ?? "";
      emailController.text = user.email ?? "";

      if (doc.exists) {
        final data = doc.data()!;
        firstNameController.text = data["firstName"]?.toString() ?? "";
        lastNameController.text  = data["lastName"]?.toString()  ?? "";
        addressController.text   = data["address"]?.toString()   ?? "";
        networkImage             = data["photo"]?.toString()     ?? "";

        final storedEmail = data["email"]?.toString() ?? "";
        if (storedEmail.isNotEmpty) emailController.text = storedEmail;

        final storedPhone = data["phone"]?.toString() ?? "";
        if (storedPhone.isNotEmpty) phoneController.text = storedPhone;
      }

      setState(() {});
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // Returns the public download URL, or null on failure.
  // =====================================================

  Future<String?> _uploadImageToStorage(File file) async {
    try {
      final email = (FirebaseAuth.instance.currentUser?.email ?? "")
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$email.jpg');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("STORAGE UPLOAD ERROR: $e");
      return null;
    }
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showMsg("User not found");
        return;
      }

      setState(() => isLoading = true);

      final email = (user.email ?? "").trim().toLowerCase();
      if (email.isEmpty) {
        showMsg("Email not found");
        return;
      }

      // ── Upload new profile photo if one was picked ──
      if (imageFile != null) {
        setState(() => _isUploading = true);
        final uploadedUrl = await _uploadImageToStorage(imageFile!);
        if (uploadedUrl != null) {
          networkImage = uploadedUrl;
          imageFile = null; // clear local file; we now use the network URL
        } else {
          showMsg("Photo upload failed — other details will still be saved");
        }
        if (mounted) setState(() => _isUploading = false);
      }

      // ── Update Firebase Auth display name ──
      final fullName =
          "${firstNameController.text.trim()} ${lastNameController.text.trim()}"
              .trim();
      await user.updateDisplayName(fullName);

      // ── Write all fields to Firestore ──
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(email);

      // Preserve createdAt — only set it if the doc doesn't exist yet
      final existing = await docRef.get();
      final Map<String, dynamic> payload = {
        "userId":      email,
        "firebaseUid": user.uid,
        "firstName":   firstNameController.text.trim(),
        "lastName":    lastNameController.text.trim(),
        "name":        fullName,
        "email":       emailController.text.trim(),
        "phone":       phoneController.text.trim(),
        "address":     addressController.text.trim(),
        "photo":       networkImage,
        "updatedAt":   FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        payload["createdAt"] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));

      if (mounted) setState(() {}); // refresh name in header card

      showMsg("Profile Updated Successfully");
    } catch (e) {
      debugPrint("SAVE ERROR: $e");
      showMsg("Failed to save profile: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // PICK IMAGE
  // =====================================================

  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() => imageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint("IMAGE PICK ERROR: $e");
    }
  }

  // =====================================================
  // OPEN MAP
  // =====================================================

  Future<void> openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );
    if (result != null && result is String && mounted) {
      setState(() => addressController.text = result);
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("LOGOUT ERROR: $e");
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg),
      ),
    );
  }

  // =====================================================
  // AVATAR IMAGE PROVIDER
  // =====================================================

  ImageProvider buildImage() {
    if (imageFile != null)       return FileImage(imageFile!);
    if (networkImage.isNotEmpty) return NetworkImage(networkImage);
    return const AssetImage("assets/user.jfif");
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final double width    = MediaQuery.of(context).size.width;
    final bool   isTablet = width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 16,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // ── PROFILE HEADER CARD ──────────

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B67F1), Color(0xFF7D89FF)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.2),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [

                              // Avatar + edit button
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: isTablet ? 62 : 55,
                                      backgroundImage: buildImage(),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: isLoading ? null : pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: _isUploading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.indigo,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.indigo,
                                              ),
                                      ),
                                    ),
                                  ),

                                  // "New photo" indicator badge
                                  if (imageFile != null)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "New",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Text(
                                "${firstNameController.text} ${lastNameController.text}".trim().isEmpty
                                    ? "Your Name"
                                    : "${firstNameController.text} ${lastNameController.text}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                phoneController.text.isNotEmpty
                                    ? phoneController.text
                                    : emailController.text,
                                style: const TextStyle(color: Colors.white70),
                              ),

                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _collection == "admins"
                                      ? "Admin Account"
                                      : "User Account",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── PERSONAL INFO SECTION ────────

                        _section(
                          title: "Personal Information",
                          child: Column(
                            children: [

                              isTablet
                                  ? Row(
                                      children: [
                                        Expanded(child: _field(firstNameController, "First Name", Icons.person)),
                                        const SizedBox(width: 16),
                                        Expanded(child: _field(lastNameController, "Last Name", Icons.person_outline)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _field(firstNameController, "First Name", Icons.person),
                                        _field(lastNameController, "Last Name", Icons.person_outline),
                                      ],
                                    ),

                              _field(
                                emailController,
                                "Email",
                                Icons.email,
                                readOnly: true,
                              ),

                              _field(
                                phoneController,
                                "Phone Number",
                                Icons.phone,
                                keyboard: TextInputType.phone,
                              ),

                              _field(
                                addressController,
                                "Address",
                                Icons.location_on,
                                maxLines: 3,
                                required: false,
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: openMap,
                                  icon: const Icon(Icons.map),
                                  label: const Text("Pick From Map"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── SAVE BUTTON ──────────────────

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : saveProfile,
                            icon: const Icon(Icons.save),
                            label: const Text(
                              "Save Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── LOGOUT BUTTON ────────────────

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: logout,
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              "Logout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── LOADING OVERLAY ──────────────────────────

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION CARD
  // =====================================================

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  // =====================================================
  // FORM FIELD
  // =====================================================

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int  maxLines = 1,
    bool required = true,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        readOnly: readOnly,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return "Required";
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.indigo),
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
              : null,
          filled: true,
          fillColor: readOnly
              ? const Color(0xFFEEEFF5)
              : const Color(0xFFF7F8FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.indigo, width: 1.3),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
        ),
      ),
    );
  }
}