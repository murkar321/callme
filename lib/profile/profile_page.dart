import 'dart:io';

import 'package:callme/screens/logo_page.dart';
import 'package:callme/screens/map_picker_page.dart';
import 'package:callme/login/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();

  final _lastNameFocus = FocusNode();
  final _phoneFocus    = FocusNode();
  final _addressFocus  = FocusNode();

  bool   _isLoading      = true;
  bool   _isSaving       = false;
  bool   _isUploading    = false;
  bool   _isDeleting     = false;
  double _uploadProgress = 0;

  File?  _imageFile;
  String _networkImage = '';   // URL from Firestore or Google
  bool   _isDirty      = false;

  // ── Doc ID = email ──────────────────────────────────────────
  String _docId(User user) => user.email!.toLowerCase().trim();
  DocumentReference _userDoc(User user) =>
      FirebaseFirestore.instance.collection('users').doc(_docId(user));

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUserData();
    for (final c in [_firstNameCtrl, _lastNameCtrl, _phoneCtrl, _addressCtrl]) {
      c.addListener(() { if (mounted) setState(() => _isDirty = true); });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD  — pre-fill photo from Google immediately, then Firestore
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (mounted) setState(() => _isLoading = true);

      // ✅ Pre-fill from Firebase Auth immediately (no Firestore wait)
      _emailCtrl.text = user.email ?? '';

      // Use Google photo as default right away
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        _networkImage = user.photoURL!;
      }

      // Split display name as fallback
      final nameParts = (user.displayName ?? '').trim().split(' ');
      _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameCtrl.text  = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Then override with Firestore data if available
      final doc = await _userDoc(user).get();
      if (doc.exists) {
        final d = doc.data()! as Map<String, dynamic>;

        if ((d['firstName'] ?? '').toString().isNotEmpty)
          _firstNameCtrl.text = d['firstName'];
        if ((d['lastName'] ?? '').toString().isNotEmpty)
          _lastNameCtrl.text = d['lastName'];
        if ((d['phone'] ?? '').toString().isNotEmpty)
          _phoneCtrl.text = d['phone'];
        if ((d['address'] ?? '').toString().isNotEmpty)
          _addressCtrl.text = d['address'];

        // Prefer user-uploaded photo over Google photo
        final storedPhoto = d['photo']?.toString() ?? '';
        if (storedPhoto.isNotEmpty) _networkImage = storedPhoto;
      }

      _isDirty = false;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('LOAD ERROR: $e');
      _showSnack('Failed to load profile.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD PHOTO
  // ─────────────────────────────────────────────────────────────

  Future<String?> _uploadPhoto(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ref = FirebaseStorage.instance
          .ref('profile_images/${user.uid}/profile.jpg');

      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        setState(() => _uploadProgress =
            snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes));
      });

      final snapshot = await task;
      if (snapshot.state != TaskState.success) return null;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE  — no pre-read, direct merge write = fast
  // ─────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack('Session expired. Please log in again.', isError: true);
        return;
      }

      if (mounted) setState(() => _isSaving = true);

      // Upload photo if new one was picked
      if (_imageFile != null) {
        setState(() { _isUploading = true; _uploadProgress = 0; });
        final url = await _uploadPhoto(_imageFile!);
        setState(() => _isUploading = false);

        if (url != null && url.isNotEmpty) {
          _networkImage = url;
          _imageFile    = null;
        } else {
          _showSnack('Photo upload failed. Other changes saved.', isError: true);
        }
      }

      final fullName =
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

      // Update Firebase Auth in parallel with Firestore
      await Future.wait([
        user.updateDisplayName(fullName),
        if (_networkImage.isNotEmpty) user.updatePhotoURL(_networkImage),
      ]);

      // ✅ Direct merge — no pre-read needed, fast single write
      await _userDoc(user).set({
        'uid':       user.uid,
        'email':     _docId(user),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName':  _lastNameCtrl.text.trim(),
        'name':      fullName,
        'phone':     _phoneCtrl.text.trim(),
        'address':   _addressCtrl.text.trim(),
        'photo':     _networkImage,
        'updatedAt': FieldValue.serverTimestamp(),
        // createdAt only set on first write via merge — won't overwrite
      }, SetOptions(merge: true));

      _isDirty = false;
      if (mounted) setState(() {});
      _showSnack('Profile saved ✓');
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      _showSnack('Save failed. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving       = false;
          _isUploading    = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PICK IMAGE
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source:       ImageSource.gallery,
        imageQuality: 75,
        maxWidth:     800,
        maxHeight:    800,
      );
      if (picked != null && mounted) {
        setState(() {
          _imageFile = File(picked.path);
          _isDirty   = true;
        });
      }
    } catch (e) {
      _showSnack('Could not open gallery.', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MAP — reads full address from MapPickerResult
  // ─────────────────────────────────────────────────────────────

  Future<void> _openMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (!mounted) return;

    // ✅ Handles both MapPickerResult and plain String returns
    if (result is MapPickerResult) {
      final combined = [
        result.addressDetails,
        result.fullAddress,
      ].where((s) => s.isNotEmpty).join(', ');

      setState(() {
        _addressCtrl.text = combined.isNotEmpty
            ? combined
            : result.shortAddress;
        _isDirty = true;
      });
    } else if (result is String && result.isNotEmpty) {
      setState(() {
        _addressCtrl.text = result;
        _isDirty          = true;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:   const Text('Log out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPage()),
        (_) => false,
      );
    } catch (e) {
      _showSnack('Logout failed. Try again.', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE ACCOUNT — wipes Storage photo, Firestore doc, Auth user
  // ─────────────────────────────────────────────────────────────

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete your account?'),
        content: const Text(
          'This will permanently delete your profile, saved address and '
          'photo. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Second confirmation to prevent accidental taps on a destructive action.
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'Your account and all associated data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, delete my account',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (finalConfirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Session expired. Please log in again.', isError: true);
      return;
    }

    if (mounted) setState(() => _isDeleting = true);

    try {
      final email = _docId(user);

      // 1. Delete profile photo from Storage (ignore if it never existed).
      try {
        await FirebaseStorage.instance
            .ref('profile_images/${user.uid}/profile.jpg')
            .delete();
      } catch (e) {
        debugPrint('STORAGE DELETE (non-fatal): $e');
      }

      // 2. Delete the user's Firestore document (keyed by email).
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .delete();
      } catch (e) {
        debugPrint('FIRESTORE DELETE (non-fatal): $e');
      }

      // 3. Delete the Firebase Auth account itself.
      await user.delete();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPage()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnack(
          'For security, please log out and log back in, then try deleting '
          'your account again.',
          isError: true,
        );
      } else {
        _showSnack('Delete failed: ${e.message}', isError: true);
      }
    } catch (e) {
      debugPrint('DELETE ACCOUNT ERROR: $e');
      _showSnack('Delete failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SNACKBAR
  // ─────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // AVATAR
  // ─────────────────────────────────────────────────────────────

  ImageProvider _avatarImage() {
    if (_imageFile != null)       return FileImage(_imageFile!);
    if (_networkImage.isNotEmpty) return NetworkImage(_networkImage);
    return const AssetImage('assets/user.jfif');
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final isTablet = sw > 700;
    final double sp = (sw / 390).clamp(0.85, 1.3);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation:       0,
        backgroundColor: Colors.transparent,
        centerTitle:     true,
        title: const Text('My Profile',
            style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isDirty && !_isSaving ? _saveProfile : null,
              child: Text('Save',
                  style: TextStyle(
                      color:      _isDirty ? Colors.indigo : Colors.grey,
                      fontWeight: FontWeight.w700,
                      fontSize:   15)),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 28 : 16, 16,
                      isTablet ? 28 : 16,
                      40 + mq.viewPadding.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildAvatarCard(isTablet, sp),
                              const SizedBox(height: 24),
                              _sectionCard(
                                title: 'Personal Information',
                                children: [
                                  // First + Last name
                                  isTablet
                                      ? Row(children: [
                                          Expanded(child: _field(
                                            controller: _firstNameCtrl,
                                            hint: 'First Name',
                                            icon: Icons.person_outline,
                                            sp: sp,
                                            textCapitalization: TextCapitalization.words,
                                            nextFocus: _lastNameFocus,
                                            validator: _nameValidator,
                                          )),
                                          const SizedBox(width: 14),
                                          Expanded(child: _field(
                                            controller: _lastNameCtrl,
                                            hint: 'Last Name',
                                            icon: Icons.person,
                                            sp: sp,
                                            focusNode: _lastNameFocus,
                                            nextFocus: _phoneFocus,
                                            textCapitalization: TextCapitalization.words,
                                            validator: _nameValidator,
                                          )),
                                        ])
                                      : Column(children: [
                                          _field(
                                            controller: _firstNameCtrl,
                                            hint: 'First Name',
                                            icon: Icons.person_outline,
                                            sp: sp,
                                            textCapitalization: TextCapitalization.words,
                                            nextFocus: _lastNameFocus,
                                            validator: _nameValidator,
                                          ),
                                          _field(
                                            controller: _lastNameCtrl,
                                            hint: 'Last Name',
                                            icon: Icons.person,
                                            sp: sp,
                                            focusNode: _lastNameFocus,
                                            nextFocus: _phoneFocus,
                                            textCapitalization: TextCapitalization.words,
                                            validator: _nameValidator,
                                          ),
                                        ]),

                                  // Email (read-only)
                                  _field(
                                    controller: _emailCtrl,
                                    hint:     'Email',
                                    icon:     Icons.email_outlined,
                                    sp:       sp,
                                    readOnly: true,
                                    keyboard: TextInputType.emailAddress,
                                  ),

                                  // Phone
                                  _field(
                                    controller: _phoneCtrl,
                                    hint:      'Phone Number',
                                    icon:      Icons.phone_outlined,
                                    sp:        sp,
                                    focusNode: _phoneFocus,
                                    nextFocus: _addressFocus,
                                    keyboard:  TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator:  _phoneValidator,
                                    prefixText: '+91 ',
                                  ),

                                  // Address — NOT required, auto-filled from map
                                  _field(
                                    controller:      _addressCtrl,
                                    hint:            'Your Address',
                                    icon:            Icons.location_on_outlined,
                                    sp:              sp,
                                    focusNode:       _addressFocus,
                                    maxLines:        3,
                                    required:        false,   // ✅ not compulsory
                                    textInputAction: TextInputAction.done,
                                  ),

                                  // Map picker button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openMap,
                                      icon:  const Icon(Icons.map_outlined, size: 16),
                                      label: Text(
                                        _addressCtrl.text.isEmpty
                                            ? 'Pick address from map'
                                            : 'Change address on map',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.indigo,
                                        side: BorderSide(color: Colors.indigo.shade200),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Save button
                              SizedBox(
                                width:  double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: (!_isDirty || _isSaving) ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    elevation:       0,
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.indigo.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5, color: Colors.white))
                                      : Text('Save Profile',
                                          style: TextStyle(
                                              fontSize:   15 * sp,
                                              fontWeight: FontWeight.w700)),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Logout button
                              SizedBox(
                                width:  double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: _logout,
                                  icon:  const Icon(Icons.logout, size: 18),
                                  label: Text('Log Out',
                                      style: TextStyle(
                                          fontSize:   15 * sp,
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red.shade200),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Delete account button
                              SizedBox(
                                width:  double.infinity,
                                height: 54,
                                child: TextButton.icon(
                                  onPressed: _isDeleting ? null : _deleteAccount,
                                  icon: _isDeleting
                                      ? const SizedBox(
                                          width: 16, height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.red))
                                      : const Icon(Icons.delete_forever,
                                          size: 18, color: Colors.red),
                                  label: Text('Delete My Profile',
                                      style: TextStyle(
                                          fontSize:   15 * sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red)),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Upload overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Uploading photo…',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value:           _uploadProgress,
                            minHeight:       6,
                            backgroundColor: Colors.grey.shade200,
                            color:           Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          // Delete-account overlay
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Deleting your account…',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 16),
                      CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AVATAR CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildAvatarCard(bool isTablet, double sp) {
    final double r = isTablet ? 64 : 54;
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5B67F1), Color(0xFF7D89FF)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color:      Colors.indigo.withOpacity(0.22),
              blurRadius: 20,
              offset:     const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3)),
                child: CircleAvatar(
                  radius:          r,
                  backgroundImage: _avatarImage(),
                  backgroundColor: const Color(0xFFEEF2FF),
                ),
              ),

              // Camera button
              Positioned(
                bottom: 2, right: 2,
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:  Colors.white,
                      shape:  BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5B67F1), width: 2),
                    ),
                    child: _isUploading
                        ? SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _uploadProgress > 0 ? _uploadProgress : null,
                                color: Colors.indigo))
                        : const Icon(Icons.camera_alt,
                            size: 16, color: Colors.indigo),
                  ),
                ),
              ),

              // "New" badge when local file picked
              if (_imageFile != null)
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('New',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            () {
              final n = '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim();
              return n.isEmpty ? 'Your Name' : n;
            }(),
            style: TextStyle(
                color: Colors.white,
                fontSize: 20 * sp,
                fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 4),

          Text(
            _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'email@example.com',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('User Account',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION CARD
  // ─────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset:     const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FORM FIELD
  // ─────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double sp,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType keyboard = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? prefixText,
    int  maxLines = 1,
    bool required = true,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller:         controller,
        focusNode:          focusNode,
        keyboardType:       keyboard,
        textInputAction:    textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters:    inputFormatters,
        maxLines:           maxLines,
        readOnly:           readOnly,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$hint is required'
                    : null
                : null),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText:    hint,
          hintStyle:   TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:  Icon(icon, color: Colors.indigo, size: 20),
          prefixText:  prefixText,
          prefixStyle: const TextStyle(
              color: Color(0xFF111827), fontWeight: FontWeight.w500),
          suffixIcon: readOnly
              ? const Icon(Icons.lock_outline, size: 15, color: Colors.grey)
              : null,
          filled:    true,
          fillColor: readOnly ? const Color(0xFFF0F0F6) : const Color(0xFFF7F8FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:  BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.indigo, width: 1.4)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:  BorderSide(color: Colors.red.shade400)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:  BorderSide(color: Colors.red.shade400, width: 1.4)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VALIDATORS
  // ─────────────────────────────────────────────────────────────

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    if (v.trim().length < 2)           return 'Must be at least 2 characters';
    if (v.trim().length > 30)          return 'Must be under 30 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(v.trim()))
      return 'Only letters, hyphens, and apostrophes allowed';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10)    return 'Enter a valid 10-digit phone number';
    if (digits.startsWith('0')) return 'Phone number cannot start with 0';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits))
      return 'Enter a valid Indian mobile number';
    return null;
  }
}