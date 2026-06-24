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
  final List<String>? selectedRenovationItems;
  final String? initialProviderId;

  const CivilBookingPage({
    super.key,
    required this.serviceName,
    this.cart,
    this.products,
    this.selectedRenovationItems,
    this.initialProviderId,
    required String providerId,
  });

  @override
  State<CivilBookingPage> createState() => _CivilBookingPageState();
}

class _CivilBookingPageState extends State<CivilBookingPage>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();
  final _phoneFocus        = FocusNode();

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading         = false;
  bool _isSuccess         = false;
  bool _isGettingLocation = false;
  bool _isLoadingProvider = true;
  bool _phoneComplete     = false;

  LatLng? _pickedLatLng;
  String  _enquiryId = '';

  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _pageAnim;
  late final AnimationController _revealAnim;
  late final Animation<double>   _pageFade;
  late final Animation<Offset>   _revealSlide;
  late final Animation<double>   _revealFade;

  static const _accent  = Color(0xFF6A5AE0);
  static const _accent2 = Color(0xFF8F7CFF);

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pageAnim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _revealAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    _pageFade    = CurvedAnimation(parent: _pageAnim,   curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _revealAnim, curve: Curves.easeOutCubic));
    _revealFade  = CurvedAnimation(parent: _revealAnim, curve: Curves.easeOut);

    _pageAnim.forward();
    _phoneController.addListener(_onPhoneChanged);

    // Pre-fill phone
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    if (widget.initialProviderId != null && widget.initialProviderId!.isNotEmpty) {
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
      complete ? _revealAnim.forward() : _revealAnim.reverse();
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

  // ── Provider loader ───────────────────────────────────────────────────────

  Future<void> _fetchProviderName(String id) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('providers').doc(id).get();
      if (!mounted || !doc.exists) return;
      final data     = doc.data()!;
      final business = (data['business'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _providerName = (business['businessName'] ?? data['providerName'] ?? '').toString();
      });
    } catch (_) {}
  }

  /// Generate every reasonable variant of the service name so we match
  /// regardless of how the provider typed it in Firestore.
  List<String> _serviceVariants() {
    final raw = widget.serviceName.trim();
    return <String>{
      raw,                                       // "Basic Package"
      raw.toLowerCase(),                         // "basic package"
      raw.toUpperCase(),                         // "BASIC PACKAGE"
      raw.toLowerCase().replaceAll(' ', '_'),    // "basic_package"
      raw.toLowerCase().replaceAll(' ', '-'),    // "basic-package"
      raw.toLowerCase().replaceAll(' ', ''),     // "basicpackage"
      raw.replaceAll(' ', '_'),                  // "Basic_Package"
      raw.replaceAll(' ', '-'),                  // "Basic-Package"
      raw.split(' ').first,                      // "Basic"
      raw.split(' ').first.toLowerCase(),        // "basic"
      raw.split(' ').last,                       // "Package"
      raw.split(' ').last.toLowerCase(),         // "package"
    }.toList();
  }

  bool _isMatch(String storedType) {
    final s        = storedType.trim();
    final rawLower = widget.serviceName.trim().toLowerCase();
    final sLower   = s.toLowerCase();
    // Exact match on any variant
    if (_serviceVariants().any((v) => v.toLowerCase() == sLower)) return true;
    // Partial / substring match as last resort
    return sLower.contains(rawLower) || rawLower.contains(sLower);
  }

  Future<void> _loadProvider() async {
    if (!mounted) return;
    setState(() { _isLoadingProvider = true; _noProviderMessage = null; });

    try {
      final variants = _serviceVariants();
      debugPrint('[Civil] searching variants: $variants');

      // Pass 1 – exact Firestore query per variant, with approved status
      for (final v in variants) {
        final snap = await FirebaseFirestore.instance
            .collection('providers')
            .where('serviceType', isEqualTo: v)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          debugPrint('[Civil] Pass1 matched "$v"');
          _setProvider(snap.docs.first.id, snap.docs.first.data()); return;
        }
      }

      // Pass 2 – same but ignore status filter (handles "Approved", "active", missing)
      for (final v in variants) {
        final snap = await FirebaseFirestore.instance
            .collection('providers')
            .where('serviceType', isEqualTo: v)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          debugPrint('[Civil] Pass2 (no-status) matched "$v"');
          _setProvider(snap.docs.first.id, snap.docs.first.data()); return;
        }
      }

      // Pass 3 – fetch ALL approved, fuzzy-match locally
      final approvedSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();
      final approvedMatch = approvedSnap.docs
          .where((d) => _isMatch((d.data()['serviceType'] ?? '').toString()))
          .firstOrNull;
      if (approvedMatch != null) {
        debugPrint('[Civil] Pass3 fuzzy approved: ${approvedMatch.id}');
        _setProvider(approvedMatch.id, approvedMatch.data()); return;
      }

      // Pass 4 – fetch EVERY provider (any status), fuzzy-match locally
      final allSnap = await FirebaseFirestore.instance.collection('providers').get();
      debugPrint('[Civil] total providers in DB: ${allSnap.docs.length}');
      for (final d in allSnap.docs) {
        debugPrint('  id=${d.id}  serviceType=${d.data()['serviceType']}  status=${d.data()['status']}');
      }
      final anyMatch = allSnap.docs
          .where((d) => _isMatch((d.data()['serviceType'] ?? '').toString()))
          .firstOrNull;
      if (anyMatch != null) {
        debugPrint('[Civil] Pass4 fuzzy any-status: ${anyMatch.id}');
        _setProvider(anyMatch.id, anyMatch.data()); return;
      }

      // Nothing matched — show helpful debug message
      if (mounted) {
        final stored = allSnap.docs
            .map((d) => '"${d.data()['serviceType'] ?? '–'}"')
            .toSet().join(', ');
        setState(() {
          _noProviderMessage =
              'No provider found for "${widget.serviceName}".\n'
              'Types in DB: $stored\n'
              'Check that a provider has registered and been approved for this service.';
          _isLoadingProvider = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[Civil] _loadProvider error: $e\n$stack');
      if (mounted) {
        setState(() {
          _noProviderMessage = 'Could not load provider.\nError: $e';
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
      _providerName      = (business['businessName'] ?? data['providerName'] ?? '').toString();
      _isLoadingProvider = false;
      _noProviderMessage = null;
    });
  }

  // ── Cart helpers ──────────────────────────────────────────────────────────
  List<CartItem> get _cartItems => widget.cart ?? [];
  bool           get _hasCartItems => _cartItems.isNotEmpty;
  int            get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price * (item.quantity));

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F1F8),
        body: _isSuccess ? _buildSuccessView() : _buildMainView(),
        bottomNavigationBar: _isSuccess ? null : _buildBottomBar(),
      ),
    );
  }

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

  Widget _buildLoadingState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: _accent),
      const SizedBox(height: 16),
      Text('Finding a provider…', style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );

  Widget _buildScrollBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      children: [
        if (_hasCartItems) ...[
          _stepLabel('📋', 'Booking Summary'),
          const SizedBox(height: 10),
          _buildBookingSummaryCard(),
          const SizedBox(height: 20),
        ],
        if (widget.selectedRenovationItems != null &&
            widget.selectedRenovationItems!.isNotEmpty) ...[
          _stepLabel('•', 'Your Selected Services'),
          const SizedBox(height: 10),
          _buildSelectedItemsCard(),
          const SizedBox(height: 20),
        ],
        _stepLabel('1', 'Your Details'),
        const SizedBox(height: 10),
        _buildDetailsCard(),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: _phoneComplete
              ? SlideTransition(
                  position: _revealSlide,
                  child: FadeTransition(
                    opacity: _revealFade,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 20),
                      _stepLabel('2', 'Schedule'),
                      const SizedBox(height: 10),
                      _buildDateTimeRow(),
                      const SizedBox(height: 20),
                      _stepLabel('3', 'Enquiry Summary'),
                      const SizedBox(height: 10),
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                    ]),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Booking summary card ──────────────────────────────────────────────────
  Widget _buildBookingSummaryCard() {
    final mq      = MediaQuery.of(context);
    final isSmall = mq.size.width < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.15)),
        boxShadow: [BoxShadow(blurRadius: 14, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_accent, _accent2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.serviceName,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 13 : 15),
                  overflow: TextOverflow.ellipsis),
              Text('${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'} in your enquiry',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: isSmall ? 11 : 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('₹$_cartTotal',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: isSmall ? 13 : 15)),
            ),
          ]),
        ),
        // Item rows
        Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 14),
          child: Column(children: [
            ..._cartItems.asMap().entries.map((e) => Column(children: [
              _buildCartItemRow(e.value, isSmall: isSmall),
              if (e.key < _cartItems.length - 1) Divider(height: 20, color: Colors.grey.shade100),
            ])),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 14, vertical: isSmall ? 10 : 12),
              decoration: BoxDecoration(color: _accent.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.currency_rupee_rounded, color: _accent, size: 16),
                const SizedBox(width: 6),
                const Expanded(child: Text('Estimated Total',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D2D3A)))),
                Text('₹$_cartTotal',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _accent)),
              ]),
            ),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(
                'Prices are indicative. Final quote confirmed by provider.',
                style: TextStyle(color: Colors.amber.shade800, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCartItemRow(CartItem item, {bool isSmall = false}) {
    final qty = item.quantity;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: isSmall ? 48 : 56, height: isSmall ? 48 : 56,
          color: Colors.grey.shade100,
          child: item.image != null
              ? Image.asset(item.image!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 22))
              : Icon(Icons.construction_rounded, color: _accent.withOpacity(0.4), size: 22),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 13 : 14,
                color: const Color(0xFF1A1A2E), height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Text('₹${item.price}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
          const Text(' / unit', style: TextStyle(color: Color(0xFF9E9EAF), fontSize: 11)),
        ]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _accent.withOpacity(0.09), borderRadius: BorderRadius.circular(20)),
          child: Text('x$qty', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 6),
        Text('₹${item.price * qty}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1A2E))),
      ]),
    ]);
  }

  // ── Selected renovation items card ────────────────────────────────────────
  Widget _buildSelectedItemsCard() {
    final items = widget.selectedRenovationItems!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.18)),
        boxShadow: [BoxShadow(blurRadius: 14, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accent, _accent2]),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.serviceName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E))),
            Text('${items.length} service${items.length > 1 ? 's' : ''} selected',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _accent.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
            child: Text('${items.length}',
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEEEEF5))),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withOpacity(0.20), width: 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, color: _accent.withOpacity(0.7), size: 13),
              const SizedBox(width: 5),
              Text(item, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final mq      = MediaQuery.of(context);
    final topPad  = mq.viewPadding.top > 0 ? 12.0 : 20.0;
    final isSmall = mq.size.height < 680;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, isSmall ? 18 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          if (_providerName != null && _providerName!.isNotEmpty)
            Flexible(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.storefront_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 5),
                Flexible(child: Text(_providerName!, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
              ]),
            )),
        ]),
        SizedBox(height: isSmall ? 12 : 18),
        const Text('Submit Enquiry',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Row(children: [
          Flexible(child: Text(widget.serviceName, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13))),
          if (_hasCartItems) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
              child: Text('${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'} · ₹$_cartTotal',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ]),
    );
  }

  // ── No provider state ─────────────────────────────────────────────────────
  Widget _buildNoProviderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.store_mall_directory_outlined, size: 52, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(_noProviderMessage ?? 'No provider available',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProvider,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ]),
      ),
    );
  }

  // ── Step label ────────────────────────────────────────────────────────────
  Widget _stepLabel(String number, String label) {
    final isEmoji = number == '📋';
    final isBullet = number == '•';
    return Row(children: [
      isEmoji
          ? SizedBox(width: 28, height: 28,
              child: Center(child: Text(number, style: const TextStyle(fontSize: 16))))
          : Container(
              width: 28, height: 28, alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isBullet
                    ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)])
                    : const LinearGradient(colors: [_accent, _accent2]),
                shape: BoxShape.circle,
              ),
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
      const SizedBox(width: 10),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), letterSpacing: -0.2))),
    ]);
  }

  // ── Details card ──────────────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return _card(child: Column(children: [
      _field(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline_rounded),
      const SizedBox(height: 14),
      _field(
        controller: _phoneController, hint: 'Mobile Number (10 digits)',
        icon: Icons.phone_outlined, keyboard: TextInputType.phone, focusNode: _phoneFocus,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        suffix: _phoneComplete ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20) : null,
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: !_phoneComplete
            ? Padding(
                key: const ValueKey('hint'),
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('Enter 10-digit phone to continue',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ]))
            : const SizedBox.shrink(key: ValueKey('no-hint')),
      ),
      const SizedBox(height: 14),
      _field(controller: _addressController, hint: 'Project Address', icon: Icons.location_on_outlined, maxLines: 3),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _isGettingLocation ? null : _getCurrentLocation,
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent, side: const BorderSide(color: _accent, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isGettingLocation
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
              : const Icon(Icons.my_location_rounded, size: 17),
          label: Text(_isGettingLocation ? 'Detecting…' : 'GPS',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: _openMapPicker,
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent, side: const BorderSide(color: _accent, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.map_outlined, size: 17),
          label: const Text('Pick on Map', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        )),
      ]),
      const SizedBox(height: 14),
      _field(controller: _noteController, hint: 'Describe your requirement (optional)',
          icon: Icons.notes_rounded, maxLines: 3),
    ]));
  }

  // ── Date / time row ───────────────────────────────────────────────────────
  Widget _buildDateTimeRow() => Row(children: [
    Expanded(child: _pickerTile(
      icon: Icons.calendar_month_rounded, label: 'Preferred Date',
      value: _selectedDate == null ? 'Tap to select' : DateFormat('dd MMM yyyy').format(_selectedDate!),
      selected: _selectedDate != null, onTap: _pickDate,
    )),
    const SizedBox(width: 12),
    Expanded(child: _pickerTile(
      icon: Icons.access_time_rounded, label: 'Preferred Time',
      value: _selectedTime == null ? 'Tap to select' : _selectedTime!.format(context),
      selected: _selectedTime != null, onTap: _pickTime,
    )),
  ]);

  Widget _pickerTile({required IconData icon, required String label, required String value,
      required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _accent.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _accent.withOpacity(0.5) : Colors.grey.shade200, width: 1.5),
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.04))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: selected ? _accent.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: selected ? _accent : Colors.grey.shade500, size: 17),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: selected ? _accent : Colors.grey.shade400,
              fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    );
  }

  // ── Summary card (Step 3) ─────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final hasCartItems  = _hasCartItems;
    final hasRenovItems = widget.selectedRenovationItems?.isNotEmpty ?? false;

    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, _accent2]),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.construction_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.serviceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(
            hasCartItems
                ? '${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'} · ₹$_cartTotal'
                : hasRenovItems
                    ? '${widget.selectedRenovationItems!.length} services selected'
                    : 'Enquiry — no upfront payment',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ])),
      ]),
      if (hasCartItems) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F5FF), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ITEMS BOOKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                color: Colors.grey.shade500, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ..._cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 1, right: 8),
                    decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
                Expanded(child: Text(item.name,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D3A), height: 1.3))),
                const SizedBox(width: 8),
                Text('₹${item.price * (item.quantity)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _accent)),
              ]),
            )),
            const Divider(height: 14, color: Color(0xFFDDDDF5)),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              Text('₹$_cartTotal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _accent)),
            ]),
          ]),
        ),
      ],
      if (!hasCartItems && hasRenovItems) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF5F5FF), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Included services', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.grey.shade500, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...widget.selectedRenovationItems!.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(top: 5), width: 5, height: 5,
                    decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(item,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D3A), height: 1.4))),
              ]),
            )),
          ]),
        ),
      ],
      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: _accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withOpacity(0.18), width: 1)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 16, color: _accent.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'A provider will contact you with a quote after reviewing your enquiry.',
            style: TextStyle(color: _accent.withOpacity(0.8), fontSize: 12, height: 1.4),
          )),
        ]),
      ),
    ]));
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final mq         = MediaQuery.of(context);
    final canProceed = !_isLoading && !_isLoadingProvider && _providerId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18,
          mq.viewInsets.bottom > 0 ? 8 : mq.viewPadding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 18, color: Colors.black.withOpacity(0.07))],
      ),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildStepProgress(),
        const SizedBox(height: 12),
        if (_hasCartItems)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _accent.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded, color: _accent, size: 15),
              const SizedBox(width: 8),
              Text('${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const Spacer(),
              Text('Total: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text('₹$_cartTotal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _accent)),
            ]),
          ),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: canProceed && _phoneComplete ? _validateAndSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.send_rounded, size: 17),
                    SizedBox(width: 10),
                    Text('Submit Enquiry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
          ),
        ),
      ])),
    );
  }

  Widget _buildStepProgress() {
    final step1 = _nameController.text.isNotEmpty && _phoneComplete && _addressController.text.isNotEmpty;
    final step2 = _selectedDate != null && _selectedTime != null;
    return Row(children: [
      _progressDot(done: _phoneComplete, label: 'Details'),
      _progressLine(done: _phoneComplete),
      _progressDot(done: step1 && step2, label: 'Schedule'),
      _progressLine(done: step1 && step2),
      _progressDot(done: false, label: 'Submit'),
    ]);
  }

  Widget _progressDot({required bool done, required String label}) => Expanded(
    child: Column(children: [
      AnimatedContainer(duration: const Duration(milliseconds: 300),
          width: 10, height: 10,
          decoration: BoxDecoration(color: done ? _accent : Colors.grey.shade300, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10,
          color: done ? _accent : Colors.grey.shade400,
          fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
    ]),
  );

  Widget _progressLine({required bool done}) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: 2, width: 32,
    color: done ? _accent : Colors.grey.shade200,
  );

  // ── Success view ──────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Enquiry Submitted!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Text('ID: $_enquiryId',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'monospace')),
            ),
            if (_hasCartItems) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withOpacity(0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR ORDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: _accent, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ..._cartItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(child: Text(item.name,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D3A)))),
                      Text('₹${item.price * (item.quantity)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _accent, fontSize: 13)),
                    ]),
                  )),
                  const Divider(color: Color(0xFFDDDDF5)),
                  Row(children: [
                    const Expanded(child: Text('Total',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Text('₹$_cartTotal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _accent)),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            Text('We will contact you shortly with a quote and confirm your visit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.6)),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _goHome() {
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => BottomNavPage(
        userPhone: user?.phoneNumber ?? _phoneController.text,
        userEmail: user?.email ?? '',
      )),
      (_) => false,
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now(), lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _accent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location services are disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever)
        throw Exception('Location permission permanently denied. Enable it in Settings.');

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;

      if (!mounted) return;
      _addressController.text =
          '${place.street ?? ''}, ${place.locality ?? ''}, '
          '${place.administrativeArea ?? ''} ${place.postalCode ?? ''}'
              .replaceAll(RegExp(r',\s*,'), ',').trim();
      setState(() => _pickedLatLng = LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (!mounted) return;
      _showSnack('$e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // ── Map picker ────────────────────────────────────────────────────────────
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => MapPickerPage(initialLatLng: _pickedLatLng)),
    );
    if (result == null || !mounted) return;
    setState(() => _pickedLatLng = result.latLng);
    _addressController.text = result.addressDetails.isNotEmpty
        ? '${result.addressDetails}, ${result.fullAddress}'
        : result.fullAddress;
  }

  // ── Validate & submit ─────────────────────────────────────────────────────
  void _validateAndSubmit() {
    if (_providerId == null || _providerId!.isEmpty) { _showSnack('No provider available for this service.'); return; }
    if (_nameController.text.trim().isEmpty)          { _showSnack('Please enter your name.'); return; }
    if (_phoneController.text.trim().length < 10)     { _showSnack('Please enter a valid 10-digit phone number.'); return; }
    if (_addressController.text.trim().isEmpty)       { _showSnack('Please enter your project address.'); return; }
    if (_selectedDate == null || _selectedTime == null) { _showSnack('Please select your preferred date and time.'); return; }
    _save();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      final List<String> servicesList = _hasCartItems
          ? _cartItems.map((e) => e.name).toList()
          : (widget.selectedRenovationItems?.isNotEmpty ?? false)
              ? widget.selectedRenovationItems!
              : [widget.serviceName];

      final docRef = await OrderService.placeOrder(
        serviceType:   widget.serviceName.trim().toLowerCase(),
        services:      servicesList,
        userId:        user?.uid ?? '',
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user?.email ?? '',
        address:       _addressController.text.trim(),
        note:          _noteController.text.trim(),
        date:          _selectedDate!,
        time:          _selectedTime!.format(context),
        totalAmount:   _cartTotal.toDouble(),
        createdBy:     user?.uid ?? '',
        createdByRole: 'user',
        providerId:    _providerId!,
        providerName:  _providerName ?? '',
        visitType:     'Site Visit',
        isEnquiry:     true,
      );

      if (!mounted) return;
      setState(() { _enquiryId = docRef.id; _isSuccess = true; _isLoading = false; });
    } catch (e) {
      debugPrint('[Civil] save error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Could not submit enquiry: $e');
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
  ));

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 5), color: Colors.black.withOpacity(0.05))],
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
        decoration: BoxDecoration(color: const Color(0xFFF5F6FC), borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: controller, keyboardType: keyboard,
          maxLines: maxLines, focusNode: focusNode,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: _accent, size: 19),
            suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      );
}