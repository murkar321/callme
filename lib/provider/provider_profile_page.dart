import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../provider/service_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const Color primary   = Color(0xFF5B4CF5);
  static const Color primaryLt = Color(0xFF7C6EFF);
  static const Color bg        = Color(0xFFF4F5FB);
  static const Color surface   = Colors.white;
  static const Color danger    = Color(0xFFE53935);
  static const Color success   = Color(0xFF2E7D32);
  static const Color textHigh  = Color(0xFF1A1D2E);
  static const Color textMid   = Color(0xFF555A72);
  static const Color textLow   = Color(0xFF9398B0);
  static const Color border    = Color(0xFFE8EAEF);
  static const Color fieldBg   = Color(0xFFF6F7FB);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ProviderProfilePage
//
//  Security-rule alignment:
//  • providers/{providerId}: provider can update own doc EXCEPT status field.
//    Deletion is admin-only — delete button is hidden for self-edits.
//  • Firestore doc ID for providers = uid(), so widget.providerId must be UID.
//  • Profile photo upload is OPTIONAL — no validation required.
// ─────────────────────────────────────────────────────────────────────────────
class ProviderProfilePage extends StatefulWidget {
  /// The Firestore document ID in /providers — must be the provider's UID.
  final String providerId;

  /// Pass [isAdmin] = true only when an admin is editing another provider's
  /// profile (e.g. from the Approve Providers page). This unlocks the delete
  /// action, which requires admin privileges in Firestore rules.
  final bool isAdmin;

