import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/hotel_data.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';

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

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading         = false;
  bool _isLoadingProvider = true;

  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  // ── Cart helpers ────────────────────────────────────────────────────────────

  List<CartItem> get _cartItems => Cart.getItems('Hotel');

  double get _totalAmount {
    if (_cartItems.isNotEmpty) return Cart.getTotal('Hotel').toDouble();
    final price    = widget.hotel.price.toDouble();
    final discount = widget.hotel.discount.toDouble();
    return price - (price * discount / 100);
  }

  /// Use the hotel name as the service label (category getter removed)
  List<String> get _servicesForOrder {
    if (_cartItems.isNotEmpty) {
      return _cartItems.map((e) => '${e.name} x${e.quantity}').toList();
    }
    return [widget.hotel.name]; // ✅ was widget.hotel.category
  }

  // ==========================================================================
  // INIT
  // ==========================================================================

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

  // ==========================================================================
  // PROVIDER LOADER
  // ==========================================================================

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

      // Fallback: scan all approved
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
    debugPrint('[HotelBookingPage] provider: $_providerName (id=$_providerId)');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

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

  // ==========================================================================
  // LOADING / NO PROVIDER
  // ==========================================================================

  Widget _buildLoadingState() {
    return Center(
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
  }

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
  }

  // ==========================================================================
  // SCROLL BODY
  // ==========================================================================

  Widget _buildScrollBody() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroHeader(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHotelInfoCard(),
              const SizedBox(height: 16),
              _buildBookingSummary(),
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildGuestCard(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HERO HEADER
  // ==========================================================================

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        SizedBox(
          height: 260,
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
          ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Text(
            widget.hotel.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HOTEL INFO CARD
  // ==========================================================================

  Widget _buildHotelInfoCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotel.city,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hotel.location,          // ✅ was widget.hotel.category
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
                  '₹${widget.hotel.originalPrice}',   // ✅ show originalPrice struck through
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
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BOOKING SUMMARY
  // ==========================================================================

  Widget _buildBookingSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty)
            _summaryRow(widget.hotel.name, _totalAmount) // ✅ was widget.hotel.category
          else
            ..._cartItems.map(
              (e) => _summaryRow(
                '${e.name} × ${e.quantity}',
                (e.price * e.quantity).toDouble(),
              ),
            ),
          const Divider(height: 20),
          _summaryRow('Total', _totalAmount, bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('₹${amount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }

  // ==========================================================================
  // SCHEDULE CARD
  // ==========================================================================

  Widget _buildScheduleCard() {
    return _card(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month, color: Colors.deepPurple),
            ),
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
          Divider(color: Colors.grey.shade200),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time, color: Colors.deepPurple),
            ),
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

  // ==========================================================================
  // GUEST DETAILS CARD
  // ==========================================================================

  Widget _buildGuestCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Guest Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 16),
          _inputField(_nameController, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _inputField(_phoneController, 'Phone Number', Icons.phone_outlined,
              keyboardType: TextInputType.phone),
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

  // ==========================================================================
  // BOTTOM BAR
  // ==========================================================================

  Widget _buildBottomBar() {
    final canBook = !_isLoading && _providerId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
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
                  const Text('Total',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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

  // ==========================================================================
  // PAYMENT + ORDER FLOW
  // ==========================================================================

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
      _showPopup('Hotel provider information missing. Please try again.', false);
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: 'Hotel Booking — ${widget.hotel.name}',
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
        address:       'Hotel — ${widget.hotel.name}, ${widget.hotel.city}',
        note:          _noteController.text.trim(),
        date:          _selectedDate!,
        time:          _selectedTime!.format(context),
        totalAmount:   _totalAmount,
        visitType:     'Hotel',
        providerId:    _providerId!,
        isEnquiry:     false,
        providerName:  _providerName ?? '',
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

  // ==========================================================================
  // DATE / TIME PICKERS
  // ==========================================================================

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
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
          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ==========================================================================
  // POPUP
  // ==========================================================================

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
              color: Colors.white, borderRadius: BorderRadius.circular(28)),
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
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
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
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
    }
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.deepPurple),
          ),
        ),
      );
}