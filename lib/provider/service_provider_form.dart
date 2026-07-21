import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../provider/service_config.dart';
import '../provider/succespage.dart';

// FIX (NEW): needed so we can force an immediate FCM token mirror into
// the provider doc right after it's created — see the comment block in
// _submitForm() below for why this is necessary. Adjust this relative
// path if notification_service.dart lives somewhere else in your
// project (per project memory it's package:callme/profile/notification_service.dart).
import '../profile/notification_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

const _kPurple    = Color(0xFF5C35CC);
const _kPurpleLt  = Color(0xFF7C6EFF);
const _kBg        = Color(0xFFF4F6FB);
const _kCard      = Colors.white;
const _kDanger    = Color(0xFFE53935);
const _kSuccess   = Color(0xFF2E7D32);
const _kFieldBg   = Color(0xFFF7F8FC);
const _kBorder    = Color(0xFFE2E4EE);
const _kTextHigh  = Color(0xFF1A1D2E);
const _kTextMid   = Color(0xFF555A72);
const _kTextLow   = Color(0xFF9398B0);

// ─── File-size limits ─────────────────────────────────────────────────────────

const _kMaxImageBytes = 500 * 1024;        // 500 KB
const _kMaxDocBytes   = 5  * 1024 * 1024; // 5 MB

// ─── The one always-mandatory document key ────────────────────────────────────

const _kCompulsoryDoc = 'Aadhaar Card';

// ─── Readable document-ID prefix map ─────────────────────────────────────────
//
// Produces IDs like  CIV-765791 / CLE-961199 / EDU-003040 etc.
// Keys must match the serviceType strings used in serviceConfigs.
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _kServicePrefix = {
  'civil':     'CIV',
  'cleaning':  'CLE',
  'education': 'EDU',
  'hotel':     'HOT',
  'laundry':   'LAU',
  'plumbing':  'PLU',
  'resort':    'RST',
  'salon':     'SAL',
  'water':     'WAT',
  // Add more verticals here as needed
};

/// Generates a readable provider document ID, e.g. `CIV-765791`.
///
/// Algorithm:
///   prefix   = 3-letter code from [_kServicePrefix] (falls back to first-3
///               uppercase chars of the serviceType)
///   suffix   = last 6 digits of current epoch-milliseconds, zero-padded
///
/// Collision probability is negligible for typical marketplace scale;
/// [_ensureUniqueProviderId] adds a retry loop just in case.
String _buildProviderId(String serviceType) {
  final key    = serviceType.trim().toLowerCase();
  final prefix = _kServicePrefix[key] ??
      serviceType.trim().toUpperCase().replaceAll(' ', '').padRight(3, 'X').substring(0, 3);
  final suffix = (DateTime.now().millisecondsSinceEpoch % 1000000)
      .toString()
      .padLeft(6, '0');
  return '$prefix-$suffix';
}

/// Retries up to [maxAttempts] times to find an ID not already in Firestore.
Future<String> _ensureUniqueProviderId(
  FirebaseFirestore db,
  String serviceType, {
  int maxAttempts = 10,
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    // Small delay so millisecond-based suffix actually changes on retry
    if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 2));
    final id   = _buildProviderId(serviceType);
    final snap = await db.collection('providers').doc(id).get();
    if (!snap.exists) return id;
  }
  // Extremely unlikely fallback: append uid suffix
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return '${_buildProviderId(serviceType)}-${uid.substring(0, 4).toUpperCase()}';
}

// ═════════════════════════════════════════════════════════════════════════════
//  ServiceProviderForm
// ═════════════════════════════════════════════════════════════════════════════

class ServiceProviderForm extends StatefulWidget {
  final String type;
  final String providerType;

  const ServiceProviderForm({
    super.key,
    required this.type,
    required this.providerType,
  });

  @override
  State<ServiceProviderForm> createState() => _ServiceProviderFormState();
}

