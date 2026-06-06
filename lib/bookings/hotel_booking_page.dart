import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/hotel_data.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/payment/payment_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';

class HotelBookingPage extends StatefulWidget {
  final HotelRoom hotel;
  final List<dynamic> products;

  /// The providerId of the hotel — required so OrderService can fetch
  /// providerName & providerUserId from Firestore and send FCM notifications.
  final String providerId;

  const HotelBookingPage({
    super.key,
    required this.hotel,
    required this.products,
    required this.providerId, // ← NEW: pass from the caller screen
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage>
    with SingleTickerProviderStateMixin {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  // ── Cart helpers ───────────────────────────────────────────
  List<CartItem> get _cartItems => Cart.getItems('Hotel');

  double get _totalAmount {
    if (_cartItems.isNotEmpty) {
      return Cart.getTotal('Hotel').toDouble();
    }
    // Single room — apply discount
    final price    = widget.hotel.price.toDouble();
    final discount = widget.hotel.discount.toDouble();
    return price - (price * discount / 100);
  }

  // ── Services list for OrderService ────────────────────────
  List<String> get _servicesForOrder {
    if (_cartItems.isNotEmpty) {
      return _cartItems
          .map((e) => '${e.name} x${e.quantity}')
          .toList();
    }
    return [widget.hotel.category];
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
                child: ListView(
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ==========================================================
  // HERO HEADER
  // ==========================================================

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Image.asset(
            widget.hotel.image,
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay for readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
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
        // Hotel name overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Text(
            widget.hotel.hotelName,
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

  // ==========================================================
  // HOTEL INFO CARD
  // ==========================================================

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
                  widget.hotel.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.hotel.discount > 0) ...[
                Text(
                  '₹${widget.hotel.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${widget.hotel.discount.toStringAsFixed(0)}% off',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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

  // ==========================================================
  // BOOKING SUMMARY
  // ==========================================================

  Widget _buildBookingSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty)
            _summaryRow(widget.hotel.category, _totalAmount)
          else
            ..._cartItems.map(
              (e) => _summaryRow(
                '${e.name} × ${e.quantity}',
                (e.price * e.quantity) as double,
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

  // ==========================================================
  // SCHEDULE CARD
  // ==========================================================

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
              child: const Icon(Icons.calendar_month,
                  color: Colors.deepPurple),
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

  // ==========================================================
  // GUEST DETAILS CARD
  // ==========================================================

  Widget _buildGuestCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 16),
          _inputField(_nameController, 'Full Name', Icons.person),
          const SizedBox(height: 12),
          _inputField(_phoneController, 'Phone Number', Icons.phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _inputField(_addressController, 'Home Address', Icons.location_on,
              maxLines: 3),
          const SizedBox(height: 12),
          _inputField(_noteController, 'Special Request (optional)',
              Icons.notes,
              maxLines: 3),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM BAR
  // ==========================================================

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.07),
          ),
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
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
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
                onPressed: _isLoading ? null : _continueToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.deepPurple.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAYMENT + ORDER FLOW
  // ==========================================================

  Future<void> _continueToPayment() async {
    // ── Validation ──────────────────────────────────────────
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showPopup('Please fill all guest details', false);
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

    if (widget.providerId.isEmpty) {
      _showPopup('Hotel provider information missing. Please try again.', false);
      return;
    }

    // ── Navigate to payment ─────────────────────────────────
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: 'Hotel Booking — ${widget.hotel.hotelName}',
          amount: _totalAmount.toInt(),
        ),
      ),
    );

    // result == true  → online payment success
    // result == 'offline' → cash/offline
    if (result != true && result != 'offline') return;

    setState(() => _isLoading = true);

    try {
      // ── Place order via OrderService ────────────────────────
      // OrderService resolves providerName & providerUserId from Firestore
      // using providerId, so we only need to pass the ID here.
      await OrderService.placeOrder(
        serviceType:   'hotel',
        services:      _servicesForOrder,
        userId:        user.uid,
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user.email ?? '',
        createdBy:     user.uid,
        createdByRole: 'user',
        address:       _addressController.text.trim(),
        note:          _noteController.text.trim(),
        date:          _selectedDate!,
        time:          _selectedTime!.format(context),
        totalAmount:   _totalAmount,
        visitType:     'Hotel',
        providerId:    widget.providerId,
        isEnquiry:     false,
        providerName:  '', // resolved internally by OrderService
      );

      // ── Clear cart ──────────────────────────────────────────
      Cart.clear('Hotel');

      // ── Success dialog ──────────────────────────────────────
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
      debugPrint('[HotelBooking] placeOrder error: $e');
      _showPopup('Something went wrong. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // DATE / TIME PICKERS
  // ==========================================================

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

  // ==========================================================
  // POPUP
  // ==========================================================

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
            borderRadius: BorderRadius.circular(28),
          ),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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

  // ==========================================================
  // UI HELPERS
  // ==========================================================

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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.deepPurple),
          ),
        ),
      );
}