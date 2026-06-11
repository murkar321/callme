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
  static const Color textHigh  = Color(0xFF1A1D2E);
  static const Color textMid   = Color(0xFF555A72);
  static const Color textLow   = Color(0xFF9398B0);
  static const Color border    = Color(0xFFE8EAEF);
  static const Color fieldBg   = Color(0xFFF6F7FB);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ProviderProfilePage
// ─────────────────────────────────────────────────────────────────────────────
class ProviderProfilePage extends StatefulWidget {
  final String providerId;
  const ProviderProfilePage({super.key, required this.providerId});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  // ── Firebase ──────────────────────────────────────────────────────────────
  final _firestore = FirebaseFirestore.instance;
  final _storage   = FirebaseStorage.instance;

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── State ─────────────────────────────────────────────────────────────────
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
  final _businessCtrl   = TextEditingController();
  final _ownerCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _stateCtrl      = TextEditingController();
  final _pincodeCtrl    = TextEditingController();
  final _holderCtrl     = TextEditingController();
  final _accountCtrl    = TextEditingController();
  final _ifscCtrl       = TextEditingController();
  final _upiCtrl        = TextEditingController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _businessCtrl, _ownerCtrl, _phoneCtrl, _emailCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
      _holderCtrl, _accountCtrl, _ifscCtrl, _upiCtrl,
    ]) {
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

      if (!snap.exists) return;

      final d        = snap.data()!;
      final business = d['business'] as Map? ?? {};
      final service  = d['service']  as Map? ?? {};
      final bank     = d['bank']     as Map? ?? {};

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
      _ownTools     = service['ownTools'] ?? false;
      _providerType = d['providerType']   ?? '';
      _serviceType  = d['serviceType']    ?? '';
      _status       = d['status']         ?? 'pending';
      _isActive     = d['isActive']       ?? true;
      _selectedCats = List<String>.from(d['categories'] ?? []);
      _docs         = Map<String, dynamic>.from(d['documents'] ?? {});

      if (serviceConfigs.containsKey(_serviceType)) {
        _allCats = List<String>.from(
          serviceConfigs[_serviceType]!.serviceCategories,
        );
      }
    } catch (_) {
      _snack('Failed to load profile');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Pick image ────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked != null) setState(() => _pickedImage = File(picked.path));
    } catch (_) {
      _snack('Could not pick image');
    }
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
      if (result == null) return;

      final file     = File(result.files.single.path!);
      final cleanKey = name.replaceAll(' ', '_');
      final ref      = _storage
          .ref()
          .child('provider_docs/${widget.providerId}/$cleanKey');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() => _docs[name] = url);
      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': url});
      _snack('$name uploaded');
    } catch (_) {
      _snack('Upload failed');
    }
  }

  // ── Delete doc ────────────────────────────────────────────────────────────
  Future<void> _deleteDoc(String name) async {
    try {
      setState(() => _docs.remove(name));
      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({'documents.$name': FieldValue.delete()});
      _snack('Document removed');
    } catch (_) {
      _snack('Delete failed');
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _saving = true);

      String updatedImage = _imageUrl;
      if (_pickedImage != null) {
        final ref = _storage.ref().child(
          'provider_images/${widget.providerId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_pickedImage!);
        updatedImage = await ref.getDownloadURL();
      }

      await _firestore
          .collection('providers')
          .doc(widget.providerId)
          .update({
        'updatedAt':              FieldValue.serverTimestamp(),
        'providerName':           _businessCtrl.text.trim(),
        'ownerName':              _ownerCtrl.text.trim(),
        'phone':                  _phoneCtrl.text.trim(),
        'categories':             _selectedCats,
        'isActive':               _isActive,
        'business.businessName':  _businessCtrl.text.trim(),
        'business.ownerName':     _ownerCtrl.text.trim(),
        'business.phone':         _phoneCtrl.text.trim(),
        'business.email':         _emailCtrl.text.trim(),
        'business.address':       _addressCtrl.text.trim(),
        'business.city':          _cityCtrl.text.trim(),
        'business.state':         _stateCtrl.text.trim(),
        'business.pincode':       _pincodeCtrl.text.trim(),
        'business.image':         updatedImage,
        'service.ownTools':       _ownTools,
        'bank.accountHolder':     _holderCtrl.text.trim(),
        'bank.accountNumber':     _accountCtrl.text.trim(),
        'bank.ifsc':              _ifscCtrl.text.trim(),
        'bank.upi':               _upiCtrl.text.trim(),
      });

      _imageUrl = updatedImage;
      _snack('Profile saved', ok: true);
    } catch (_) {
      _snack('Save failed');
    } finally {
      setState(() => _saving = false);
    }
  }

  // ── Delete profile ────────────────────────────────────────────────────────
  Future<void> _deleteProfile() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Profile?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

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
      setState(() => _saving = false);
    }
  }

  // ── Completion % ─────────────────────────────────────────────────────────
  int get _completion {
    int s = 0;
    if (_imageUrl.isNotEmpty || _pickedImage != null) s += 15;
    if (_businessCtrl.text.isNotEmpty)  s += 15;
    if (_selectedCats.isNotEmpty)       s += 15;
    if (_docs.isNotEmpty)               s += 20;
    if (_holderCtrl.text.isNotEmpty)    s += 15;
    if (_upiCtrl.text.isNotEmpty)       s += 20;
    return s;
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: ok ? const Color(0xFF2E7D32) : _T.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(child: CircularProgressIndicator(color: _T.primary)),
      );
    }

    return Scaffold(
      backgroundColor: _T.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              _TopBar(onBack: () => Navigator.pop(context)),
              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Business Info',
                            icon: Icons.storefront_rounded,
                            child: _buildBusinessFields(),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Services',
                            icon: Icons.miscellaneous_services_rounded,
                            child: _buildServicesContent(),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Documents',
                            icon: Icons.description_rounded,
                            child: _buildDocsContent(),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: 'Bank Details',
                            icon: Icons.account_balance_rounded,
                            child: _buildBankFields(),
                          ),
                          const SizedBox(height: 20),
                          _buildDangerSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ── Floating save button ─────────────────────────────────────────────
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _save),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.primary, _T.primaryLt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  backgroundImage: _imageProvider,
                  child: _imageProvider == null
                      ? const Icon(Icons.person_rounded,
                          size: 46, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: _T.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Business name
          AnimatedBuilder(
            animation: _businessCtrl,
            builder: (_, __) => Text(
              _businessCtrl.text.isEmpty
                  ? 'Business Name'
                  : _businessCtrl.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.providerId,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Badges — wrap to avoid overflow
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_status.isNotEmpty)  _Chip(_status.toUpperCase()),
              if (_providerType.isNotEmpty) _Chip(_providerType),
              if (_serviceType.isNotEmpty)  _Chip(_serviceType),
            ],
          ),
          const SizedBox(height: 18),
          // Active toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Active',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
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
          const SizedBox(height: 18),
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile completion',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('$_completion%',
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
                  value: _completion / 100,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Business fields ───────────────────────────────────────────────────────
  Widget _buildBusinessFields() {
    return Column(
      children: [
        _Field(_businessCtrl, 'Business Name', Icons.store_rounded),
        _Field(_ownerCtrl, 'Owner Name', Icons.person_rounded),
        _Field(_phoneCtrl, 'Phone Number', Icons.phone_rounded,
            type: TextInputType.phone),
        _Field(_emailCtrl, 'Email', Icons.email_rounded,
            type: TextInputType.emailAddress),
        _Field(_addressCtrl, 'Address', Icons.location_on_rounded),
        Row(
          children: [
            Expanded(child: _Field(_cityCtrl, 'City', Icons.location_city_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _Field(_stateCtrl, 'State', Icons.map_rounded)),
          ],
        ),
        _Field(_pincodeCtrl, 'Pincode', Icons.pin_drop_rounded,
            type: TextInputType.number),
      ],
    );
  }

  // ── Services ──────────────────────────────────────────────────────────────
  Widget _buildServicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.w600, color: _T.textHigh)),
            subtitle: const Text('Provider brings their own equipment',
                style: TextStyle(fontSize: 12, color: _T.textLow)),
            value: _ownTools,
            activeColor: _T.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onChanged: (v) => setState(() => _ownTools = v),
          ),
        ),
        if (_allCats.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Service Categories',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _T.textMid)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCats.map((cat) {
              final sel = _selectedCats.contains(cat);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (sel) {
                      _selectedCats.remove(cat);
                    } else {
                      _selectedCats.add(cat);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
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
        ],
      ],
    );
  }

  // ── Documents ─────────────────────────────────────────────────────────────
  Widget _buildDocsContent() {
    if (_docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              const Text('No documents uploaded',
                  style: TextStyle(color: _T.textLow, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _docs.keys.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _T.fieldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _T.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_rounded,
                    color: _T.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(doc,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _T.textHigh,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              // Edit
              _IconBtn(
                icon: Icons.upload_rounded,
                color: _T.primary,
                onTap: () => _uploadDoc(doc),
              ),
              const SizedBox(width: 4),
              // Delete
              _IconBtn(
                icon: Icons.delete_rounded,
                color: _T.danger,
                onTap: () => _deleteDoc(doc),
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
      children: [
        _Field(_holderCtrl, 'Account Holder', Icons.person_outline_rounded),
        _Field(_accountCtrl, 'Account Number',
            Icons.account_balance_wallet_rounded,
            type: TextInputType.number),
        _Field(_ifscCtrl, 'IFSC Code', Icons.code_rounded),
        _Field(_upiCtrl, 'UPI ID', Icons.qr_code_rounded, required: false),
      ],
    );
  }

  // ── Danger zone ───────────────────────────────────────────────────────────
  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.danger.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _T.danger.withOpacity(0.1),
                child:
                    const Icon(Icons.warning_amber_rounded, color: _T.danger, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Danger Zone',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _T.danger)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Deleting this profile is permanent and cannot be reversed.',
            style: TextStyle(fontSize: 13, color: _T.textMid, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _deleteProfile,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Delete Provider Profile',
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _T.primary.withOpacity(0.1),
                child: Icon(icon, color: _T.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _T.textHigh)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onBack,
              child: Container(
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: _T.textHigh),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Provider Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _T.textHigh,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Save bar (bottomNavigationBar)
// ─────────────────────────────────────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _T.primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Badge chip
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Icon button
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Form field
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final bool required;

  const _Field(
    this.controller,
    this.hint,
    this.icon, {
    this.type = TextInputType.text,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(
            fontSize: 14, color: _T.textHigh, fontWeight: FontWeight.w500),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _T.textLow, fontSize: 13),
          prefixIcon: Icon(icon, color: _T.primary, size: 20),
          filled: true,
          fillColor: _T.fieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
}

