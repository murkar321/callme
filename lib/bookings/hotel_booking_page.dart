import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    with SingleTickerProviderStateMixin {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController  = TextEditingController();

  DateTime?   _selectedDate;
  TimeOfDay?  _selectedTime;
  int         _selectedSuiteIndex = 0; // default → Standard Room

  bool _isLoading         = false;
  bool _isLoadingProvider = true;

  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;


  // ── Cart / price helpers ──────────────────────────────────────────────────

  List<CartItem> get _cartItems => Cart.getItems('Hotel');

  _SuiteType get _selectedSuite => _kSuiteTypes[_selectedSuiteIndex];

  double get _baseAmount {
    if (_cartItems.isNotEmpty) return Cart.getTotal('Hotel').toDouble();
    final price    = widget.hotel.price.toDouble();
    final discount = widget.hotel.discount.toDouble();
    return price - (price * discount / 100);
  }

  double get _totalAmount => _baseAmount * _selectedSuite.priceMultiplier;

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

    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    final hint = widget.initialProviderId?.isNotEmpty == true
        ? widget.initialProviderId
        : widget.providerId.isNotEmpty
            ? widget.providerId
            : null;

    if (hint != null) {
      _providerId        = hint;
      _isLoadingProvider = false;
      _fetchProviderName(hint);
    } else {
      _loadProvider();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Provider loader ───────────────────────────────────────────────────────

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
        _providerName =
            (business['businessName'] ?? data['providerName'] ?? '').toString();
      });
    } catch (_) {}
  }

  Future<void> _loadProvider() async {
    setState(() {
      _isLoadingProvider = true;
      _noProviderMessage = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: 'hotel')
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
        return st == 'hotel';
      }).firstOrNull;

      if (match != null) {
        _setProvider(match.id, match.data());
      } else {
        if (mounted) {
          setState(() {
            _noProviderMessage =
                'No approved hotel provider available yet.\nPlease try again later.';
            _isLoadingProvider = false;
          });
        }
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
      _providerId        = id;
      _providerName      =
          (business['businessName'] ?? data['providerName'] ?? '').toString();
      _isLoadingProvider = false;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
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
      ),
      bottomNavigationBar:
          (!_isLoadingProvider && _noProviderMessage == null)
              ? _buildBottomBar()
              : null,
    );
  }

  // ── Loading / no provider ─────────────────────────────────────────────────

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepPurple),
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
                  backgroundColor: Colors.deepPurple,
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

  // ── Scroll body ───────────────────────────────────────────────────────────

  Widget _buildScrollBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad        = screenWidth < 400 ? 12.0 : 16.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroHeader(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Column(
            children: [
              _buildHotelInfoCard(),
              const SizedBox(height: 14),
              _buildSuiteSelectionCard(),   // ← NEW
              const SizedBox(height: 14),
              _buildBookingSummary(),
              const SizedBox(height: 14),
              _buildScheduleCard(),
              const SizedBox(height: 14),
              _buildGuestCard(),
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
    return Stack(
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
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        if (_providerName != null && _providerName!.isNotEmpty)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
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
          child: Text(
            widget.hotel.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hotel info card ───────────────────────────────────────────────────────

  Widget _buildHotelInfoCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hotel.city,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  widget.hotel.location,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.hotel.discount > 0) ...[
                Text(
                  '₹${widget.hotel.originalPrice}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${widget.hotel.discount}% off',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
              Text(
                '₹${_baseAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'base / night',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Suite Selection Card (NEW) ────────────────────────────────────────────

  Widget _buildSuiteSelectionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bed_rounded,
                    color: Colors.deepPurple, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Room / Suite Type',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._kSuiteTypes.asMap().entries.map(
            (entry) => _buildSuiteTile(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildSuiteTile(int index, _SuiteType suite) {
    final selected  = index == _selectedSuiteIndex;
    final tilePrice = (_baseAmount * suite.priceMultiplier);

    return GestureDetector(
      onTap: () => setState(() => _selectedSuiteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.deepPurple.withOpacity(0.07)
              : const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.deepPurple.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                suite.icon,
                size: 20,
                color: selected ? Colors.deepPurple : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 12),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suite.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected
                          ? Colors.deepPurple.shade700
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suite.description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${tilePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: selected
                        ? Colors.deepPurple
                        : Colors.black87,
                  ),
                ),
                if (suite.priceMultiplier != 1.0)
                  Text(
                    '×${suite.priceMultiplier}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.deepPurple
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: selected ? Colors.deepPurple : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking summary ───────────────────────────────────────────────────────

  Widget _buildBookingSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty) ...[
            _summaryRow(widget.hotel.name, _baseAmount),
            _summaryRow(
              'Suite: ${_selectedSuite.name}',
              _totalAmount - _baseAmount,
              prefix: '+',
              color: Colors.deepPurple.shade300,
            ),
          ] else ...[
            ..._cartItems.map(
              (e) => _summaryRow(
                '${e.name} × ${e.quantity}',
                (e.price * e.quantity).toDouble(),
              ),
            ),
            _summaryRow(
              'Suite: ${_selectedSuite.name}',
              _totalAmount - _baseAmount,
              prefix: '+',
              color: Colors.deepPurple.shade300,
            ),
          ],
          const Divider(height: 20),
          _summaryRow('Total', _totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool bold = false,
    String prefix = '',
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '$prefix₹${amount.toStringAsFixed(0)}',
            style: style,
          ),
        ],
      ),
    );
  }

  // ── Schedule card ─────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    return _card(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _iconBox(Icons.calendar_month),
            title: Text(
              _selectedDate == null
                  ? 'Select Check-In Date'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null
                    ? Colors.grey.shade500
                    : Colors.black87,
                fontWeight: _selectedDate != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _iconBox(Icons.access_time),
            title: Text(
              _selectedTime == null
                  ? 'Select Check-In Time'
                  : _selectedTime!.format(context),
              style: TextStyle(
                color: _selectedTime == null
                    ? Colors.grey.shade500
                    : Colors.black87,
                fontWeight: _selectedTime != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.deepPurple),
      );

  // ── Guest details card ────────────────────────────────────────────────────

  Widget _buildGuestCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Guest Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 16),
          _inputField(
              _nameController, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _inputField(
            _phoneController,
            'Phone Number',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _inputField(
            _noteController,
            'Special Request (optional)',
            Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final canBook = !_isLoading && _providerId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.07)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSuite.name,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canBook ? _continueToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.deepPurple.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Book Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Payment + order flow ──────────────────────────────────────────────────

  Future<void> _continueToPayment() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showPopup('Please fill your name and phone number', false);
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
      _showPopup(
          'Hotel provider information missing. Please try again.', false);
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName:
              'Hotel Booking — ${widget.hotel.name} (${_selectedSuite.name})',
          amount: _totalAmount.toInt(),
        ),
      ),
    );

    if (result != true && result != 'offline') return;

    setState(() => _isLoading = true);
    try {
      await OrderService.placeOrder(
        serviceType:   'hotel',
        services:      _servicesForOrder,
        userId:        user.uid,
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user.email ?? '',
        createdBy:     user.uid,
        createdByRole: 'user',
        address:
            'Hotel — ${widget.hotel.name}, ${widget.hotel.city}',
        note: _noteController.text.trim(),
        date: _selectedDate!,
        time: _selectedTime!.format(context),
        totalAmount:  _totalAmount,
        visitType:    'Hotel',
        providerId:   _providerId!,
        isEnquiry:    false,
        providerName: _providerName ?? '',
      );

      Cart.clear('Hotel');

      if (!mounted) return;
      _showPopup(
        result == 'offline'
            ? 'Booking Placed Successfully!'
            : 'Payment Successful!\nBooking Confirmed.',
        true,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: _phoneController.text.trim(),
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
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Colors.deepPurple),
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
          colorScheme:
              const ColorScheme.light(primary: Colors.deepPurple),
        ),
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
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: success ? Colors.green : Colors.red,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
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

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: child,
      );

  Widget _inputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.deepPurple),
          ),
        ),
      );
}