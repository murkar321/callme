import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:callme/data/hotel_data.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';

// ─── Suite types ─────────────────────────────────────────────────────────────

class _SuiteType {
  final String name;
  final String description;
  final IconData icon;
  final double priceMultiplier; // multiplied against base price

  const _SuiteType({
    required this.name,
    required this.description,
    required this.icon,
    required this.priceMultiplier,
  });
}

const List<_SuiteType> _kSuiteTypes = [
  _SuiteType(
    name: 'Standard Room',
    description: 'Comfortable room with essential amenities',
    icon: Icons.hotel_outlined,
    priceMultiplier: 1.0,
  ),
  _SuiteType(
    name: 'Deluxe Room',
    description: 'Spacious room with upgraded furnishings & city view',
    icon: Icons.king_bed_outlined,
    priceMultiplier: 1.4,
  ),
  _SuiteType(
    name: 'Junior Suite',
    description: 'Separate sitting area, premium amenities',
    icon: Icons.weekend_outlined,
    priceMultiplier: 1.85,
  ),
  _SuiteType(
    name: 'Executive Suite',
    description: 'Full living room, private dining & butler service',
    icon: Icons.business_center_outlined,
    priceMultiplier: 2.5,
  ),
];

// ─── Design tokens (matches booking_page.dart) ───────────────────────────────

const _kAccent     = Color(0xFF5B4FCF);
const _kAccentSoft = Color(0xFF7B6FE8);
const _kBg         = Color(0xFFF4F3FB);
const _kCard       = Colors.white;
const _kSuccess    = Color(0xFF34C759);

// ─── Page ────────────────────────────────────────────────────────────────────

class HotelBookingPage extends StatefulWidget {
  final HotelData hotel;
  final List<dynamic> products;

  /// Caller may pass a pre-resolved provider ID to skip the Firestore lookup.
  final String? initialProviderId;

  /// Legacy param — treated as initialProviderId when initialProviderId is null.
  final String providerId;