class _ServiceProviderFormState extends State<ServiceProviderForm>
    with SingleTickerProviderStateMixin {

  // ── Pagination ──────────────────────────────────────────────────────────────
  int  _step     = 0;
  bool _loading  = false;
  bool _ownTools = false;

  final _pageCtrl = PageController();

  // ✅ NEW — The step list is now BUILT PER SERVICE TYPE instead of being a
  // fixed 5-step sequence. Every step key maps to a widget builder and a
  // label; whether a given key is included depends on the category's
  // ServiceConfig flags:
  //   - 'service' (the tools & equipment toggle) is skipped when
  //     `_config.showToolsOption == false`
  //   - 'bank' (bank details) is skipped when
  //     `_config.showBankDetails == false`
  // 'categories', 'business', and 'documents' are always present.
  //
  // Everything else in this file (progress bar, step labels, validation,
  // nav buttons, submit) reads from `_stepKeys` instead of a hardcoded
  // count, so it automatically adapts to however many steps are active.
  List<String> get _stepKeys {
    final keys = <String>['categories', 'business'];
    if (_config.showToolsOption != false) keys.add('service');
    if (_config.showBankDetails != false) keys.add('bank');
    keys.add('documents');
    return keys;
  }

  static const Map<String, String> _stepLabelMap = {
    'categories': 'Categories',
    'business':   'Business',
    'service':    'Service',
    'bank':       'Bank',
    'documents':  'Documents',
  };

  List<String> get _stepLabels =>
      _stepKeys.map((k) => _stepLabelMap[k]!).toList();

  // ── Data ─────────────────────────────────────────────────────────────────────
  File?               _businessImage;
  List<String>        _selectedCats   = [];
  Map<String, File>   _pickedDocFiles  = {};
  Map<String, String> _uploadedDocs   = {};

  // ── Form keys ────────────────────────────────────────────────────────────────
  final _businessFormKey = GlobalKey<FormState>();
  final _bankFormKey     = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────────
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

  // ── Derived config ───────────────────────────────────────────────────────────
  dynamic get _config => serviceConfigs[widget.type]!;

  List<String> get _allCats =>
      (_config.serviceCategories as List<dynamic>).cast<String>();

  List<String> get _requiredDocs =>
      (_config.requiredDocuments as List<dynamic>).cast<String>();

  static final RegExp _emailRe =
      RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$');
  static final RegExp _ifscRe =
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _allControllers) c.dispose();
    super.dispose();
  }

  // ── Step validation ──────────────────────────────────────────────────────────
  //
  // Each of these returns a list of *specific, human-readable* problems for
  // the current step. An empty list means the step is complete. This powers
  // both the inline field-level red errors (via the Form widgets) AND the
  // summary sheet shown in [_showMissingSheet], so the provider always knows
  // exactly what they still need to fix.
  //
  // ✅ UPDATED — dispatches on the step's KEY (from `_stepKeys`) rather than
  // a hardcoded index, since the index of e.g. "documents" now shifts
  // depending on which optional steps are active for this category.
  // ─────────────────────────────────────────────────────────────────────────────

  List<String> _missingItemsForStep(int step) {
    final key = _stepKeys[step];
    switch (key) {
      case 'categories':
        return _categoriesMissing();
      case 'business':
        return _businessMissing();
      case 'service':
        return const [];
      case 'bank':
        return _bankMissing();
      case 'documents':
        return _documentsMissing();
      default:
        return const [];
    }
  }

  List<String> _categoriesMissing() {
    if (_selectedCats.isEmpty) {
      return ['Select at least one service category to continue.'];
    }
    return const [];
  }

  List<String> _businessMissing() {
    final issues = <String>[];

    if (_businessCtrl.text.trim().isEmpty) issues.add('Business name is required.');
    if (_ownerCtrl.text.trim().isEmpty) issues.add('Owner / manager name is required.');

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      issues.add('Phone number is required.');
    } else if (phone.length != 10) {
      issues.add('Phone number must be exactly 10 digits.');
    }

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      issues.add('Email address is required.');
    } else if (!_emailRe.hasMatch(email)) {
      issues.add('Email address is not valid (e.g. you@example.com).');
    }

    if (_addressCtrl.text.trim().isEmpty) issues.add('Business address is required.');
    if (_cityCtrl.text.trim().isEmpty) issues.add('City is required.');
    if (_stateCtrl.text.trim().isEmpty) issues.add('State is required.');

    final pin = _pincodeCtrl.text.trim();
    if (pin.isEmpty) {
      issues.add('Pincode is required.');
    } else if (pin.length != 6) {
      issues.add('Pincode must be exactly 6 digits.');
    }

    return issues;
  }

  List<String> _bankMissing() {
    final issues = <String>[];

    if (_holderCtrl.text.trim().isEmpty) issues.add('Account holder name is required.');

    final acc = _accountCtrl.text.trim();
    if (acc.isEmpty) {
      issues.add('Account number is required.');
    } else if (acc.length < 9 || acc.length > 18) {
      issues.add('Account number must be 9–18 digits.');
    }

    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    if (ifsc.isEmpty) {
      issues.add('IFSC code is required.');
    } else if (!_ifscRe.hasMatch(ifsc)) {
      issues.add('IFSC code is not valid (e.g. SBIN0001234).');
    }

    final upi = _upiCtrl.text.trim();
    if (upi.isEmpty) {
      issues.add('UPI ID is required.');
    } else if (!upi.contains('@')) {
      issues.add('UPI ID is not valid (e.g. name@upi).');
    }

    return issues;
  }

  List<String> _documentsMissing() {
    if (!_uploadedDocs.containsKey(_kCompulsoryDoc)) {
      return ['$_kCompulsoryDoc must be uploaded before submitting.'];
    }
    return const [];
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  Future<void> _next() async {
    FocusScope.of(context).unfocus();

    final missing = _missingItemsForStep(_step);
    if (missing.isNotEmpty) {
      // Also light up per-field red errors so the exact field is obvious,
      // in addition to the summary sheet.
      final key = _stepKeys[_step];
      if (key == 'business') _businessFormKey.currentState?.validate();
      if (key == 'bank') _bankFormKey.currentState?.validate();
      _showMissingSheet(missing);
      return;
    }

    final lastStep = _stepKeys.length - 1;
    if (_step < lastStep) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut);
    } else {
      await _showAgreementDialog();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut);
    }
  }

  // ── Missing-fields summary sheet ─────────────────────────────────────────────

  void _showMissingSheet(List<String> items) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kDanger.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: _kDanger, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Please complete this step',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _kTextHigh),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                ...items.map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(Icons.circle,
                                size: 6, color: _kDanger),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              issue,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: _kTextMid,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: _elevatedStyle(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Image pick ────────────────────────────────────────────────────────────────

  Future<void> _pickBusinessImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;

      final file  = File(picked.path);
      final bytes = await file.length();

      if (bytes > _kMaxImageBytes) {
        _snackError(
          'Image too large (${(bytes / 1024).toStringAsFixed(0)} KB).\n'
          'Max: 500 KB — please choose a smaller image.',
        );
        return;
      }
      setState(() => _businessImage = file);
    } catch (_) {
      _snackError('Could not open gallery.');
    }
  }

  // ── Location auto-fill ────────────────────────────────────────────────────────

  Future<void> _fillLocation() async {
    try {
      var perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snackError('Location permission denied.');
        return;
      }
      setState(() => _loading = true);
      final pos        = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.first;
      setState(() {
        _addressCtrl.text = [p.street, p.subLocality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        _cityCtrl.text    = p.locality           ?? '';
        _stateCtrl.text   = p.administrativeArea ?? '';
        _pincodeCtrl.text = p.postalCode         ?? '';
      });
      _snackOk('Location filled successfully.');
    } catch (_) {
      _snackError('Could not fetch location — please enter manually.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Document upload ───────────────────────────────────────────────────────────

  Future<void> _uploadDocument(String docName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.single.path == null) return;

      final file  = File(result.files.single.path!);
      final bytes = await file.length();

      if (bytes > _kMaxDocBytes) {
        _snackError(
          '$docName too large '
          '(${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB). Max: 5 MB.',
        );
        return;
      }

      setState(() {
        _loading = true;
        _pickedDocFiles[docName] = file;
      });

      final uid      = FirebaseAuth.instance.currentUser!.uid;
      final cleanKey = docName.replaceAll(' ', '_');
      final ref = FirebaseStorage.instance
          .ref()
          .child('provider_docs/$uid/$cleanKey');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() => _uploadedDocs[docName] = url);
      _snackOk('$docName uploaded.');
    } catch (_) {
      _snackError('Upload failed — please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  //
  // The Firestore document ID is a readable string like CIV-765791,
  // generated by [_ensureUniqueProviderId]. This is the ONLY document
  // created for a provider — there is no separate lookup collection.
  //
  // The Firebase UID is still stored inside the document as `userId` /
  // `uid`, so any screen that needs to find "my provider profile" from the
  // logged-in user can simply query:
  //
  //   providers.where('userId', isEqualTo: currentUser.uid).limit(1)
  //
  // instead of reading a separate `provider_uid_lookup/{uid}` pointer doc.
  //
  // NOTE: for categories where the 'bank' step is hidden (Education,
  // Civil), `bank` in the written document below will simply contain the
  // initial empty-string field values, since the bank controllers are
  // never populated for those categories. This preserves the existing
  // document shape for every other page/query that reads `bank.*` without
  // needing null-checks added elsewhere.
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    try {
      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'You must be logged in.';

      final db = FirebaseFirestore.instance;

      // ── 1. Generate readable provider document ID ──────────────────────────
      final readableId =
          await _ensureUniqueProviderId(db, widget.type);

      // ── 2. Upload business image (if provided) ─────────────────────────────
      String imageUrl = '';
      if (_businessImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child(
              'provider_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
        await ref.putFile(_businessImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // ── 3. Write to providers/{readableId} — the single source of truth ────
      await db.collection('providers').doc(readableId).set({
        // Readable document key is the doc ID itself; store it too for
        // easy access without knowing the document path.
        'providerId':   readableId,   // e.g. "CIV-765791"
        'userId':       user.uid,     // Firebase UID — used for FCM, auth checks
        'uid':          user.uid,     // legacy alias

        'providerName': _businessCtrl.text.trim(),
        'businessName': _businessCtrl.text.trim(),
        'ownerName':    _ownerCtrl.text.trim(),
        'phone':        _phoneCtrl.text.trim(),
        'serviceType':  widget.type.trim().toLowerCase(),
        'providerType': widget.providerType,

        // ★ Categories chosen by the provider at registration (Step 0).
        // OrderService._notifyMatchingProviders() uses this list to decide
        // which providers to fan-out a new-order notification to.
        'categories': _selectedCats,

        'business': {
          'businessName': _businessCtrl.text.trim(),
          'ownerName':    _ownerCtrl.text.trim(),
          'phone':        _phoneCtrl.text.trim(),
          'email':        _emailCtrl.text.trim(),
          'address':      _addressCtrl.text.trim(),
          'city':         _cityCtrl.text.trim(),
          'state':        _stateCtrl.text.trim(),
          'pincode':      _pincodeCtrl.text.trim(),
          'image':        imageUrl,
        },

        'service': {'ownTools': _ownTools},

        'bank': {
          'accountHolder': _holderCtrl.text.trim(),
          'accountNumber': _accountCtrl.text.trim(),
          'ifsc':          _ifscCtrl.text.trim(),
          'upi':           _upiCtrl.text.trim(),
        },

        'documents':           _uploadedDocs,
        'agreementAccepted':   true,
        'agreementAcceptedAt': FieldValue.serverTimestamp(),

        'status':    'pending',
        'isActive':  false,
        'fcmToken':  '',   // see token-mirror fix immediately below —
                           // this gets backfilled a few lines down, not
                           // left to chance on a future login.

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ── 4. FIX: force an immediate FCM token mirror into the provider ──────
      // doc we just created.
      //
      // Why this is needed: to reach this form at all, the person must
      // already be logged in (see the `user == null` check above). That
      // means NotificationService._saveToken() already ran once at THEIR
      // login and already wrote their token to users/{uid} and
      // users/{email}. Its provider-mirror step
      // (_resolveAllProviderDocIds) only mirrors into provider docs that
      // ALREADY EXIST at that moment — and this provider doc didn't exist
      // yet, since we're only creating it right now.
      //
      // Without this call, the doc above sits with fcmToken: '' until the
      // person's NEXT login/token-refresh cycle happens to run (could be
      // days/weeks), even though they were never actually logged out. This
      // is what produces the admin-side "No push sent — provider hasn't
      // logged in since registering" message even for providers who
      // genuinely have been logged in the whole time — the doc just never
      // got its token written.
      //
      // refreshTokenAfterLogin() re-runs the exact same _saveToken() /
      // _writeToken() flow NotificationService already uses at login, so
      // there's no new logic to trust here — it just runs it again, now
      // that this provider doc actually exists to mirror into.
      try {
        await NotificationService().refreshTokenAfterLogin();
        debugPrint('[ServiceProviderForm] Token mirror re-run after '
            'provider doc creation for $readableId');
      } catch (e) {
        debugPrint('[ServiceProviderForm] Token mirror after registration '
            'failed (non-fatal — will still self-heal on next login/token '
            'refresh): $e');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            businessName: _businessCtrl.text.trim(),
            providerType: widget.providerType,
            serviceType:  widget.type,
          ),
        ),
      );
    } catch (e) {
      _snackError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Snacks ────────────────────────────────────────────────────────────────────

  void _snackOk(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_snackBar(msg, _kSuccess, Icons.check_circle_rounded));
  }

  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_snackBar(msg, _kDanger, Icons.error_rounded));
  }

  SnackBar _snackBar(String msg, Color bg, IconData icon) => SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ]),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 4),
      );

  // ── Agreement dialog ──────────────────────────────────────────────────────────

  Future<void> _showAgreementDialog() async {
    bool accepted = false;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.75,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, sc) => Container(
              decoration: const BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _dragHandle(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: sc,
                      padding: EdgeInsets.fromLTRB(
                        22, 24, 22,
                        MediaQuery.of(ctx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _agreementHeader(),
                          const SizedBox(height: 24),
                          _agreementTile(Icons.verified_outlined,
                              'All information and documents submitted are genuine and valid.'),
                          _agreementTile(Icons.gpp_bad_outlined,
                              'Fraudulent activity may permanently suspend the account.'),
                          _agreementTile(Icons.support_agent,
                              'Professional behaviour must be maintained with every customer.'),
                          _agreementTile(Icons.fact_check_outlined,
                              'Your profile will be manually reviewed before approval.'),
                          const SizedBox(height: 20),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: accepted
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accepted
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: accepted,
                                  activeColor: _kPurple,
                                  onChanged: (v) =>
                                      setLocal(() => accepted = v ?? false),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I confirm all details are genuine and I agree to the provider terms.',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: _outlinedStyle(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: accepted
                                    ? () => Navigator.pop(ctx, true)
                                    : null,
                                style: _elevatedStyle(),
                                child: const Text('Accept & Submit'),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) _submitForm();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final isTablet = mq.size.width > 600;
    final hPad     = isTablet ? 48.0 : 16.0;
    final steps    = _stepKeys;

    return Scaffold(
      backgroundColor: _kBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _kTextHigh,
        centerTitle: true,
        title: Text('${widget.type} Registration',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Stack(children: [
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
            child: Column(children: [
              _buildProgress(steps.length),
              const SizedBox(height: 6),
              _buildStepLabels(steps.length),
              const SizedBox(height: 14),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps.map(_stepWidgetFor).toList(),
                ),
              ),
              const SizedBox(height: 10),
              _buildNavButtons(steps.length),
              SizedBox(height: mq.padding.bottom > 0 ? 4 : 10),
            ]),
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black.withOpacity(0.28),
            child: const Center(
              child: CircularProgressIndicator(color: _kPurple),
            ),
          ),
      ]),
    );
  }

  // ✅ NEW — maps a step key to its corresponding page widget.
  Widget _stepWidgetFor(String key) {
    switch (key) {
      case 'categories':
        return _categoriesStep();
      case 'business':
        return _businessStep();
      case 'service':
        return _serviceStep();
      case 'bank':
        return _bankStep();
      case 'documents':
        return _documentsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Progress bar ──────────────────────────────────────────────────────────────

  Widget _buildProgress(int stepCount) {
    return Row(
      children: List.generate(stepCount, (i) {
        final done   = i < _step;
        final active = i == _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i == stepCount - 1 ? 0 : 5),
            height: 7,
            decoration: BoxDecoration(
              color: done
                  ? _kPurple
                  : active
                      ? _kPurpleLt
                      : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepLabels(int stepCount) {
    final labels = _stepLabels;
    return Row(
      children: List.generate(stepCount, (i) {
        final active = i == _step;
        final done   = i < _step;
        return Expanded(
          child: Column(children: [
            if (done)
              const Icon(Icons.check_circle, size: 13, color: _kPurple)
            else
              SizedBox(height: done ? 13 : 0),
            Text(
              labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active
                    ? _kPurple
                    : done
                        ? _kPurple.withOpacity(0.5)
                        : Colors.grey.shade400,
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildNavButtons(int stepCount) => Row(children: [
        if (_step > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _back,
              icon: const Icon(Icons.arrow_back_ios_new, size: 13),
              label: const Text('Back'),
              style: _outlinedStyle(),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _loading ? null : _next,
            style: _elevatedStyle(),
            child: Text(
              _step == stepCount - 1 ? 'Submit Registration' : 'Continue',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ]);

  // ══════════════════════════════════════════════════════════════════
  //  STEP — Categories
  // ══════════════════════════════════════════════════════════════════

  Widget _categoriesStep() {
    return _card(
      title: 'Select Categories',
      subtitle:
          'Choose the services you offer — at least one required.\n'
          'Only orders matching these categories will notify you.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _allCats.map((cat) {
          final sel = _selectedCats.contains(cat);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() =>
                  sel ? _selectedCats.remove(cat) : _selectedCats.add(cat));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? _kPurple : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? _kPurple : Colors.grey.shade300),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: _kPurple.withOpacity(0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Text(cat,
                  style: TextStyle(
                      color: sel ? Colors.white : _kTextHigh,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  STEP — Business Info
  // ══════════════════════════════════════════════════════════════════

  Widget _businessStep() {
    return _card(
      title: 'Business Information',
      subtitle: 'Profile photo is optional · all other fields required',
      child: Form(
        key: _businessFormKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: GestureDetector(
              onTap: _pickBusinessImage,
              child: Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: _kPurple.withOpacity(0.1),
                  backgroundImage: _businessImage != null
                      ? FileImage(_businessImage!)
                      : null,
                  child: _businessImage == null
                      ? const Icon(Icons.store_rounded,
                          size: 36, color: _kPurple)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: _kPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 15),
                  ),
                ),
                if (_businessImage != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => setState(() => _businessImage = null),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _kDanger,
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
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Tap to change · max 500 KB · optional',
                style: TextStyle(fontSize: 11, color: _kTextLow)),
          ),
          const SizedBox(height: 20),
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
                if (v.trim().length != 10) return 'Enter a valid 10-digit number.';
                return null;
              }),
          _field(_emailCtrl, 'Email Address *', Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              helperText: 'e.g. you@example.com',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required.';
                if (!_emailRe.hasMatch(v.trim()))
                  return 'Enter a valid email address.';
                return null;
              }),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: _field(_addressCtrl, 'Business Address *',
                  Icons.location_on_rounded,
                  validator: _required('Address')),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Tooltip(
                message: 'Auto-fill from GPS',
                child: SizedBox(
                  height: 58,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _fillLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ),
            ),
          ]),
          Row(children: [
            Expanded(
              child: _field(_cityCtrl, 'City *', Icons.location_city_rounded,
                  validator: _required('City')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_stateCtrl, 'State *', Icons.map_rounded,
                  validator: _required('State')),
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
                if (v.trim().length != 6) return 'Enter a valid 6-digit pincode.';
                return null;
              }),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  STEP — Service preferences (tools & equipment)
  //  Only reachable when `_config.showToolsOption != false`.
  // ══════════════════════════════════════════════════════════════════

  Widget _serviceStep() {
    return _card(
      title: 'Service Preferences',
      subtitle: 'No required fields — configure as needed',
      child: Container(
        decoration: BoxDecoration(
          color: _kFieldBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
        ),
        child: SwitchListTile(
          value: _ownTools,
          activeColor: _kPurple,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: const Text('I have my own tools & equipment',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kTextHigh)),
          subtitle: const Text('Turn on if you bring your own equipment',
              style: TextStyle(fontSize: 12, color: _kTextLow)),
          onChanged: (v) => setState(() => _ownTools = v),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  STEP — Bank details
  //  Only reachable when `_config.showBankDetails != false`.
  // ══════════════════════════════════════════════════════════════════

  Widget _bankStep() {
    return _card(
      title: 'Bank Details',
      subtitle: 'All fields required for payouts',
      child: Form(
        key: _bankFormKey,
        child: Column(children: [
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
                if (!_ifscRe.hasMatch(v.trim().toUpperCase()))
                  return 'Invalid IFSC (e.g. SBIN0001234).';
                return null;
              }),
          _field(_upiCtrl, 'UPI ID *', Icons.qr_code_rounded,
              helperText: 'e.g. name@upi',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'UPI ID is required.';
                if (!v.contains('@'))
                  return 'Enter a valid UPI ID (e.g. name@upi).';
                return null;
              }),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  STEP — Documents
  // ══════════════════════════════════════════════════════════════════

  Widget _documentsStep() {
    final docs = [
      if (!_requiredDocs.contains(_kCompulsoryDoc)) _kCompulsoryDoc,
      ..._requiredDocs,
    ];

    return _card(
      title: 'Upload Documents',
      subtitle: '$_kCompulsoryDoc is required · others are optional',
      child: Column(
        children: docs.map((doc) {
          final uploaded     = _uploadedDocs.containsKey(doc);
          final isCompulsory = doc == _kCompulsoryDoc;
          final subtitleText = uploaded
              ? 'Uploaded ✓'
              : isCompulsory
                  ? 'Required · PDF or Image · max 5 MB'
                  : 'Optional · PDF or Image · max 5 MB';

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: uploaded
                  ? Colors.green.withOpacity(0.06)
                  : isCompulsory
                      ? _kPurple.withOpacity(0.04)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: uploaded
                    ? Colors.green
                    : isCompulsory
                        ? _kPurple.withOpacity(0.5)
                        : Colors.grey.shade300,
                width: uploaded || isCompulsory ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: uploaded
                      ? Colors.green.withOpacity(0.1)
                      : _kPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  uploaded
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_rounded,
                  color: uploaded ? Colors.green : _kPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Text(doc,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _kTextHigh)),
                    if (isCompulsory)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: _kPurple,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Required',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(subtitleText,
                      style: TextStyle(
                          fontSize: 11,
                          color: uploaded ? Colors.green : _kTextLow)),
                ]),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () => _uploadDocument(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: uploaded ? Colors.green : _kPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(92, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    child: Text(
                      uploaded ? 'Re-upload' : 'Upload',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  Shared widgets
  // ══════════════════════════════════════════════════════════════════

  Widget _card({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          )
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: _kTextHigh)),
          const SizedBox(height: 5),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: _kTextMid)),
          const SizedBox(height: 22),
          child,
        ]),
      ),
    );
  }

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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(
            fontSize: 14,
            color: _kTextHigh,
            fontWeight: FontWeight.w500),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kTextLow, fontSize: 13),
          helperText: helperText,
          helperStyle: const TextStyle(fontSize: 11, color: _kTextLow),
          prefixIcon: Icon(icon, color: _kPurple, size: 20),
          filled: true,
          fillColor: _kFieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          errorStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kPurple, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kDanger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kDanger, width: 1.6),
          ),
        ),
      ),
    );
  }

  // ── Agreement helpers ─────────────────────────────────────────────────────────

  Widget _dragHandle() => Center(
        child: Container(
          width: 56,
          height: 5,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(100)),
        ),
      );

  Widget _agreementHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPurple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _kPurple, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Provider Agreement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Please read before submitting',
                  style: TextStyle(color: _kTextMid, fontSize: 13)),
            ]),
          ),
        ]),
      );

  Widget _agreementTile(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _kPurple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, height: 1.55, fontWeight: FontWeight.w500)),
          ),
        ]),
      );

  ButtonStyle _elevatedStyle() => ElevatedButton.styleFrom(
        backgroundColor: _kPurple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _kPurple.withOpacity(0.45),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        foregroundColor: _kTextMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: _kBorder),
      );

  String? Function(String?) _required(String name) =>
      (v) => (v == null || v.trim().isEmpty) ? '$name is required.' : null;
}