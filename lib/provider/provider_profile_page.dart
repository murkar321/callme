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

/// A single named field-level validation rule used to build the
/// "exactly what's wrong" error summary shown to the user on save.
class _FieldCheck {
  final String label;
  final FocusNode? focus;
  final String? Function() check;
  const _FieldCheck({required this.label, required this.check, this.focus});
}

class ProviderProfilePage extends StatefulWidget {
  /// Firestore doc ID in /providers — must equal the provider's UID.
  final String providerId;

  /// Set true only when an admin opens another provider's profile.
  /// Unlocks the admin-specific danger zone (currently same as self-delete
  /// but can be extended with extra admin actions).
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
  final _scrollCtrl = ScrollController();

  // ── Page state ────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving  = false;
  bool _deleting = false;

  bool   _ownTools     = false;
  bool   _isActive     = true;
  String _status       = 'pending';
  String _providerType = '';
  String _serviceType  = '';

  // ── Image ─────────────────────────────────────────────────────────────────
  String _imageUrl    = '';
  File?  _pickedImage;

  bool get _hasImage => _pickedImage != null || _imageUrl.isNotEmpty;

  ImageProvider? get _imageProvider {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_imageUrl.isNotEmpty) return NetworkImage(_imageUrl);
    return null;
  }

  // ── Documents ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _docs = {};

  // ── Selected service categories ───────────────────────────────────────────
  List<String> _selectedCats = [];

  List<String> get _allCats {
    if (_serviceType.isEmpty) return [];
    final cfg = serviceConfigs[_serviceType];
    if (cfg == null) return [];
    return (cfg.serviceCategories as List<dynamic>).cast<String>();
  }

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

  // ── Focus nodes (used to jump to + highlight the first failing field) ─────
  final _businessFocus = FocusNode();
  final _ownerFocus    = FocusNode();
  final _phoneFocus    = FocusNode();
  final _emailFocus    = FocusNode();
  final _addressFocus  = FocusNode();
  final _cityFocus     = FocusNode();
  final _stateFocus    = FocusNode();
  final _pincodeFocus  = FocusNode();
  final _holderFocus   = FocusNode();
  final _accountFocus  = FocusNode();
  final _ifscFocus     = FocusNode();
  final _upiFocus      = FocusNode();

  List<FocusNode> get _allFocusNodes => [
    _businessFocus, _ownerFocus, _phoneFocus, _emailFocus,
    _addressFocus,  _cityFocus,  _stateFocus, _pincodeFocus,
    _holderFocus,   _accountFocus, _ifscFocus, _upiFocus,
  ];

  // ── Named validation rules — drives the "what exactly failed" summary ─────
  List<_FieldCheck> get _validations => [
    _FieldCheck(
      label: 'Business Name',
      focus: _businessFocus,
      check: () =>
          _businessCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'Owner / Manager Name',
      focus: _ownerFocus,
      check: () =>
          _ownerCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'Phone Number',
      focus: _phoneFocus,
      check: () {
        final v = _phoneCtrl.text.trim();
        if (v.isEmpty) return 'is required';
        if (v.length != 10) return 'must be a valid 10-digit number';
        return null;
      },
    ),
    _FieldCheck(
      label: 'Email Address',
      focus: _emailFocus,
      check: () {
        final v = _emailCtrl.text.trim();
        if (v.isEmpty) return 'is required';
        if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$').hasMatch(v)) {
          return 'must be a valid email address';
        }
        return null;
      },
    ),
    _FieldCheck(
      label: 'Address',
      focus: _addressFocus,
      check: () =>
          _addressCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'City',
      focus: _cityFocus,
      check: () => _cityCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'State',
      focus: _stateFocus,
      check: () => _stateCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'Pincode',
      focus: _pincodeFocus,
      check: () {
        final v = _pincodeCtrl.text.trim();
        if (v.isEmpty) return 'is required';
        if (v.length != 6) return 'must be a valid 6-digit pincode';
        return null;
      },
    ),
    _FieldCheck(
      label: 'Account Holder Name',
      focus: _holderFocus,
      check: () =>
          _holderCtrl.text.trim().isEmpty ? 'is required' : null,
    ),
    _FieldCheck(
      label: 'Account Number',
      focus: _accountFocus,
      check: () {
        final v = _accountCtrl.text.trim();
        if (v.isEmpty) return 'is required';
        if (v.length < 9 || v.length > 18) {
          return 'must be 9–18 digits';
        }
        return null;
      },
    ),
    _FieldCheck(
      label: 'IFSC Code',
      focus: _ifscFocus,
      check: () {
        final v = _ifscCtrl.text.trim().toUpperCase();
        if (v.isEmpty) return 'is required';
        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v)) {
          return 'is invalid — use the format SBIN0001234';
        }
        return null;
      },
    ),
    _FieldCheck(
      label: 'UPI ID',
      focus: _upiFocus,
      check: () {
        final v = _upiCtrl.text.trim();
        if (v.isEmpty) return null; // optional
        if (!v.contains('@')) return 'must be a valid UPI ID (e.g. name@upi)';
        return null;
      },
    ),
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
    for (final f in _allFocusNodes) f.dispose();
    _scrollCtrl.dispose();
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

      _imageUrl     = business['image'] ?? '';
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
    // Trigger inline red field errors (kept for visual consistency).
    _formKey.currentState?.validate();

    // ── Manual, named validation pass so we can tell the user EXACTLY
    //    which field(s) failed and why, instead of a generic message.
    final failures = <String>[];
    FocusNode? firstFailFocus;

    for (final v in _validations) {
      final err = v.check();
      if (err != null) {
        failures.add('${v.label} $err');
        firstFailFocus ??= v.focus;
      }
    }

    if (_allCats.isNotEmpty && _selectedCats.isEmpty) {
      failures.add('Select at least one service category');
    }
    if (!_docs.containsKey(_kCompulsoryDoc)) {
      failures.add('Upload the compulsory document: $_kCompulsoryDoc');
    }

    if (failures.isNotEmpty) {
      if (firstFailFocus != null) {
        final ctx = firstFailFocus.context;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.2,
            curve: Curves.easeOut,
          );
        }
        firstFailFocus.requestFocus();
      } else if (_scrollCtrl.hasClients) {
        await _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (mounted) _showErrorSummary(failures);
      return;
    }

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

      String updatedUrl = _imageUrl;
      if (_pickedImage != null) {
        final ref = _storage.ref().child(
          'provider_images/${widget.providerId}'
          '/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_pickedImage!);
        updatedUrl = await ref.getDownloadURL();
      }

      await _db.collection('providers').doc(widget.providerId).update({
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
        'business.image':        updatedUrl,
        'service.ownTools':      _ownTools,
        'bank.accountHolder':    _holderCtrl.text.trim(),
        'bank.accountNumber':    _accountCtrl.text.trim(),
        'bank.ifsc':             _ifscCtrl.text.trim(),
        'bank.upi':              _upiCtrl.text.trim(),
      });

      if (!mounted) return;
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

  // ── Error summary sheet — lists exactly what's missing/invalid ────────────
  void _showErrorSummary(List<String> failures) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _T.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.error_rounded,
                      color: _T.danger, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${failures.length} thing${failures.length > 1 ? 's' : ''} '
                    'need${failures.length > 1 ? '' : 's'} your attention',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _T.textHigh),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: failures
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Icon(Icons.circle,
                                        size: 6, color: _T.danger),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          color: _T.textMid,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Got it',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete my profile (self) ──────────────────────────────────────────────
  // Two-step confirmation: first a standard confirm dialog, then the user
  // must type their business name to prevent accidental deletion.
  Future<void> _deleteMyProfile() async {
    // Step 1 — intent confirmation
    final step1 = await _confirm(
      title: 'Delete Your Profile?',
      body: 'This will permanently delete your profile, all documents, and '
            'remove you from the platform. This cannot be undone.',
      action: 'Continue',
      destructive: true,
    );
    if (!step1 || !mounted) return;

    // Step 2 — type business name to confirm
    final nameToMatch = _businessCtrl.text.trim();
    final inputCtrl   = TextEditingController();
    final confirmed   = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: _T.textMid, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'Type '),
                    TextSpan(
                      text: '"$nameToMatch"',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _T.danger),
                    ),
                    const TextSpan(
                        text: ' below to permanently delete your profile.'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: inputCtrl,
                autofocus: true,
                onChanged: (_) => setS(() {}),
                decoration: InputDecoration(
                  hintText: 'Business name',
                  hintStyle: const TextStyle(
                      color: _T.textLow, fontSize: 13),
                  filled: true,
                  fillColor: _T.fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _T.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _T.danger, width: 1.6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: _T.textMid)),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: inputCtrl,
              builder: (_, val, __) {
                final match = val.text.trim() == nameToMatch;
                return ElevatedButton(
                  onPressed: match
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _T.danger.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                  ),
                  child: const Text('Delete Forever',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Perform deletion ──────────────────────────────────────────────────
    try {
      setState(() => _deleting = true);

      // 1. Delete Firestore document
      await _db
          .collection('providers')
          .doc(widget.providerId)
          .delete();

      // 2. Delete Storage files — best-effort (don't block on errors)
      await _deleteStorageFolder(
          'provider_images/${widget.providerId}');
      await _deleteStorageFolder(
          'provider_docs/${widget.providerId}');

      // 3. Sign out if this provider is deleting their own account
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (!widget.isAdmin && currentUid == widget.providerId) {
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;
      // Pop back to the previous screen (login / home)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('[PROFILE] Delete failed: $e');
      _snack('Failed to delete profile — check your connection', ok: false);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /// Deletes every file inside a Storage "folder" (prefix).
  /// Silently ignores errors so a missing folder doesn't block deletion.
  Future<void> _deleteStorageFolder(String prefix) async {
    try {
      final ref    = _storage.ref().child(prefix);
      final result = await ref.listAll();
      for (final item in result.items) {
        try { await item.delete(); } catch (_) {}
      }
      // Recurse into sub-folders
      for (final sub in result.prefixes) {
        await _deleteStorageFolder(sub.fullPath);
      }
    } catch (_) {
      // Folder may not exist — ignore
    }
  }

  // ── Delete provider (admin-only, simpler flow) ────────────────────────────
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

      await _db
          .collection('providers')
          .doc(widget.providerId)
          .delete();

      await _deleteStorageFolder('provider_images/${widget.providerId}');
      await _deleteStorageFolder('provider_docs/${widget.providerId}');

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

    // Full-screen deletion overlay
    if (_deleting) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _T.danger),
              SizedBox(height: 16),
              Text(
                'Deleting your profile…',
                style: TextStyle(
                    color: _T.textMid,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
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
                controller: _scrollCtrl,
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
                  // ── Admin danger zone ────────────────────────────────────
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildAdminDangerZone(),
                  ],
                  // ── Self-delete — always visible to the provider ─────────
                  const SizedBox(height: 16),
                  _buildSelfDeleteZone(),
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
          focusNode: _businessFocus,
          validator: _required('Business name')),
      _field(_ownerCtrl, 'Owner / Manager Name *', Icons.person_rounded,
          focusNode: _ownerFocus,
          validator: _required('Owner name')),
      _field(_phoneCtrl, 'Phone Number *', Icons.phone_rounded,
          focusNode: _phoneFocus,
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
          focusNode: _emailFocus,
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
          focusNode: _addressFocus,
          validator: _required('Address')),
      Row(children: [
        Expanded(
          child: _field(
            _cityCtrl, 'City *', Icons.location_city_rounded,
            focusNode: _cityFocus,
            validator: _required('City'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _field(
            _stateCtrl, 'State *', Icons.map_rounded,
            focusNode: _stateFocus,
            validator: _required('State'),
          ),
        ),
      ]),
      _field(_pincodeCtrl, 'Pincode *', Icons.pin_drop_rounded,
          focusNode: _pincodeFocus,
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
          focusNode: _holderFocus,
          validator: _required('Account holder name')),
      _field(_accountCtrl, 'Account Number *',
          Icons.account_balance_wallet_rounded,
          focusNode: _accountFocus,
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
          focusNode: _ifscFocus,
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
          focusNode: _upiFocus,
          helperText: 'e.g. name@upi',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (!v.contains('@'))
              return 'Enter a valid UPI ID (e.g. name@upi).';
            return null;
          }),
    ]);
  }

  // ── Admin danger zone ─────────────────────────────────────────────────────
  Widget _buildAdminDangerZone() {
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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: _T.danger, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Admin — Danger Zone',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _T.danger)),
        ]),
        const SizedBox(height: 12),
        const Text(
          'As admin you can permanently delete this provider. '
          'All associated data will be removed and cannot be recovered.',
          style: TextStyle(fontSize: 13, color: _T.textMid, height: 1.5),
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

  // ── Self-delete zone — visible to the provider themselves ─────────────────
  Widget _buildSelfDeleteZone() {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.danger.withOpacity(0.20)),
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
          // Header
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _T.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _T.danger, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete My Profile',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _T.danger),
            ),
          ]),
          const SizedBox(height: 12),

          // Warning text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.danger.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _T.danger.withOpacity(0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _T.danger, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will permanently delete your profile, '
                    'all uploaded documents, and your account from '
                    'the platform. You will be signed out immediately. '
                    'This action cannot be undone.',
                    style: TextStyle(
                        fontSize: 12,
                        color: _T.danger,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delete button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_saving || _deleting) ? null : _deleteMyProfile,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text(
                'Delete My Profile',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _T.danger.withOpacity(0.35),
                elevation: 0,
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
            onPressed: (_saving || _deleting) ? null : _save,
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
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
    FocusNode? focusNode,
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
        focusNode: focusNode,
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