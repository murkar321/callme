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
  final lastNameController  = TextEditingController();
  final emailController     = TextEditingController();
  final phoneController     = TextEditingController();
  final addressController   = TextEditingController();

  // =====================================================
  // STATE
  // =====================================================

  bool   isLoading    = true;
  bool   _isUploading = false;
  double _uploadProgress = 0;

  File?  imageFile;
  String networkImage = "";

  String _collection = "users";

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

      if (mounted) setState(() => isLoading = true);

      final docId = (user.email ?? "").trim().toLowerCase();

      if (docId.isEmpty) {
        showMsg("No email found on this account");
        return;
      }

      // Prefill from Auth
      emailController.text = user.email ?? "";
      phoneController.text = user.phoneNumber ?? "";

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        firstNameController.text =
            data["firstName"]?.toString() ?? "";
        lastNameController.text =
            data["lastName"]?.toString() ?? "";
        addressController.text =
            data["address"]?.toString() ?? "";

        final storedEmail = data["email"]?.toString() ?? "";
        if (storedEmail.isNotEmpty) emailController.text = storedEmail;

        final storedPhone = data["phone"]?.toString() ?? "";
        if (storedPhone.isNotEmpty) phoneController.text = storedPhone;

        final storedPhoto = data["photo"]?.toString() ?? "";
        if (storedPhoto.isNotEmpty) {
          networkImage = storedPhoto;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("LOAD ERROR: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // UPLOAD IMAGE — FIXED
  // Uses UploadTask directly so we get a real
  // TaskSnapshot with a working getDownloadURL().
  // =====================================================

  Future<String?> _uploadProfilePhoto(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Build a safe storage path using uid (always available,
      // never contains special chars — avoids email encoding issues)
      final storagePath =
          'profile_images/${user.uid}/profile.jpg';

      final ref = FirebaseStorage.instance.ref(storagePath);

      // Create the upload task
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uid':   user.uid,
            'email': user.email ?? '',
          },
        ),
      );

      // Listen to progress so the UI spinner is accurate
      uploadTask.snapshotEvents.listen((TaskSnapshot snap) {
        if (!mounted) return;
        final progress =
            snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes);
        setState(() => _uploadProgress = progress);
      });

      // Await the task directly — this is the KEY fix.
      // Do NOT use .whenComplete() — it returns void.
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state != TaskState.success) {
        debugPrint("Upload state: ${snapshot.state}");
        return null;
      }

      // Get the permanent download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("Upload success. URL: $downloadUrl");
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint("FIREBASE STORAGE ERROR [${e.code}]: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");
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
        showMsg("User not found. Please login again.");
        return;
      }

      if (mounted) setState(() => isLoading = true);

      final String email = (user.email ?? "").trim().toLowerCase();
      if (email.isEmpty) {
        showMsg("No email found on this account");
        return;
      }

      // ── Step 1: Upload photo if a new one was picked ──
      if (imageFile != null) {
        if (mounted) {
          setState(() {
            _isUploading    = true;
            _uploadProgress = 0;
          });
        }

        final String? uploadedUrl =
            await _uploadProfilePhoto(imageFile!);

        if (mounted) setState(() => _isUploading = false);

        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          networkImage = uploadedUrl;
          imageFile    = null; // switch to network image
          debugPrint("Photo saved to Firestore as: $networkImage");
        } else {
          showMsg(
            "Photo upload failed. Check Firebase Storage rules.\n"
            "Other profile details will still be saved.",
          );
          // Don't return — still save the rest of the profile
        }
      }

      // ── Step 2: Update Firebase Auth display name ──
      final String fullName =
          "${firstNameController.text.trim()} "
          "${lastNameController.text.trim()}".trim();

      await user.updateDisplayName(fullName);

      // Also update photoURL in Auth so it's consistent
      if (networkImage.isNotEmpty) {
        await user.updatePhotoURL(networkImage);
      }

      // ── Step 3: Build Firestore payload ──
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(email);

      final existingDoc = await docRef.get();

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

      // Only set createdAt on first write
      if (!existingDoc.exists) {
        payload["createdAt"] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));

      debugPrint("Firestore saved. photo field = $networkImage");

      if (mounted) setState(() {}); // rebuild header card

      showMsg("Profile updated successfully ✓");
    } catch (e) {
      debugPrint("SAVE PROFILE ERROR: $e");
      showMsg("Save failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading       = false;
          _isUploading    = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  // =====================================================
  // PICK IMAGE
  // =====================================================

  Future<void> pickImage() async {
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source:       ImageSource.gallery,
        imageQuality: 75,
        maxWidth:     800,
        maxHeight:    800,
      );
      if (picked != null && mounted) {
        setState(() => imageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint("IMAGE PICK ERROR: $e");
      showMsg("Could not open gallery");
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
  // SNACKBAR
  // =====================================================

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:      SnackBarBehavior.floating,
        duration:      const Duration(seconds: 3),
        content: Text(msg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // =====================================================
  // AVATAR IMAGE PROVIDER
  // =====================================================

  ImageProvider _buildImageProvider() {
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
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool   isTablet    = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),

      appBar: AppBar(
        elevation:       0,
        backgroundColor: Colors.transparent,
        centerTitle:     true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color:      Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [

          // ── SCROLLABLE CONTENT ────────────────────

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 28 : 16,
                vertical:   16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // ── HEADER CARD ──────────────

                        _buildHeaderCard(isTablet),

                        const SizedBox(height: 24),

                        // ── PERSONAL INFO ────────────

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
                                        _field(lastNameController,  "Last Name",  Icons.person_outline),
                                      ],
                                    ),

                              _field(emailController, "Email",        Icons.email,       readOnly: true),
                              _field(phoneController, "Phone Number", Icons.phone,       keyboard: TextInputType.phone),
                              _field(addressController, "Address",    Icons.location_on, maxLines: 3, required: false),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: openMap,
                                  icon:  const Icon(Icons.map),
                                  label: const Text("Pick From Map"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── SAVE BUTTON ──────────────

                        SizedBox(
                          width:  double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: (isLoading || _isUploading)
                                ? null
                                : saveProfile,
                            icon:  const Icon(Icons.save),
                            label: const Text(
                              "Save Profile",
                              style: TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation:       0,
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── LOGOUT BUTTON ────────────

                        SizedBox(
                          width:  double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: logout,
                            icon:  const Icon(Icons.logout),
                            label: const Text(
                              "Logout",
                              style: TextStyle(
                                fontSize:   16,
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

          // ── LOADING OVERLAY ───────────────────────

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Uploading photo… "
                        "${(_uploadProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value:           _uploadProgress,
                            backgroundColor: Colors.white30,
                            color:           Colors.white,
                            minHeight:       6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // HEADER CARD
  // =====================================================

  Widget _buildHeaderCard(bool isTablet) {
    final double avatarRadius = isTablet ? 62 : 52;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B67F1), Color(0xFF7D89FF)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:      Colors.indigo.withOpacity(0.2),
            blurRadius: 18,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [

          // ── AVATAR ────────────────────────────────

          Stack(
            clipBehavior: Clip.none,
            children: [

              // White ring + avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius:          avatarRadius,
                  backgroundImage: _buildImageProvider(),
                  backgroundColor: const Color(0xFFEEF2FF),
                ),
              ),

              // Edit / upload spinner button
              Positioned(
                bottom: 0,
                right:  0,
                child: GestureDetector(
                  onTap: (isLoading || _isUploading) ? null : pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading
                        ? SizedBox(
                            width:  18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _uploadProgress > 0
                                  ? _uploadProgress
                                  : null,
                              color: Colors.indigo,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size:  18,
                            color: Colors.indigo,
                          ),
                  ),
                ),
              ),

              // "New" badge — visible after picking but before saving
              if (imageFile != null)
                Positioned(
                  top:  0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color:        Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "New",
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // ── NAME ──────────────────────────────────

          Text(
            () {
              final n =
                  "${firstNameController.text} ${lastNameController.text}"
                      .trim();
              return n.isEmpty ? "Your Name" : n;
            }(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // ── PHONE OR EMAIL ────────────────────────

          Text(
            phoneController.text.isNotEmpty
                ? phoneController.text
                : emailController.text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 10),

          // ── ACCOUNT TYPE BADGE ────────────────────

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _collection == "admins" ? "Admin Account" : "User Account",
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      width:   double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
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
        controller:  c,
        keyboardType: keyboard,
        maxLines:    maxLines,
        readOnly:    readOnly,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return "This field is required";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText:   hint,
          prefixIcon: Icon(icon, color: Colors.indigo),
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline,
                  size: 16, color: Colors.grey)
              : null,
          filled:    true,
          fillColor: readOnly
              ? const Color(0xFFEEEFF5)
              : const Color(0xFFF7F8FC),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:  BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:  const BorderSide(color: Colors.indigo, width: 1.3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:  const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:  const BorderSide(color: Colors.red, width: 1.3),
          ),
        ),
      ),
    );
  }
}