  const HotelBookingPage({
    super.key,
    required this.hotel,
    required this.products,
    this.providerId = '',
    this.initialProviderId,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedSuiteIndex = 0; // default → Standard Room

  bool _isLoading = false;
  bool _isLoadingProvider = true;
  bool _summaryExpanded = true;

  // FIX: same 10-digit "complete" tracking pattern as booking_page.dart's
  // _phoneComplete — drives the inline checkmark and lets validation give
  // a specific "enter a valid 10-digit number" message instead of lumping
  // name+phone into one generic "fill your details" error.
  bool _phoneComplete = false;

  /// True only when the caller explicitly resolved a specific provider
  /// (e.g. navigated here from that provider's own profile page). This is
  /// the ONLY case where we should force direct assignment instead of
  /// letting placeOrder() fan the order out to every matching provider.
  bool get _isPinnedProvider =>
      (widget.initialProviderId?.isNotEmpty == true) ||
      widget.providerId.isNotEmpty;

  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  late final AnimationController _revealAnim;
  late final Animation<double> _revealFade;
  late final Animation<Offset> _revealSlide;

  // ── Cart / price helpers ──────────────────────────────────────────────────

  List<CartItem> get _cartItems => Cart.getItems('Hotel');

  _SuiteType get _selectedSuite => _kSuiteTypes[_selectedSuiteIndex];

  double get _baseAmount {
    if (_cartItems.isNotEmpty) return Cart.getTotal('Hotel').toDouble();
    final price = widget.hotel.price.toDouble();
    final discount = widget.hotel.discount.toDouble();
    return price - (price * discount / 100);
  }

  double get _totalAmount => _baseAmount * _selectedSuite.priceMultiplier;

  static const String _kServiceType = 'hotel';

  /// MAIN category the order is matched against provider `categories[]` /
  /// `subCategories[]` on. For a cart checkout we defer to whatever
  /// category the cart items already carry (set on the resort/hotel
  /// listing page); for a direct hotel + suite booking we use the
  /// selected suite type, since that's what hotel providers register
  /// against (Standard Room / Deluxe Room / Junior Suite / Executive Suite).
  String get _category {
    if (_cartItems.isNotEmpty) {
      return resolveCanonicalCategory(_cartItems.first.category, _kServiceType);
    }
    return resolveCanonicalCategory(_selectedSuite.name, _kServiceType);
  }

  /// The SPECIFIC item — the hotel/resort itself for a direct booking,
  /// or the single cart item name when there's exactly one.
  String get _subCategory {
    if (_cartItems.length == 1) {
      return resolveCanonicalCategory(_cartItems.first.name, _kServiceType);
    }
    if (_cartItems.isEmpty) {
      return resolveCanonicalCategory(widget.hotel.name, _kServiceType);
    }
    return '';
  }

  List<String> get _servicesForOrder {
    final suiteLabel = _selectedSuite.name;
    if (_cartItems.isNotEmpty) {
      return [
        ..._cartItems.map((e) => '${e.name} x${e.quantity}'),
        'Suite: $suiteLabel',
      ];
    }
    return ['${widget.hotel.name} — $suiteLabel'];
  }

  // ── Init / dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _revealAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealAnim, curve: Curves.easeOutCubic));
    _revealFade = CurvedAnimation(parent: _revealAnim, curve: Curves.easeOut);

    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    // FIX: track phone-complete state (10 digits) live, same as
    // booking_page.dart, and seed it correctly if auth pre-filled a full
    // number above.
    _phoneComplete = _phoneController.text.trim().length == 10;
    if (_phoneComplete) _revealAnim.forward();
    _phoneController.addListener(_onPhoneChanged);

    final hint = widget.initialProviderId?.isNotEmpty == true
        ? widget.initialProviderId
        : widget.providerId.isNotEmpty
            ? widget.providerId
            : null;

    if (hint != null) {
      _providerId = hint;
      _isLoadingProvider = false;
      _fetchProviderName(hint);
    } else {
      _loadProvider();
    }
  }

  void _onPhoneChanged() {
    final done = _phoneController.text.trim().length == 10;
    if (done != _phoneComplete) {
      setState(() => _phoneComplete = done);
      done ? _revealAnim.forward() : _revealAnim.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _revealAnim.dispose();
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Provider loader ───────────────────────────────────────────────────────

  Future<void> _fetchProviderName(String id) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('providers').doc(id).get();
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      final business = (data['business'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _providerName =
            (business['businessName'] ?? data['providerName'] ?? '').toString();
      });
    } catch (_) {}
  }

  /// Finds the best approved 'hotel' provider whose registered
  /// categories/subCategories match what's actually being booked — run
  /// through the exact same categoryMatchFuzzy() pipeline placeOrder()'s
  /// fan-out uses, so this preview agrees with who really gets notified.
  Future<void> _loadProvider() async {
    setState(() {
      _isLoadingProvider = true;
      _noProviderMessage = null;
    });
    try {
      final syntheticOrderData = <String, dynamic>{
        'category': _category,
        'subCategory': _subCategory,
        'services': _servicesForOrder,
        'serviceType': _kServiceType,
      };

      final approvedSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? svcOnlyMatch;
      QueryDocumentSnapshot<Map<String, dynamic>>? categoryMatchDoc;
      QueryDocumentSnapshot<Map<String, dynamic>>? unrestrictedLegacy;

      for (final doc in approvedSnap.docs) {
        final data = doc.data();

        final docSvc = providerServiceType(data);
        if (docSvc.isEmpty ||
            normalizeServiceType(docSvc) != normalizeServiceType(_kServiceType)) {
          continue;
        }

        svcOnlyMatch ??= doc;

        final cats = providerCategories(data);
        final subCats = providerSubCategories(data);

        if (cats.isEmpty && subCats.isEmpty) {
          unrestrictedLegacy ??= doc;
          continue;
        }

        if (categoryMatchDoc == null &&
            categoryMatchFuzzy(syntheticOrderData, cats,
                providerSubCats: subCats)) {
          categoryMatchDoc = doc;
        }
      }

      final best = categoryMatchDoc ?? unrestrictedLegacy ?? svcOnlyMatch;

      if (best != null) {
        _setProvider(best.id, best.data());
      } else if (mounted) {
        setState(() {
          _noProviderMessage =
              'No approved hotel provider available yet.\nPlease try again later.';
          _isLoadingProvider = false;
        });
      }
    } catch (e) {
      debugPrint('[HotelBookingPage] _loadProvider error: $e');
      if (mounted) {
        setState(() {
          _noProviderMessage =
              'Could not load provider. Check your connection and try again.';
          _isLoadingProvider = false;
        });
      }
    }
  }

  void _setProvider(String id, Map<String, dynamic> data) {
    if (!mounted) return;
    final business = (data['business'] as Map<String, dynamic>?) ?? {};
    setState(() {
      _providerId = id;
      _providerName =
          (business['businessName'] ?? data['providerName'] ?? '').toString();
      _isLoadingProvider = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeIn,
          child: _isLoadingProvider
              ? _buildLoadingState()
              : _noProviderMessage != null
                  ? _buildNoProviderState()
                  : _buildScrollBody(),
        ),
      ),
      bottomNavigationBar: (!_isLoadingProvider && _noProviderMessage == null)
          ? _buildBottomBar()
          : null,
    );
  }

