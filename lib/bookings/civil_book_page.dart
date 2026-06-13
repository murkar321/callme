import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/screens/map_picker_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import 'package:intl/intl.dart';

class CivilBookingPage extends StatefulWidget {
  final String serviceName;
  final List<CartItem>? cart;
  final List<dynamic>? products;

  /// Optional hint ID — if provided the provider lookup is skipped.
  final String? initialProviderId;

  const CivilBookingPage({
    super.key,
    required this.serviceName,
    this.cart,
    this.products,
    this.initialProviderId, required String providerId,
  });

  @override
  State<CivilBookingPage> createState() => _CivilBookingPageState();
}

class _CivilBookingPageState extends State<CivilBookingPage>
    with TickerProviderStateMixin {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();

  final _phoneFocus = FocusNode();

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading         = false;
  bool _isSuccess         = false;
  bool _isGettingLocation = false;
  bool _isLoadingProvider = true;

  LatLng? _pickedLatLng;

  String _enquiryId = '';

  // Provider resolved from Firestore
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  // Adaptive reveal: schedule + summary shown after phone is filled
  bool _phoneComplete = false;

  // Animation controllers
  late final AnimationController _pageAnim;
  late final AnimationController _revealAnim;
  late final Animation<double>   _pageFade;
  late final Animation<Offset>   _revealSlide;
  late final Animation<double>   _revealFade;

  static const _accent  = Color(0xFF6A5AE0);
  static const _accent2 = Color(0xFF8F7CFF);

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealAnim, curve: Curves.easeOutCubic));
    _revealFade = CurvedAnimation(parent: _revealAnim, curve: Curves.easeOut);

    _pageAnim.forward();

    _phoneController.addListener(_onPhoneChanged);

    // Pre-fill phone from Firebase auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text = digits.length > 10
          ? digits.substring(digits.length - 10)
          : digits;
    }

    if (widget.initialProviderId != null &&
        widget.initialProviderId!.isNotEmpty) {
      _providerId        = widget.initialProviderId;
      _isLoadingProvider = false;
      _fetchProviderName(widget.initialProviderId!);
    } else {
      _loadProvider();
    }
  }

  void _onPhoneChanged() {
    final complete = _phoneController.text.trim().length >= 10;
    if (complete != _phoneComplete) {
      setState(() => _phoneComplete = complete);
      if (complete) {
        _revealAnim.forward();
      } else {
        _revealAnim.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _revealAnim.dispose();
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // =========================================================
  // PROVIDER LOADER
  // =========================================================

  Future<void> _fetchProviderName(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(id)
          .get();
      if (!mounted || !doc.exists) return;
      final data     = doc.data()!;
      final business = (data['business'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _providerName = (business['businessName'] ??
                data['providerName'] ?? '')
            .toString();
      });
    } catch (_) {}
  }

  Future<void> _loadProvider() async {
    setState(() {
      _isLoadingProvider = true;
      _noProviderMessage = null;
    });
    try {
      final normalised = widget.serviceName.trim().toLowerCase();

      final snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: normalised)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _setProvider(snap.docs.first.id, snap.docs.first.data());
        return;
      }

      final allSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      final match = allSnap.docs.where((doc) {
        final st = (doc.data()['serviceType'] ?? '').toString().toLowerCase();
        return st == normalised;
      }).firstOrNull;

      if (match != null) {
        _setProvider(match.id, match.data());
      } else {
        if (mounted) {
          setState(() {
            _noProviderMessage =
                'No approved provider available for "${widget.serviceName}" yet.\n'
                'Please try again later.';
            _isLoadingProvider = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[CivilBookingPage] _loadProvider error: $e');
      if (mounted) {
        setState(() {
          _noProviderMessage =
              'Could not load a provider. Check your connection and try again.';
          _isLoadingProvider = false;
        });
      }
    }
  }

  void _setProvider(String id, Map<String, dynamic> data) {
    if (!mounted) return;
    final business = (data['business'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _providerId        = id;
      _providerName      = (business['businessName'] ??
              data['providerName'] ?? '')
          .toString();
      _isLoadingProvider = false;
    });
    debugPrint(
        '[CivilBookingPage] provider: $_providerName (id=$_providerId)');
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F8),
      body: _isSuccess ? _buildSuccessView() : _buildMainView(),
      bottomNavigationBar: _isSuccess ? null : _buildBottomBar(),
    );
  }

  // =========================================================
  // MAIN VIEW
  // =========================================================

  Widget _buildMainView() {
    return SafeArea(
      child: FadeTransition(
        opacity: _pageFade,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingProvider
                  ? _buildLoadingState()
                  : _noProviderMessage != null
                      ? _buildNoProviderState()
                      : _buildScrollBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _accent),
          const SizedBox(height: 16),
          Text(
            'Finding a provider…',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      children: [
        // ── Step 1: Your Details ──────────────────────────────
        _stepLabel('1', 'Your Details'),
        const SizedBox(height: 10),
        _buildDetailsCard(),

        // ── Steps 2 & 3 revealed after phone is complete ─────
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: _phoneComplete
              ? SlideTransition(
                  position: _revealSlide,
                  child: FadeTransition(
                    opacity: _revealFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Step 2: Schedule ──────────────────
                        const SizedBox(height: 20),
                        _stepLabel('2', 'Schedule'),
                        const SizedBox(height: 10),
                        _buildDateTimeRow(),

                        // ── Step 3: Enquiry Summary ───────────
                        const SizedBox(height: 20),
                        _stepLabel('3', 'Enquiry Summary'),
                        const SizedBox(height: 10),
                        _buildSummaryCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              if (_providerName != null && _providerName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        _providerName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Submit Enquiry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.serviceName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NO PROVIDER STATE
  // =========================================================

  Widget _buildNoProviderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_mall_directory_outlined,
                  size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              _noProviderMessage ?? 'No provider available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProvider,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STEP LABEL
  // =========================================================

  Widget _stepLabel(String number, String label) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_accent, _accent2]),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DETAILS CARD  (Step 1)
  // =========================================================

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        children: [
          _field(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),

          _field(
            controller: _phoneController,
            hint: 'Mobile Number (10 digits)',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            focusNode: _phoneFocus,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            suffix: _phoneComplete
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 20)
                : null,
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_phoneComplete
                ? Padding(
                    key: const ValueKey('hint'),
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          'Enter 10-digit phone to continue',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-hint')),
          ),

          const SizedBox(height: 14),

          _field(
            controller: _addressController,
            hint: 'Project Address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          // ── Location buttons row ──────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isGettingLocation ? null : _getCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isGettingLocation
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: _accent, strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(
                    _isGettingLocation ? 'Detecting…' : 'GPS',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Pick on Map',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _field(
            controller: _noteController,
            hint: 'Describe your requirement (optional)',
            icon: Icons.notes_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DATE TIME ROW  (Step 2)
  // =========================================================

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _pickerTile(
            icon: Icons.calendar_month_rounded,
            label: 'Preferred Date',
            value: _selectedDate == null
                ? 'Tap to select'
                : DateFormat('dd MMM yyyy').format(_selectedDate!),
            selected: _selectedDate != null,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _pickerTile(
            icon: Icons.access_time_rounded,
            label: 'Preferred Time',
            value: _selectedTime == null
                ? 'Tap to select'
                : _selectedTime!.format(context),
            selected: _selectedTime != null,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _accent.withOpacity(0.5)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? _accent.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? _accent : Colors.grey.shade500,
                  size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: selected ? _accent : Colors.grey.shade400,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD  (Step 3) — enquiry, no price
  // =========================================================

  Widget _buildSummaryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_accent, _accent2]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.construction_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Enquiry — no upfront payment',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          // Enquiry notice badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _accent.withOpacity(0.18), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: _accent.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A provider will contact you with a quote after reviewing your enquiry.',
                    style: TextStyle(
                      color: _accent.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOTTOM BAR
  // =========================================================

  Widget _buildBottomBar() {
    final canProceed =
        !_isLoading && !_isLoadingProvider && _providerId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepProgress(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canProceed && _phoneComplete
                    ? _validateAndSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Submit Enquiry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgress() {
    final step1 = _nameController.text.isNotEmpty &&
        _phoneComplete &&
        _addressController.text.isNotEmpty;
    final step2 = _selectedDate != null && _selectedTime != null;

    return Row(
      children: [
        _progressDot(done: _phoneComplete, label: 'Details'),
        _progressLine(done: _phoneComplete),
        _progressDot(done: step1 && step2, label: 'Schedule'),
        _progressLine(done: step1 && step2),
        _progressDot(done: false, label: 'Submit'),
      ],
    );
  }

  Widget _progressDot({required bool done, required String label}) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: done ? _accent : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: done ? _accent : Colors.grey.shade400,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressLine({required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      width: 32,
      color: done ? _accent : Colors.grey.shade200,
    );
  }

  // =========================================================
  // SUCCESS VIEW
  // =========================================================

  Widget _buildSuccessView() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 72),
              ),
              const SizedBox(height: 28),
              const Text(
                'Enquiry Submitted!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: $_enquiryId',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We will contact you shortly with a quote and confirm your visit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goHome() {
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: user?.phoneNumber ?? _phoneController.text,
          userEmail: user?.email ?? '',
        ),
      ),
      (_) => false,
    );
  }

  // =========================================================
  // PICKERS
  // =========================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // =========================================================
  // GPS LOCATION
  // =========================================================

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied. Enable it in Settings.');
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      final place = placemarks.first;

      if (!mounted) return;
      _addressController.text =
          '${place.street ?? ''}, ${place.locality ?? ''}, '
          '${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'
              .replaceAll(RegExp(r',\s*,'), ',')
              .trim();

      setState(() {
        _pickedLatLng = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // =========================================================
  // MAP PICKER
  // =========================================================

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MapPickerPage(initialLatLng: _pickedLatLng),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _pickedLatLng = result.latLng);

    final details = result.addressDetails.isNotEmpty
        ? '${result.addressDetails}, ${result.fullAddress}'
        : result.fullAddress;
    _addressController.text = details;
  }

  // =========================================================
  // VALIDATE + SUBMIT ENQUIRY
  // =========================================================

  void _validateAndSubmit() {
    if (_providerId == null || _providerId!.isEmpty) {
      _showSnack('No provider available for this service.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name.');
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      _showSnack('Please enter a valid 10-digit phone number.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showSnack('Please enter your project address.');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showSnack('Please select your preferred date and time.');
      return;
    }
    _save();
  }

  // =========================================================
  // SAVE — ENQUIRY ORDER (isEnquiry: true, totalAmount: 0)
  // =========================================================

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      final docRef = await OrderService.placeOrder(
        serviceType:   widget.serviceName.trim().toLowerCase(),
        services:      [widget.serviceName],
        userId:        user?.uid ?? '',
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user?.email ?? '',
        address:       _addressController.text.trim(),
        note:          _noteController.text.trim(),
        date:          _selectedDate!,
        time:          _selectedTime!.format(context),
        totalAmount:   0,           // quote given by provider
        createdBy:     user?.uid ?? '',
        createdByRole: 'user',
        providerId:    _providerId!,
        providerName:  _providerName ?? '',
        visitType:     'Site Visit',
        isEnquiry:     true,        // marks status as 'enquiry', payment.paid = false
      );

      if (!mounted) return;
      setState(() {
        _enquiryId = docRef.id;
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[CivilBookingPage] save error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Could not submit enquiry: $e');
    }
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: child,
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: _accent, size: 20),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      );
}