  const ProviderProfilePage({
    super.key,
    required this.providerId,
    this.isAdmin = false,
  });

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage>
    with SingleTickerProviderStateMixin {
  // ── Firebase ──────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _storage   = FirebaseStorage.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Page state ────────────────────────────────────────────────────────────
  bool _loading  = true;
  bool _saving   = false;
  bool _ownTools = false;
  bool _isActive = true;

  String _status       = 'pending';
  String _providerType = '';
  String _serviceType  = '';
  String _imageUrl     = '';
  File?  _pickedImage;

  List<String>         _selectedCats = [];
  List<String>         _allCats      = [];
  Map<String, dynamic> _docs         = {};

  // ── Controllers ───────────────────────────────────────────────────────────
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

  List<TextEditingController> get _allControllers => [
    _businessCtrl, _ownerCtrl, _phoneCtrl, _emailCtrl,
    _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
    _holderCtrl, _accountCtrl, _ifscCtrl, _upiCtrl,
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final snap = await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .get();

      if (!snap.exists || !mounted) return;

      final d        = snap.data()!;
      final business = (d['business'] as Map?)?.cast<String, dynamic>() ?? {};
      final service  = (d['service']  as Map?)?.cast<String, dynamic>() ?? {};
      final bank     = (d['bank']     as Map?)?.cast<String, dynamic>() ?? {};

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

      _imageUrl     = business['image']   ?? '';
      _ownTools     = service['ownTools'] as bool? ?? false;
      _providerType = d['providerType']   as String? ?? '';
      _serviceType  = d['serviceType']    as String? ?? '';
      _status       = d['status']         as String? ?? 'pending';
      _isActive     = d['isActive']       as bool?   ?? true;
      _selectedCats = List<String>.from(d['categories'] ?? []);
      _docs         = Map<String, dynamic>.from(d['documents'] ?? {});

      if (serviceConfigs.containsKey(_serviceType)) {
        _allCats = List<String>.from(
          serviceConfigs[_serviceType]!.serviceCategories,
        );
      }
    } catch (e) {
      _snack('Failed to load profile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Pick image (OPTIONAL — no validation) ────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (_) {
      _snack('Could not pick image');
    }
  }

  /// Remove profile photo (set to null / empty)
  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _imageUrl    = '';
    });
  }

  ImageProvider? get _imageProvider {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_imageUrl.isNotEmpty) return NetworkImage(_imageUrl);
    return null;
  }

  // ── Upload doc ────────────────────────────────────────────────────────────
  Future<void> _uploadDoc(String name) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file     = File(result.files.single.path!);
      final cleanKey = name.replaceAll(' ', '_');
      final ref      = _storage
          .ref()
          .child('provider_docs/${widget.providerId}/$cleanKey');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() => _docs[name] = url);

      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': url});
      _snack('$name uploaded', ok: true);
    } catch (_) {
      _snack('Upload failed');
    }
  }

  // ── Delete doc ────────────────────────────────────────────────────────────
  Future<void> _deleteDoc(String name) async {
    final confirmed = await _confirm(
      title: 'Remove Document?',
      body: '"$name" will be permanently removed.',
      actionLabel: 'Remove',
    );
    if (!confirmed) return;

    try {
      setState(() => _docs.remove(name));
      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': FieldValue.delete()});
      _snack('Document removed', ok: true);
    } catch (_) {
      _snack('Delete failed');
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Please fill in all required fields');
      return;
    }

    try {
      setState(() => _saving = true);

      // Profile photo is optional — upload only if a new one was picked
      String updatedImage = _imageUrl;
      if (_pickedImage != null) {
        final ref = _storage.ref().child(
          'provider_images/${widget.providerId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_pickedImage!);
        updatedImage = await ref.getDownloadURL();
      }

      // NOTE: We must NOT write `status` here — Firestore rules block
      // self-edits that change the status field.
      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({
        'updatedAt':             FieldValue.serverTimestamp(),
        'providerName':          _businessCtrl.text.trim(),
        'ownerName':             _ownerCtrl.text.trim(),
        'phone':                 _phoneCtrl.text.trim(),
        'categories':            _selectedCats,
        'isActive':              _isActive,
        'business.businessName': _businessCtrl.text.trim(),
        'business.ownerName':    _ownerCtrl.text.trim(),
        'business.phone':        _phoneCtrl.text.trim(),
        'business.email':        _emailCtrl.text.trim(),
        'business.address':      _addressCtrl.text.trim(),
        'business.city':         _cityCtrl.text.trim(),
        'business.state':        _stateCtrl.text.trim(),
        'business.pincode':      _pincodeCtrl.text.trim(),
        'business.image':        updatedImage,
        'service.ownTools':      _ownTools,
        'bank.accountHolder':    _holderCtrl.text.trim(),
        'bank.accountNumber':    _accountCtrl.text.trim(),
        'bank.ifsc':             _ifscCtrl.text.trim(),
        'bank.upi':              _upiCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() => _imageUrl = updatedImage);
      _snack('Profile saved', ok: true);
    } catch (e) {
      _snack('Save failed — check your connection');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Delete profile (admin-only) ───────────────────────────────────────────
  Future<void> _deleteProfile() async {
    final confirmed = await _confirm(
      title: 'Delete Provider?',
      body: 'This profile will be permanently deleted and cannot be recovered.',
      actionLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    try {
      setState(() => _saving = true);
      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .delete();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      _snack('Delete failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────
  Future<bool> _confirm({
    required String title,
    required String body,
    required String actionLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(body,
            style: const TextStyle(color: _T.textMid, fontSize: 14, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _T.textMid)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? _T.danger : _T.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── Profile completion % ──────────────────────────────────────────────────
  int get _completion {
    int s = 0;
    if (_imageUrl.isNotEmpty || _pickedImage != null) s += 15;
    if (_businessCtrl.text.isNotEmpty)  s += 15;
    if (_selectedCats.isNotEmpty)       s += 15;
    if (_docs.isNotEmpty)               s += 20;
    if (_holderCtrl.text.isNotEmpty)    s += 15;
    if (_upiCtrl.text.isNotEmpty)       s += 20;
    return s.clamp(0, 100);
  }

  // ── Status color ──────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (_status) {
      case 'approved': return const Color(0xFF2E7D32);
      case 'rejected': return _T.danger;
      default:         return const Color(0xFFF57C00);
    }
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
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
        body: Center(
          child: CircularProgressIndicator(color: _T.primary),
        ),
      );
    }

    final mq         = MediaQuery.of(context);
    final screenW    = mq.size.width;
    final bottomPad  = mq.viewPadding.bottom + 80;
    // Responsive horizontal padding: tighter on small phones
    final hPad       = screenW < 360 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: _T.bg,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Business Info',
                        icon: Icons.storefront_rounded,
                        child: _buildBusinessFields(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Services',
                        icon: Icons.miscellaneous_services_rounded,
                        child: _buildServicesSection(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Documents',
                        icon: Icons.description_rounded,
                        child: _buildDocumentsSection(),
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Bank Details',
                        icon: Icons.account_balance_rounded,
                        child: _buildBankFields(),
                      ),
                      // Danger zone — only shown to admins
                      if (widget.isAdmin) ...[
                        const SizedBox(height: 16),
                        _buildDangerZone(),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      child: Row(
        children: [
          // Back button
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
          // Status badge — constrained so it never overflows
          if (_status.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _statusColor.withOpacity(0.3)),
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
        ],
      ),
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
            color: _T.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with optional remove button
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _imageProvider,
                  child: _imageProvider == null
                      ? const Icon(Icons.store_rounded,
                          size: 40, color: Colors.white)
                      : null,
                ),
                // Camera edit button
                Positioned(
                  bottom: 0,
                  right: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: _T.primary),
                  ),
                ),
                // Remove photo button (only when photo exists)
                if (_imageProvider != null)
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
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Optional hint label
          const Text(
            'Tap to change photo · Optional',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          // Business name — animated
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
          const SizedBox(height: 4),
          // Provider type / service type chips — wrapped to avoid overflow
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
          // Active toggle — full width row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          style: TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Completion bar
          AnimatedBuilder(
            animation: Listenable.merge(_allControllers),
            builder: (_, __) {
              final pct = _completion;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile completion',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      Text('$pct%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection({
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ── Business fields ───────────────────────────────────────────────────────
  Widget _buildBusinessFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormField(
            controller: _businessCtrl,
            hint: 'Business Name',
            icon: Icons.store_rounded),
        _FormField(
            controller: _ownerCtrl,
            hint: 'Owner Name',
            icon: Icons.person_rounded),
        _FormField(
            controller: _phoneCtrl,
            hint: 'Phone Number',
            icon: Icons.phone_rounded,
            type: TextInputType.phone),
        _FormField(
            controller: _emailCtrl,
            hint: 'Email Address',
            icon: Icons.email_rounded,
            type: TextInputType.emailAddress),
        _FormField(
            controller: _addressCtrl,
            hint: 'Full Address',
            icon: Icons.location_on_rounded),
        // City + State side by side
        Row(
          children: [
            Expanded(
              child: _FormField(
                  controller: _cityCtrl,
                  hint: 'City',
                  icon: Icons.location_city_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FormField(
                  controller: _stateCtrl,
                  hint: 'State',
                  icon: Icons.map_rounded),
            ),
          ],
        ),
        _FormField(
            controller: _pincodeCtrl,
            hint: 'Pincode',
            icon: Icons.pin_drop_rounded,
            type: TextInputType.number),
      ],
    );
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
              final selected = _selectedCats.contains(cat);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (selected) {
                      _selectedCats.remove(cat);
                    } else {
                      _selectedCats.add(cat);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _T.primary.withOpacity(0.1)
                        : _T.fieldBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected ? _T.primary : _T.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected ? _T.primary : _T.textMid,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Documents section ─────────────────────────────────────────────────────
  Widget _buildDocumentsSection() {
    if (_docs.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text('No documents uploaded yet',
              style: TextStyle(color: _T.textLow, fontSize: 13)),
          const SizedBox(height: 4),
          const Text(
            'Documents are uploaded by an administrator during verification.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _T.textLow, fontSize: 12, height: 1.5),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _docs.keys.map((name) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _T.fieldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border),
          ),
          child: Row(
            children: [
              // Doc icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _T.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_rounded,
                    color: _T.primary, size: 18),
              ),
              const SizedBox(width: 10),
              // Doc name — takes remaining space, never overflows
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _T.textHigh,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              // Upload / delete — fixed-width row so they never push out
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SmallIconBtn(
                    icon: Icons.upload_rounded,
                    color: _T.primary,
                    tooltip: 'Re-upload',
                    onTap: () => _uploadDoc(name),
                  ),
                  const SizedBox(width: 4),
                  _SmallIconBtn(
                    icon: Icons.delete_rounded,
                    color: _T.danger,
                    tooltip: 'Remove',
                    onTap: () => _deleteDoc(name),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Bank fields ───────────────────────────────────────────────────────────
  Widget _buildBankFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormField(
            controller: _holderCtrl,
            hint: 'Account Holder Name',
            icon: Icons.person_outline_rounded),
        _FormField(
            controller: _accountCtrl,
            hint: 'Account Number',
            icon: Icons.account_balance_wallet_rounded,
            type: TextInputType.number),
        _FormField(
            controller: _ifscCtrl,
            hint: 'IFSC Code',
            icon: Icons.code_rounded),
        _FormField(
            controller: _upiCtrl,
            hint: 'UPI ID (optional)',
            icon: Icons.qr_code_rounded,
            required: false),
      ],
    );
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Deleting this provider is permanent and cannot be undone. '
            'All associated data will be removed.',
            style: TextStyle(
                fontSize: 13, color: _T.textMid, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _deleteProfile,
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
        ],
      ),
    );
  }

  // ── Save bar ──────────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    final mq          = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 12),
      decoration: BoxDecoration(
        color: _T.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
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
              disabledBackgroundColor: _T.primary.withOpacity(0.5),
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
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero badge chip — constrained to never overflow
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.4,
      ),
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
//  Small icon button
// ─────────────────────────────────────────────────────────────────────────────
class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallIconBtn({
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

// ─────────────────────────────────────────────────────────────────────────────
//  Form field
// ─────────────────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final bool required;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
            fontSize: 14,
            color: _T.textHigh,
            fontWeight: FontWeight.w500),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'This field is required' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _T.textLow, fontSize: 13),
          prefixIcon: Icon(icon, color: _T.primary, size: 20),
          filled: true,
          fillColor: _T.fieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}