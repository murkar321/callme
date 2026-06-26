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

// ─── Constants ───────────────────────────────────────────────────────────────

const _kMaxImageBytes = 500 * 1024; // 500 KB
const _kMaxDocBytes = 5 * 1024 * 1024; // 5 MB
const _kPurple = Color(0xFF5C35CC);
const _kBg = Color(0xFFF4F6FB);
const _kCard = Colors.white;

// The one document that is always mandatory, regardless of service type.
// NOTE: this string must match exactly how it appears in your
// serviceConfigs[...].requiredDocuments lists. Adjust spelling here if needed.
const _kCompulsoryDoc = 'Aadhaar Card';

// ─── Main Widget ─────────────────────────────────────────────────────────────

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

class _ServiceProviderFormState extends State<ServiceProviderForm> {
  // ── State ──────────────────────────────────────────────────────────────────

  int _step = 0;
  bool _loading = false;
  bool _ownTools = false;
  File? _businessImage;

  final _pageCtrl = PageController();
  final List<String> _selectedCats = [];
  final Map<String, String> _uploadedDocs = {};

  // ── Form Keys (one per step) ───────────────────────────────────────────────

  final _businessFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  // ── Controllers ────────────────────────────────────────────────────────────

  final _businessCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [
      _businessCtrl, _ownerCtrl, _phoneCtrl, _emailCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl,
      _bankHolderCtrl, _accountCtrl, _ifscCtrl, _upiCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Step labels ────────────────────────────────────────────────────────────

  static const _stepLabels = [
    'Categories',
    'Business',
    'Service',
    'Bank',
    'Documents',
  ];

  // ── Validation: per step ──────────────────────────────────────────────────

  /// Returns an error message if the current step is incomplete, else null.
  String? _validateCurrentStep() {
    switch (_step) {
      case 0: // Categories
        if (_selectedCats.isEmpty) return 'Please select at least one category.';
        return null;

      case 1: // Business
        // Business photo optional
        if (!_businessFormKey.currentState!.validate()) return '';
        return null;

      case 2: // Service — no required field, always valid
        return null;

      case 3: // Bank
        if (!_bankFormKey.currentState!.validate()) return '';
        return null;

      case 4: // Documents
        if (!_uploadedDocs.containsKey(_kCompulsoryDoc)) return 'Aadhaar Card is required.';
        return null;

      default:
        return null;
    }
  }

  // ── Image pick ────────────────────────────────────────────────────────────

  Future<void> _pickBusinessImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.length();

    if (bytes > _kMaxImageBytes) {
      _showError(
        'Image too large (${(bytes / 1024).toStringAsFixed(0)} KB).\n'
        'Max allowed: 500 KB. Please choose a smaller image.',
      );
      return;
    }

    setState(() => _businessImage = file);
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _fillLocation() async {
    try {
      var permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.first;

      setState(() {
        _addressCtrl.text = '${p.street ?? ''}, ${p.subLocality ?? ''}'.trim();
        _cityCtrl.text = p.locality ?? '';
        _stateCtrl.text = p.administrativeArea ?? '';
        _pincodeCtrl.text = p.postalCode ?? '';
      });

      _showSnack('Location filled successfully.');
    } catch (_) {
      _showError('Could not fetch location. Please enter manually.');
    }
  }

  // ── Document upload ───────────────────────────────────────────────────────

  Future<void> _uploadDocument(String docName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final bytes = await file.length();

      if (bytes > _kMaxDocBytes) {
        _showError(
          '$docName file too large (${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB).\n'
          'Max allowed: 5 MB.',
        );
        return;
      }

      setState(() => _loading = true);

      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('provider_docs/$userId/$docName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() => _uploadedDocs[docName] = url);
      _showSnack('$docName uploaded.');
    } catch (_) {
      _showError('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Provider ID ───────────────────────────────────────────────────────────


  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _nextStep() async {
    FocusScope.of(context).unfocus();
    final error = _validateCurrentStep();
    if (error != null) {
      if (error.isNotEmpty) _showError(error);
      return;
    }

    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _showAgreementDialog();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Agreement dialog ──────────────────────────────────────────────────────

  Future<void> _showAgreementDialog() async {
    bool accepted = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.75,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => Container(
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
                      controller: scrollCtrl,
                      padding: EdgeInsets.fromLTRB(
                        22, 24, 22,
                        MediaQuery.of(ctx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _agreementHeader(),
                          const SizedBox(height: 28),
                          _agreementTile(Icons.verified_outlined,
                              'All submitted information and documents are authentic and valid.'),
                          _agreementTile(Icons.gpp_bad_outlined,
                              'Fraudulent activity or fake documents may permanently suspend the account.'),
                          _agreementTile(Icons.support_agent,
                              'Professional and respectful service behaviour must be maintained.'),
                          _agreementTile(Icons.fact_check_outlined,
                              'Your profile will be manually reviewed before approval.'),
                          const SizedBox(height: 24),
                          // Checkbox tile
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: accepted
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(22),
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
                                      setDialog(() => accepted = v ?? false),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I confirm that all details provided are genuine and I agree to the provider terms.',
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
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
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
                            ],
                          ),
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

    if (result == true) _submitForm();
  }

  Widget _agreementHeader() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _kPurple,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Provider Agreement',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Please review before submission',
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _agreementTile(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: _kPurple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    try {
      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'You must be logged in.';

      final providerId = user.uid;
      String imageUrl = '';

      if (_businessImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('provider_images/$providerId.jpg');
        await ref.putFile(_businessImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(providerId)
          .set({
        'providerId': providerId,
        'userId': user.uid,
        'providerName': _businessCtrl.text.trim(),
        'ownerName': _ownerCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'serviceType': widget.type,
        'providerType': widget.providerType,
        'categories': _selectedCats,
        'business': {
          'businessName': _businessCtrl.text.trim(),
          'ownerName': _ownerCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pincode': _pincodeCtrl.text.trim(),
          'image': imageUrl,
        },
        'service': {'ownTools': _ownTools},
        'bank': {
          'accountHolder': _bankHolderCtrl.text.trim(),
          'accountNumber': _accountCtrl.text.trim(),
          'ifsc': _ifscCtrl.text.trim(),
          'upi': _upiCtrl.text.trim(),
        },
        'documents': _uploadedDocs,
        'agreementAccepted': true,
        'agreementAcceptedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            businessName: _businessCtrl.text.trim(),
            providerType: widget.providerType,
            serviceType: widget.type,
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _dragHandle() => Container(
        width: 60,
        height: 6,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(100)),
      );

  ButtonStyle _elevatedStyle({Color? bg}) => ElevatedButton.styleFrom(
        backgroundColor: bg ?? _kPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final config = serviceConfigs[widget.type]!;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text('${widget.type} Registration',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mq.size.width > 600 ? 48 : 16,
                vertical: 16,
              ),
              child: Column(
                children: [
                  _buildProgressBar(),
                  const SizedBox(height: 6),
                  _buildStepLabels(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _categoriesStep(config),
                        _businessStep(),
                        _serviceStep(),
                        _bankStep(),
                        _documentsStep(config),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNavButtons(),
                  SizedBox(height: mq.padding.bottom > 0 ? 0 : 8),
                ],
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: _kPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(5, (i) {
        final active = i <= _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
            height: 8,
            decoration: BoxDecoration(
              color: active ? _kPurple : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepLabels() {
    return Row(
      children: List.generate(5, (i) {
        final active = i == _step;
        return Expanded(
          child: Text(
            _stepLabels[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? _kPurple : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavButtons() => Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _prevStep,
                icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                label: const Text('Back'),
                style: _outlinedStyle(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _loading ? null : _nextStep,
              style: _elevatedStyle(),
              child: Text(
                _step == 4 ? 'Submit Registration' : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );

  // ── Step 0: Categories ────────────────────────────────────────────────────

  Widget _categoriesStep(dynamic config) {
    return _card(
      title: 'Select Categories',
      subtitle: 'Choose the services you provide (at least one required)',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: (config.serviceCategories as List<dynamic>)
            .cast<String>()
            .map((cat) {
          final sel = _selectedCats.contains(cat);
          return GestureDetector(
            onTap: () => setState(() =>
                sel ? _selectedCats.remove(cat) : _selectedCats.add(cat)),
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
                            color: _kPurple.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Text(cat,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: Business ──────────────────────────────────────────────────────

  Widget _businessStep() {
    return _card(
      title: 'Business Information',
      subtitle: 'Business photo is optional',
      child: Form(
        key: _businessFormKey,
        child: Column(
          children: [
            // Photo
            GestureDetector(
              onTap: _pickBusinessImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: _kPurple.withOpacity(0.1),
                    backgroundImage: _businessImage != null
                        ? FileImage(_businessImage!)
                        : null,
                    child: _businessImage == null
                        ? const Icon(Icons.camera_alt,
                            size: 32, color: _kPurple)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: _kPurple, shape: BoxShape.circle),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Max 500 KB · tap to change',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            _formField(_businessCtrl, 'Business Name', Icons.store,
                validator: _requiredValidator('Business name')),
            _formField(_ownerCtrl, 'Owner Name', Icons.person,
                validator: _requiredValidator('Owner name')),
            _formField(_phoneCtrl, 'Phone Number', Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required.';
              if (v.trim().length != 10) return 'Enter a valid 10-digit number.';
              return null;
            }),
            _formField(_emailCtrl, 'Email Address', Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              final emailReg = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$');
              if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email.';
              return null;
            }),

            // Address with location button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _formField(_addressCtrl, 'Business Address',
                      Icons.location_on,
                      validator: _requiredValidator('Address')),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: SizedBox(
                    height: 58,
                    width: 58,
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
                      child:
                          const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _formField(_cityCtrl, 'City', Icons.location_city,
                      validator: _requiredValidator('City')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _formField(_stateCtrl, 'State', Icons.map,
                      validator: _requiredValidator('State')),
                ),
              ],
            ),
            _formField(_pincodeCtrl, 'Pincode', Icons.pin_drop,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Pincode is required.';
              if (v.trim().length != 6) return 'Enter a valid 6-digit pincode.';
              return null;
            }),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Service ───────────────────────────────────────────────────────

  Widget _serviceStep() {
    return _card(
      title: 'Service Details',
      subtitle: 'Configure your service preferences',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SwitchListTile(
          value: _ownTools,
          activeColor: _kPurple,
          title: const Text('I have my own tools & equipment',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Turn on if you bring your own equipment'),
          onChanged: (v) => setState(() => _ownTools = v),
        ),
      ),
    );
  }

  // ── Step 3: Bank ──────────────────────────────────────────────────────────

  Widget _bankStep() {
    return _card(
      title: 'Bank Details',
      subtitle: 'Required for receiving payouts',
      child: Form(
        key: _bankFormKey,
        child: Column(
          children: [
            _formField(_bankHolderCtrl, 'Account Holder Name', Icons.person,
                validator: _requiredValidator('Account holder name')),
            _formField(_accountCtrl, 'Account Number', Icons.account_balance,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Account number is required.';
              if (v.trim().length < 9 || v.trim().length > 18)
                return 'Enter a valid account number (9–18 digits).';
              return null;
            }),
            _formField(_ifscCtrl, 'IFSC Code', Icons.code,
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'IFSC is required.';
              final ifscReg = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
              if (!ifscReg.hasMatch(v.trim().toUpperCase()))
                return 'Enter a valid IFSC (e.g. SBIN0001234).';
              return null;
            }),
            _formField(_upiCtrl, 'UPI ID', Icons.qr_code,
                validator: (v) {
              if (v == null || v.trim().isEmpty) return 'UPI ID is required.';
              if (!v.contains('@')) return 'Enter a valid UPI ID (e.g. name@upi).';
              return null;
            }),
          ],
        ),
      ),
    );
  }

  // ── Step 4: Documents ─────────────────────────────────────────────────────

  Widget _documentsStep(dynamic config) {
    final docs = (config.requiredDocuments as List<dynamic>).cast<String>();
    return _card(
      title: 'Upload Documents',
      subtitle: 'Documents are optional · upload only if available',
      child: Column(
        children: docs.map((doc) {
          final uploaded = _uploadedDocs.containsKey(doc);
          final isCompulsory = doc == _kCompulsoryDoc;

          String subtitleText;
          if (uploaded) {
            subtitleText = 'Uploaded ✓';
          } else if (isCompulsory) {
            subtitleText = 'Required · PDF or Image · Max 5 MB';
          } else {
            subtitleText = 'Optional · PDF or Image · Max 5 MB';
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: uploaded
                  ? Colors.green.withOpacity(0.06)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: uploaded
                      ? Colors.green
                      : (isCompulsory
                          ? _kPurple.withOpacity(0.6)
                          : Colors.grey.shade300),
                  width: uploaded ? 1.5 : (isCompulsory ? 1.5 : 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: uploaded
                        ? Colors.green.withOpacity(0.1)
                        : _kPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    uploaded ? Icons.check_circle : Icons.upload_file,
                    color: uploaded ? Colors.green : _kPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(doc,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isCompulsory) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kPurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Required',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: TextStyle(
                            fontSize: 11,
                            color: uploaded
                                ? Colors.green
                                : Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _uploadDocument(doc),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            uploaded ? Colors.green : _kPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(96, 44),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        child: Text(
                          uploaded ? 'Re-upload' : 'Upload',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared card wrapper ───────────────────────────────────────────────────

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
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.06))
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  // ── Form field widget ─────────────────────────────────────────────────────

  Widget _formField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: _kPurple, size: 20),
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          errorStyle: const TextStyle(fontSize: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kPurple, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Validator helpers ─────────────────────────────────────────────────────

  String? Function(String?) _requiredValidator(String fieldName) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$fieldName is required.';
      return null;
    };
  }
}