  // ── Loading / no provider ─────────────────────────────────────────────────

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kAccent),
            const SizedBox(height: 16),
            Text('Finding a hotel provider…',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );

  Widget _buildNoProviderState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.hotel_outlined,
                    size: 52, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                _noProviderMessage ?? 'No provider available',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProvider,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  // ── Scroll body — ordered flow:
  //    Hero → Summary → (1) Suite → (2) Guest details → (3) Schedule ────────

  Widget _buildScrollBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 400 ? 12.0 : 16.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroHeader(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),

              _StepHeader(number: 1, label: 'Choose Room / Suite'),
              const SizedBox(height: 10),
              _buildSuiteSelectionCard(),
              const SizedBox(height: 20),

              _StepHeader(number: 2, label: 'Guest Details'),
              const SizedBox(height: 10),
              _buildGuestCard(),

              AnimatedSize(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                child: _phoneComplete
                    ? SlideTransition(
                        position: _revealSlide,
                        child: FadeTransition(
                          opacity: _revealFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _StepHeader(
                                  number: 3, label: 'Check-In Date & Time'),
                              const SizedBox(height: 10),
                              _buildScheduleCard(),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    final heroH = MediaQuery.of(context).size.height * 0.30;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          SizedBox(
            height: heroH.clamp(200.0, 300.0),
            width: double.infinity,
            child: Image.asset(widget.hotel.image, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.black87, size: 18),
              ),
            ),
          ),
          if (_isPinnedProvider &&
              _providerName != null &&
              _providerName!.isNotEmpty)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.35,
                      ),
                      child: Text(
                        _providerName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.hotel.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient summary card (mirrors booking_page.dart's services card) ───

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccent, _kAccentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Text('Your Booking',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('₹${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _summaryExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _summaryExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        if (_cartItems.isEmpty) ...[
                          _summaryLine(widget.hotel.name, _baseAmount),
                          _summaryLine(
                            'Suite: ${_selectedSuite.name}',
                            _totalAmount - _baseAmount,
                            prefix: '+',
                          ),
                        ] else ...[
                          ..._cartItems.map(
                            (e) => _summaryLine(
                              '${e.name} x${e.quantity}',
                              (e.price * e.quantity).toDouble(),
                            ),
                          ),
                          _summaryLine(
                            'Suite: ${_selectedSuite.name}',
                            _totalAmount - _baseAmount,
                            prefix: '+',
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text('₹${_totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String name, double price, {String prefix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.white54, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Text('$prefix₹${price.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ── Step 1 — Suite Selection Card ─────────────────────────────────────────

  Widget _buildSuiteSelectionCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kSuiteTypes
            .asMap()
            .entries
            .map((e) => _buildSuiteTile(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _buildSuiteTile(int index, _SuiteType suite) {
    final selected = index == _selectedSuiteIndex;
    final tilePrice = (_baseAmount * suite.priceMultiplier);
    final isLast = index == _kSuiteTypes.length - 1;

    return GestureDetector(
      onTap: () => setState(() => _selectedSuiteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.07) : const Color(0xFFF3F2FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected
                    ? _kAccent.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                suite.icon,
                size: 20,
                color: selected ? _kAccent : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suite.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? _kAccent : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suite.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${tilePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: selected ? _kAccent : Colors.black87,
                  ),
                ),
                if (suite.priceMultiplier != 1.0)
                  Text(
                    '×${suite.priceMultiplier}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kAccent : Colors.grey.shade300,
                  width: 2,
                ),
                color: selected ? _kAccent : Colors.transparent,
              ),
              child:
                  selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 — Guest details card ───────────────────────────────────────────

  Widget _buildGuestCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // FIX: digitsOnly + 10-digit hard cap via inputFormatters (same
          // as booking_page.dart's phone field), plus a live check-mark
          // suffix once 10 digits are entered.
          _Field(
            controller: _phoneController,
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            suffix: _phoneComplete
                ? const Icon(Icons.check_circle_rounded,
                    color: _kSuccess, size: 20)
                : null,
          ),
          if (!_phoneComplete) ...[
            const SizedBox(height: 6),
            _hintRow('Enter a 10-digit mobile number'),
          ],
          const SizedBox(height: 12),
          _Field(
            controller: _noteController,
            hint: 'Special Request (optional)',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _hintRow(String text) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ],
    );
  }

  // ── Step 3 — Schedule card ────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        final dateTile = _PickerTile(
          icon: Icons.calendar_month_rounded,
          label: 'Check-In Date',
          value: _selectedDate == null
              ? 'Tap to pick'
              : DateFormat('dd MMM yyyy').format(_selectedDate!),
          selected: _selectedDate != null,
          onTap: _pickDate,
        );
        final timeTile = _PickerTile(
          icon: Icons.access_time_rounded,
          label: 'Check-In Time',
          value:
              _selectedTime == null ? 'Tap to pick' : _selectedTime!.format(context),
          selected: _selectedTime != null,
          onTap: _pickTime,
        );

        if (narrow) {
          return Column(
            children: [
              dateTile,
              const SizedBox(height: 12),
              timeTile,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: dateTile),
            const SizedBox(width: 12),
            Expanded(child: timeTile),
          ],
        );
      },
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final canBook = !_isLoading && _providerId != null;
    final step1Done = _phoneComplete;
    final step2Done = _selectedDate != null && _selectedTime != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressRow(step1: step1Done, step2: step1Done && step2Done),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canBook ? _continueToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  disabledBackgroundColor: const Color(0xFFD0CBEE),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Book Now',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('₹${_totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
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

  // ── Payment + order flow ──────────────────────────────────────────────────

  Future<void> _continueToPayment() async {
    // FIX: split into specific checks (name / phone-digit-count / date+time
    // / provider) instead of one combined "fill your details" message —
    // matches booking_page.dart's _validateAndPay() flow so the person
    // knows exactly which field needs fixing.
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showPopup('Please enter your name', false);
      return;
    }
    if (phone.length != 10) {
      _showPopup('Enter a valid 10-digit phone number', false);
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showPopup('Please select check-in date and time', false);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showPopup('Please log in first', false);
      return;
    }
    if (_providerId == null || _providerId!.isEmpty) {
      _showPopup('Hotel provider information missing. Please try again.', false);
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: 'Hotel Booking — ${widget.hotel.name} (${_selectedSuite.name})',
          amount: _totalAmount.toInt(),
        ),
      ),
    );

    if (result != true && result != 'offline') return;

    setState(() => _isLoading = true);
    try {
      await OrderService.placeOrder(
        serviceType: _kServiceType,
        services: _servicesForOrder,
        userId: user.uid,
        userName: name,
        phone: phone,
        email: user.email ?? '',
        createdBy: user.uid,
        createdByRole: 'user',
        address: 'Hotel — ${widget.hotel.name}, ${widget.hotel.city}',
        note: _noteController.text.trim(),
        date: _selectedDate!,
        time: _selectedTime!.format(context),
        totalAmount: _totalAmount,
        visitType: 'Hotel',

        // Properly canonicalized category/subCategory so the provider's
        // dashboard "Available" tab and the push-notification fan-out both
        // match this order against the correct registered categories —
        // same fix pattern as booking_page.dart.
        category: _category,
        subCategory: _subCategory,

        // Only pin a specific provider when the caller explicitly resolved
        // one (e.g. navigated here from that provider's profile). Otherwise
        // leave providerId null so placeOrder() fans the order out to every
        // approved hotel provider whose categories/subCategories match —
        // instead of silently notifying only whoever _loadProvider()'s
        // preview search happened to land on.
        providerId: _isPinnedProvider ? _providerId : null,
        isEnquiry: false,
        providerName: _isPinnedProvider ? (_providerName ?? '') : '', itemBreakdown: [], subCategories: [],
      );

      Cart.clear('Hotel');

      if (!mounted) return;
      _showPopup(
        result == 'offline' ? 'Booking Placed Successfully!' : 'Payment Successful!\nBooking Confirmed.',
        true,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: phone,
            userEmail: user.email ?? '',
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint('[HotelBookingPage] placeOrder error: $e');
      _showPopup('Something went wrong. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kAccent)),
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
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kAccent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Popup ─────────────────────────────────────────────────────────────────

  void _showPopup(String message, bool success) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !success,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: success ? _kSuccess.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: success ? _kSuccess : Colors.red,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
    if (!success) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }
}

// ─── Reusable UI pieces (match booking_page.dart) ────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;
  final List<TextInputFormatter>? formatters;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
    this.formatters,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: formatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: _kAccent, size: 20),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kAccent.withOpacity(0.5) : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.04)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? _kAccent.withOpacity(0.12) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? _kAccent : Colors.grey.shade400, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: selected ? _kAccent : Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final bool step1;
  final bool step2;

  const _ProgressRow({required this.step1, required this.step2});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(done: step1, label: 'Details'),
        _line(done: step1),
        _dot(done: step2, label: 'Schedule'),
        _line(done: step2),
        _dot(done: false, label: 'Payment'),
      ],
    );
  }

  Widget _dot({required bool done, required String label}) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: done ? _kAccent : const Color(0xFFDDDAF5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: done ? _kAccent : Colors.grey.shade400,
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _line({required bool done}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      width: 36,
      color: done ? _kAccent : const Color(0xFFE8E6F7),
    );
  }
}

// ─── Step header (matches booking_page.dart's step style) ───────────────────

class _StepHeader extends StatelessWidget {
  final int number;
  final String label;

  const _StepHeader({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kAccent, _kAccentSoft]),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ],
    );
  }
}