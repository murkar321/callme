import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../provider/service_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const primary   = Color(0xFF5C35CC);
  static const primaryLt = Color(0xFF7C6EFF);
  static const bg        = Color(0xFFF4F6FB);
  static const surface   = Colors.white;
  static const danger    = Color(0xFFE53935);
  static const success   = Color(0xFF2E7D32);
  static const textHigh  = Color(0xFF1A1D2E);
  static const textMid   = Color(0xFF555A72);
  static const textLow   = Color(0xFF9398B0);
  static const border    = Color(0xFFE2E4EE);
  static const fieldBg   = Color(0xFFF7F8FC);
}

// ─────────────────────────────────────────────────────────────────────────────
//  File-size limits
// ─────────────────────────────────────────────────────────────────────────────
const _kMaxImageBytes = 500 * 1024;        // 500 KB
const _kMaxDocBytes   = 5  * 1024 * 1024; // 5 MB
const _kCompulsoryDoc = 'Aadhaar Card';

// ─────────────────────────────────────────────────────────────────────────────
//  ProviderProfilePage
//
//  FIX SUMMARY (vs original):
//
//  1. Profile photo path aligned with ServiceProviderForm.
//     ServiceProviderForm writes:  provider_images/{uid}/{timestamp}.jpg
//     Old _save() wrote to:        profile_images/{uid}/profile.jpg   ← WRONG
//     New _save() writes to:       provider_images/{uid}/{timestamp}.jpg ← FIXED
//     Both read from:              business.image in Firestore
//
//  2. Firestore field round-trip fixed.
//     _load() reads nested:  business.businessName, business.ownerName, …
//     Old _save() wrote flat: providerName, ownerName, …              ← WRONG
//     New _save() writes:    business.businessName, business.ownerName, …
//                             + top-level mirrors for admin queries    ← FIXED
//
//  3. Image state refresh after save: _imageUrl updated + _pickedImage
//     cleared so the hero card re-renders the new photo immediately.
// ─────────────────────────────────────────────────────────────────────────────

class ProviderProfilePage extends StatefulWidget {
  /// Firestore doc ID in /providers — must equal the provider's UID.
  final String providerId;

  /// Set true only when an admin opens another provider's profile.
  /// Unlocks the delete button (requires admin Firestore rules).
  final bool isAdmin;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
    this.isAdmin = false,
  });

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  // ── Firebase ──────────────────────────────────────────────────────────────
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Page state ────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving  = false;

  bool   _ownTools     = false;
  bool   _isActive     = true;
  String _status       = 'pending';
  String _providerType = '';
  String _serviceType  = '';

  // ── Image ─────────────────────────────────────────────────────────────────
  /// Download URL stored in Firestore under business.image.
  /// ServiceProviderForm writes this field — we read and update the same key.
  String _imageUrl    = '';

  /// Newly picked local file (not yet uploaded).
  File?  _pickedImage;

  bool get _hasImage => _pickedImage != null || _imageUrl.isNotEmpty;

  ImageProvider? get _imageProvider {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_imageUrl.isNotEmpty) return NetworkImage(_imageUrl);
    return null;
  }

  // ── Documents ─────────────────────────────────────────────────────────────
  /// docName → download URL  (populated from Firestore)
  Map<String, dynamic> _docs = {};

  // ── Selected service categories ───────────────────────────────────────────
  List<String> _selectedCats = [];

  /// All possible categories for this provider's serviceType
  List<String> get _allCats {
    if (_serviceType.isEmpty) return [];
    final cfg = serviceConfigs[_serviceType];
    if (cfg == null) return [];
    return (cfg.serviceCategories as List<dynamic>).cast<String>();
  }

  /// Document list driven by serviceConfigs — Aadhaar always first
  List<String> get _docList {
    if (_serviceType.isEmpty) return [_kCompulsoryDoc];
    final cfg = serviceConfigs[_serviceType];
    if (cfg == null) return [_kCompulsoryDoc];
    final fromConfig = (cfg.requiredDocuments as List<dynamic>).cast<String>();
    return [
      _kCompulsoryDoc,
      ...fromConfig.where((d) => d != _kCompulsoryDoc),
    ];
  }

  // ── Text controllers ──────────────────────────────────────────────────────
  late final _businessCtrl = TextEditingController();
  late final _ownerCtrl    = TextEditingController();
  late final _phoneCtrl    = TextEditingController();
  late final _emailCtrl    = TextEditingController();
  late final _addressCtrl  = TextEditingController();
  late final _cityCtrl     = TextEditingController();
  late final _stateCtrl    = TextEditingController();
  late final _pincodeCtrl  = TextEditingController();
  late final _holderCtrl   = TextEditingController();
  late final _accountCtrl  = TextEditingController();
  late final _ifscCtrl     = TextEditingController();
  late final _upiCtrl      = TextEditingController();

  List<TextEditingController> get _allCtrls => [
    _businessCtrl, _ownerCtrl, _phoneCtrl, _emailCtrl,
    _addressCtrl,  _cityCtrl,  _stateCtrl, _pincodeCtrl,
    _holderCtrl,   _accountCtrl, _ifscCtrl, _upiCtrl,
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _allCtrls) c.dispose();
    super.dispose();
  }

  // ── Load from Firestore ───────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final snap = await _db
          .collection('providers')
          .doc(widget.providerId)
          .get();
      if (!snap.exists || !mounted) return;

      final d        = snap.data()!;
      final business = (d['business'] as Map?)?.cast<String, dynamic>() ?? {};
      final service  = (d['service']  as Map?)?.cast<String, dynamic>() ?? {};
      final bank     = (d['bank']     as Map?)?.cast<String, dynamic>() ?? {};

      // ── Controllers ──────────────────────────────────────────────────────
      _businessCtrl.text = business['businessName'] ?? '';
      _ownerCtrl.text    = business['ownerName']    ?? '';
      _phoneCtrl.text    = business['phone']        ?? '';
      _emailCtrl.text    = business['email']        ?? '';
      _addressCtrl.text  = business['address']      ?? '';
      _cityCtrl.text     = business['city']         ?? '';
      _stateCtrl.text    = business['state']        ?? '';
      _pincodeCtrl.text  = business['pincode']      ?? '';
      _holderCtrl.text   = bank['accountHolder']    ?? '';
      _accountCtrl.text  = bank['accountNumber']    ?? '';
      _ifscCtrl.text     = bank['ifsc']             ?? '';
      _upiCtrl.text      = bank['upi']              ?? '';

      // ── Profile image ────────────────────────────────────────────────────
      // ServiceProviderForm stores the download URL in business.image.
      // We read from and write back to that exact same key so the photo
      // set during registration appears here automatically.
      _imageUrl = business['image'] ?? '';

      // ── Other fields ─────────────────────────────────────────────────────
      _ownTools     = service['ownTools'] as bool?   ?? false;
      _providerType = d['providerType']   as String? ?? '';
      _serviceType  = d['serviceType']    as String? ?? '';
      _status       = d['status']         as String? ?? 'pending';
      _isActive     = d['isActive']       as bool?   ?? true;
      _selectedCats = List<String>.from(d['categories'] ?? []);
      _docs         = Map<String, dynamic>.from(d['documents'] ?? {});
    } catch (_) {
      _snack('Failed to load profile', ok: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Pick profile photo ────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;

      final file  = File(picked.path);
      final bytes = await file.length();

      if (bytes > _kMaxImageBytes) {
        _snack(
          'Image too large (${(bytes / 1024).toStringAsFixed(0)} KB). '
          'Max: 500 KB.',
          ok: false,
        );
        return;
      }
      setState(() => _pickedImage = file);
    } catch (_) {
      _snack('Could not open gallery', ok: false);
    }
  }

  void _removeImage() => setState(() {
    _pickedImage = null;
    _imageUrl    = '';
  });

  // ── Upload document ───────────────────────────────────────────────────────
  // Storage path: provider_docs/{uid}/{docName_underscored}
  Future<void> _uploadDoc(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Session expired — please log in again', ok: false);
      return;
    }
    try {
      await user.getIdToken(true);
    } catch (_) {
      _snack('Could not refresh session', ok: false);
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.single.path == null) return;

      final file  = File(result.files.single.path!);
      final bytes = await file.length();

      if (bytes > _kMaxDocBytes) {
        _snack(
          '$name too large '
          '(${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB). Max: 5 MB.',
          ok: false,
        );
        return;
      }

      setState(() => _saving = true);

      final cleanKey = name.replaceAll(' ', '_');
      final ref = _storage
          .ref()
          .child('provider_docs/${widget.providerId}/$cleanKey');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() => _docs[name] = url);

      await _db
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': url});

      _snack('$name uploaded', ok: true);
    } catch (_) {
      _snack('Upload failed', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete document ───────────────────────────────────────────────────────
  Future<void> _deleteDoc(String name) async {
    final ok = await _confirm(
      title: 'Remove Document?',
      body: '"$name" will be permanently removed.',
      action: 'Remove',
    );
    if (!ok) return;

    try {
      setState(() => _docs.remove(name));
      await _db
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': FieldValue.delete()});
      _snack('Document removed', ok: true);
    } catch (_) {
      _snack('Delete failed', ok: false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Please fix the errors above', ok: false);
      return;
    }

    // Auth guard: ensure token is fresh before any Storage write.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Session expired — please log in again', ok: false);
      return;
    }
    try {
      await user.getIdToken(true);
    } catch (_) {
      _snack('Could not refresh session — check connection', ok: false);
      return;
    }

    try {
      setState(() => _saving = true);

      // ── Upload new photo ─────────────────────────────────────────────────
      // Storage path: provider_images/{uid}/{timestamp}.jpg
      //
      // This matches the path that ServiceProviderForm uses on first
      // registration, so both registration and profile edits land in the
      // same bucket. The download URL is then stored at business.image in
      // Firestore — the same key _load() reads from.
      String updatedUrl = _imageUrl;
      if (_pickedImage != null) {
        final ref = _storage.ref().child(
          'provider_images/${widget.providerId}'
          '/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_pickedImage!);
        updatedUrl = await ref.getDownloadURL();
      }

      // ── Write back to Firestore ──────────────────────────────────────────
      // Nested business.* fields are what _load() reads — these MUST be
      // updated or edits will appear lost on the next reload.
      // Top-level mirrors (providerName, ownerName, phone) are kept in sync
      // so admin list queries that read the root doc stay accurate.
      await _db.collection('providers').doc(widget.providerId).update({
        'updatedAt':             FieldValue.serverTimestamp(),
        // Top-level mirrors for admin queries
        'providerName':          _businessCtrl.text.trim(),
        'ownerName':             _ownerCtrl.text.trim(),
        'phone':                 _phoneCtrl.text.trim(),
        'categories':            _selectedCats,
        'isActive':              _isActive,
        // Nested business map — exactly what _load() reads
        'business.businessName': _businessCtrl.text.trim(),
        'business.ownerName':    _ownerCtrl.text.trim(),
        'business.phone':        _phoneCtrl.text.trim(),
        'business.email':        _emailCtrl.text.trim(),
        'business.address':      _addressCtrl.text.trim(),
        'business.city':         _cityCtrl.text.trim(),
        'business.state':        _stateCtrl.text.trim(),
        'business.pincode':      _pincodeCtrl.text.trim(),
        // Image URL — same key ServiceProviderForm writes to
        'business.image':        updatedUrl,
        // Service and bank
        'service.ownTools':      _ownTools,
        'bank.accountHolder':    _holderCtrl.text.trim(),
        'bank.accountNumber':    _accountCtrl.text.trim(),
        'bank.ifsc':             _ifscCtrl.text.trim(),
        'bank.upi':              _upiCtrl.text.trim(),
      });

      if (!mounted) return;
      // Refresh local state so the hero card re-renders the new photo
      // and the remove button reflects the current image immediately.
      setState(() {
        _imageUrl    = updatedUrl;
        _pickedImage = null;
      });
      _snack('Profile saved', ok: true);
    } catch (_) {
      _snack('Save failed — check your connection', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete provider (admin-only) ──────────────────────────────────────────
  Future<void> _deleteProvider() async {
    final ok = await _confirm(
      title: 'Delete Provider?',
      body: 'This profile will be permanently deleted. This cannot be undone.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok) return;

    try {
      setState(() => _saving = true);
      await _db.collection('providers').doc(widget.providerId).delete();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      _snack('Delete failed', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Profile completion ────────────────────────────────────────────────────
  int get _completion {
    int s = 0;
    if (_hasImage)                          s += 10;
    if (_businessCtrl.text.isNotEmpty)      s += 10;
    if (_phoneCtrl.text.length == 10)       s += 10;
    if (_emailCtrl.text.contains('@'))      s += 10;
    if (_addressCtrl.text.isNotEmpty)       s += 10;
    if (_selectedCats.isNotEmpty)           s += 10;
    if (_docs.containsKey(_kCompulsoryDoc)) s += 15;
    if (_docs.length > 1)                   s += 5;
    if (_holderCtrl.text.isNotEmpty)        s += 10;
    if (_upiCtrl.text.isNotEmpty)           s += 10;
    return s.clamp(0, 100);
  }

  // ── Status colour ─────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (_status) {
      case 'approved': return _T.success;
      case 'rejected': return _T.danger;
      default:         return const Color(0xFFF57C00);
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────
  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(body,
            style: const TextStyle(
                color: _T.textMid, fontSize: 14, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _T.textMid)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? _T.danger : _T.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Flexible(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: ok ? _T.success : _T.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 3),
      ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(child: CircularProgressIndicator(color: _T.primary)),
      );
    }

    final mq       = MediaQuery.of(context);
    final isTablet = mq.size.width > 600;
    final hPad     = isTablet ? 32.0 : (mq.size.width < 360 ? 12.0 : 16.0);
    final botPad   = mq.viewPadding.bottom + 80;

    return Scaffold(
      backgroundColor: _T.bg,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, botPad),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const SizedBox(height: 12),
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Business Info',
                    icon: Icons.storefront_rounded,
                    child: _buildBusinessFields(),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Services & Categories',
                    icon: Icons.miscellaneous_services_rounded,
                    child: _buildServicesSection(),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Documents',
                    icon: Icons.description_rounded,
                    child: _buildDocumentsSection(),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    title: 'Bank Details',
                    icon: Icons.account_balance_rounded,
                    child: _buildBankFields(),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildDangerZone(),
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _T.bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(children: [
        Material(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          shadowColor: Colors.black12,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _T.textHigh),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Provider Profile',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _T.textHigh,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_status.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border:
                    Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
      ]),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.primary, _T.primaryLt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Avatar ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _pickImage,
          child: Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hasImage
                      ? Colors.white.withOpacity(0.5)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withOpacity(0.18),
                backgroundImage: _imageProvider,
                child: _imageProvider == null
                    ? const Icon(Icons.store_rounded,
                        size: 40, color: Colors.white)
                    : null,
              ),
            ),
            // Camera badge
            Positioned(
              bottom: 0,
              right: -4,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 16, color: _T.primary),
              ),
            ),
            // Remove button — only when a photo exists
            if (_hasImage)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _T.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap to change photo · Optional · max 500 KB',
          style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),

        // ── Business name (live preview) ──────────────────────────────────
        AnimatedBuilder(
          animation: _businessCtrl,
          builder: (_, __) {
            final name = _businessCtrl.text.trim();
            return Text(
              name.isEmpty ? 'Your Business Name' : name,
              style: TextStyle(
                color: name.isEmpty ? Colors.white54 : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),

        // ── Provider/service type badges ──────────────────────────────────
        if (_providerType.isNotEmpty || _serviceType.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_providerType.isNotEmpty) _HeroBadge(_providerType),
                if (_serviceType.isNotEmpty)  _HeroBadge(_serviceType),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // ── Active toggle ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            const Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Active',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('Accept new bookings',
                    style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ),
            Switch(
              value: _isActive,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF43A047),
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white24,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Profile completion bar ────────────────────────────────────────
        AnimatedBuilder(
          animation: Listenable.merge(_allCtrls),
          builder: (_, __) {
            final pct = _completion;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                const Text('Profile completion',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('$pct%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ]);
          },
        ),
      ]),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _T.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _T.textHigh),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        const SizedBox(height: 18),
        child,
      ]),
    );
  }

  // ── Business fields ───────────────────────────────────────────────────────
  Widget _buildBusinessFields() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_businessCtrl, 'Business Name *', Icons.store_rounded,
          validator: _required('Business name')),
      _field(_ownerCtrl, 'Owner / Manager Name *', Icons.person_rounded,
          validator: _required('Owner name')),
      _field(_phoneCtrl, 'Phone Number *', Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          helperText: '10-digit mobile number',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone is required.';
            if (v.trim().length != 10)
              return 'Enter a valid 10-digit number.';
            return null;
          }),
      _field(_emailCtrl, 'Email Address *', Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          helperText: 'e.g. you@example.com',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required.';
            if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$')
                .hasMatch(v.trim()))
              return 'Enter a valid email address.';
            return null;
          }),
      _field(_addressCtrl, 'Full Address *', Icons.location_on_rounded,
          validator: _required('Address')),
      Row(children: [
        Expanded(
          child: _field(
            _cityCtrl, 'City *', Icons.location_city_rounded,
            validator: _required('City'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _field(
            _stateCtrl, 'State *', Icons.map_rounded,
            validator: _required('State'),
          ),
        ),
      ]),
      _field(_pincodeCtrl, 'Pincode *', Icons.pin_drop_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          helperText: '6-digit PIN code',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Pincode is required.';
            if (v.trim().length != 6)
              return 'Enter a valid 6-digit pincode.';
            return null;
          }),
    ]);
  }

  // ── Services section ──────────────────────────────────────────────────────
  Widget _buildServicesSection() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
      // Own tools toggle
      Container(
        decoration: BoxDecoration(
          color: _T.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border),
        ),
        child: SwitchListTile(
          title: const Text('Own Tools & Equipment',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _T.textHigh)),
          subtitle: const Text('I bring my own equipment',
              style: TextStyle(fontSize: 12, color: _T.textLow)),
          value: _ownTools,
          activeColor: _T.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          onChanged: (v) => setState(() => _ownTools = v),
        ),
      ),

      if (_allCats.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text('Service Categories',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _T.textMid,
                letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCats.map((cat) {
            final sel = _selectedCats.contains(cat);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => sel
                    ? _selectedCats.remove(cat)
                    : _selectedCats.add(cat));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? _T.primary.withOpacity(0.1)
                      : _T.fieldBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: sel ? _T.primary : _T.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? _T.primary : _T.textMid,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ] else if (_serviceType.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.border),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: _T.textLow, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No category config found for "$_serviceType".',
                style: const TextStyle(color: _T.textMid, fontSize: 13),
              ),
            ),
          ]),
        ),
    ]);
  }

  // ── Documents section ─────────────────────────────────────────────────────
  Widget _buildDocumentsSection() {
    final docs = _docList;

    return Column(
        mainAxisSize: MainAxisSize.min,
        children: docs.map((name) {
          final uploaded     = _docs.containsKey(name);
          final isCompulsory = name == _kCompulsoryDoc;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: uploaded
                  ? const Color(0xFFF0FAF0)
                  : isCompulsory
                      ? _T.primary.withOpacity(0.04)
                      : _T.fieldBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: uploaded
                    ? const Color(0xFF66BB6A)
                    : isCompulsory
                        ? _T.primary.withOpacity(0.4)
                        : _T.border,
                width: uploaded || isCompulsory ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: uploaded
                      ? Colors.green.withOpacity(0.1)
                      : _T.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_circle_rounded
                      : Icons.insert_drive_file_rounded,
                  color: uploaded ? Colors.green : _T.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _T.textHigh,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (isCompulsory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: _T.primary,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Required',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  Text(
                    uploaded
                        ? 'Uploaded ✓'
                        : isCompulsory
                            ? 'PDF or Image · max 5 MB'
                            : 'Optional · PDF or Image · max 5 MB',
                    style: TextStyle(
                        fontSize: 11,
                        color: uploaded ? Colors.green : _T.textLow),
                  ),
                ]),
              ),
              const SizedBox(width: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _IconBtn(
                  icon: Icons.upload_rounded,
                  color: _T.primary,
                  tooltip: uploaded ? 'Re-upload' : 'Upload',
                  onTap: () => _uploadDoc(name),
                ),
                if (uploaded) ...[
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.delete_rounded,
                    color: _T.danger,
                    tooltip: 'Remove',
                    onTap: () => _deleteDoc(name),
                  ),
                ],
              ]),
            ]),
          );
        }).toList());
  }

  // ── Bank fields ───────────────────────────────────────────────────────────
  Widget _buildBankFields() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _field(_holderCtrl, 'Account Holder Name *',
          Icons.person_outline_rounded,
          validator: _required('Account holder name')),
      _field(_accountCtrl, 'Account Number *',
          Icons.account_balance_wallet_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          helperText: '9–18 digits',
          validator: (v) {
            if (v == null || v.trim().isEmpty)
              return 'Account number is required.';
            if (v.trim().length < 9 || v.trim().length > 18)
              return 'Enter a valid account number (9–18 digits).';
            return null;
          }),
      _field(_ifscCtrl, 'IFSC Code *', Icons.code_rounded,
          textCapitalization: TextCapitalization.characters,
          helperText: 'e.g. SBIN0001234',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'IFSC is required.';
            if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
                .hasMatch(v.trim().toUpperCase()))
              return 'Invalid IFSC (e.g. SBIN0001234).';
            return null;
          }),
      _field(_upiCtrl, 'UPI ID (optional)', Icons.qr_code_rounded,
          helperText: 'e.g. name@upi',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (!v.contains('@'))
              return 'Enter a valid UPI ID (e.g. name@upi).';
            return null;
          }),
    ]);
  }

  // ── Danger zone (admin only) ──────────────────────────────────────────────
  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.danger.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: _T.danger, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Danger Zone',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _T.danger)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Deleting this provider is permanent and cannot be undone. '
          'All associated data will be removed.',
          style:
              TextStyle(fontSize: 13, color: _T.textMid, height: 1.5),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _deleteProvider,
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Provider',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _T.danger,
              side: const BorderSide(color: _T.danger, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    final bot = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bot + 12),
      decoration: BoxDecoration(
        color: _T.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _T.primary.withOpacity(0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Shared form field ─────────────────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(
            fontSize: 14,
            color: _T.textHigh,
            fontWeight: FontWeight.w500),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _T.textLow, fontSize: 13),
          helperText: helperText,
          helperStyle: const TextStyle(fontSize: 11, color: _T.textLow),
          prefixIcon: Icon(icon, color: _T.primary, size: 20),
          filled: true,
          fillColor: _T.fieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _T.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _T.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _T.danger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _T.danger, width: 1.6),
          ),
        ),
      ),
    );
  }

  // ── Validator helper ──────────────────────────────────────────────────────
  String? Function(String?) _required(String name) =>
      (v) => (v == null || v.trim().isEmpty) ? '$name is required.' : null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero badge chip
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small icon button (upload / delete)
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
        ),
      ),
    );
  }
}