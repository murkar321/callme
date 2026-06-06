import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';
import '../payment/payment_page.dart';

class SalonBookingPage extends StatefulWidget {
  final List<dynamic> cartItems;

  /// Pass the providerId of the salon whose services are in the cart.
  /// Required so OrderService can fetch providerName & providerUserId from Firestore.
  final String providerId;

  const SalonBookingPage({
    super.key,
    required this.cartItems,
    required this.providerId, // ← NEW: must be passed from the caller
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage>
    with SingleTickerProviderStateMixin {
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();

  bool _isLoading         = false;
  bool _isGettingLocation = false;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  // ── Visit-type helpers ─────────────────────────────────────
  bool get _hasHome =>
      widget.cartItems.any((e) => e.id.toString().contains('Home'));

  bool get _hasSalon =>
      widget.cartItems.any((e) => e.id.toString().contains('Salon'));

  String get _visitType {
    if (_hasHome && _hasSalon) return 'Mixed';
    if (_hasHome) return 'Home';
    return 'Salon';
  }

  // ── Total ──────────────────────────────────────────────────
  double get _totalAmount {
    double total = 0;
    for (final item in widget.cartItems) {
      total += (item.price as num) * (item.quantity as num);
    }
    return total;
  }

  // ── Services list for OrderService ────────────────────────
  List<String> get _servicesForOrder => widget.cartItems
      .map((e) =>
          '${e.name} (${e.id.toString().contains("Home") ? "Home" : "Salon"}) x${e.quantity}')
      .toList();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    _sectionTitle('Selected Services'),
                    _buildServicesCard(),
                    const SizedBox(height: 20),
                    _sectionTitle('Appointment Type'),
                    _buildVisitTypeCard(),
                    const SizedBox(height: 20),
                    _sectionTitle('Your Details'),
                    _buildDetailsCard(),
                    const SizedBox(height: 120),
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
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB38BFA), Color(0xFFE8A0BF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Salon Booking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.cartItems.length} service${widget.cartItems.length == 1 ? '' : 's'} selected',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SERVICES CARD
  // ==========================================================

  Widget _buildServicesCard() {
    return _card(
      child: Column(
        children: widget.cartItems.map<Widget>((item) {
          final isHome = item.id.toString().contains('Home');
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB38BFA), Color(0xFFE8A0BF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.content_cut, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isHome ? "Home Visit" : "Salon Visit"} • Qty ${item.quantity}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // VISIT TYPE CARD
  // ==========================================================

  Widget _buildVisitTypeCard() {
    return _card(
      child: Row(
        children: [
          _visitChip(Icons.home, 'Home', _hasHome),
          const SizedBox(width: 12),
          _visitChip(Icons.store, 'Salon', _hasSalon),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAILS CARD
  // ==========================================================

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        children: [
          _input(_phoneController, 'Phone Number', Icons.phone,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _input(_emailController, 'Email Address', Icons.email,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),

          // Address only shown for home-visit items
          if (_hasHome) ...[
            _input(
              _addressController,
              'Home Address',
              Icons.location_on,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB38BFA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  disabledBackgroundColor:
                      const Color(0xFFB38BFA).withOpacity(0.6),
                ),
                icon: _isGettingLocation
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isGettingLocation
                      ? 'Getting Location…'
                      : 'Use Current Location',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _input(
            _noteController,
            'Additional Note (optional)',
            Icons.notes,
            maxLines: 3,
          ),
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
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                  backgroundColor: const Color(0xFFB38BFA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFB38BFA).withOpacity(0.5),
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
                        'Proceed To Pay',
                        style: TextStyle(
                          fontSize: 15,
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
  // PAYMENT FLOW
  // ==========================================================

  Future<void> _continueToPayment() async {
    // ── Validation ──────────────────────────────────────────
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    if (phone.isEmpty || email.isEmpty) {
      _showPopup('Please fill phone and email', false);
      return;
    }

    if (_hasHome && address.isEmpty) {
      _showPopup('Home address is required for home-visit services', false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showPopup('Please log in first', false);
      return;
    }

    if (widget.providerId.isEmpty) {
      _showPopup('Provider information missing. Please try again.', false);
      return;
    }

    // ── Navigate to payment ─────────────────────────────────
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: 'Salon Booking',
          amount: _totalAmount.toInt(),
        ),
      ),
    );

    // result == true  → online payment success
    // result == 'offline' → cash/offline payment
    if (result != true && result != 'offline') return;

    setState(() => _isLoading = true);

    try {
      // ── Place order via OrderService ────────────────────────
      // OrderService.placeOrder fetches providerName & providerUserId
      // from Firestore internally using providerId — no need to pass them here.
      await OrderService.placeOrder(
        serviceType:   'salon',
        services:      _servicesForOrder,
        userId:        user.uid,
        userName:      user.displayName ?? 'Salon User',
        phone:         phone,
        email:         email,
        createdBy:     user.uid,
        createdByRole: 'user',
        address:       _hasHome ? address : 'Salon Visit',
        note:          _noteController.text.trim(),
        date:          DateTime.now(),
        time:          TimeOfDay.now().format(context),
        totalAmount:   _totalAmount,
        visitType:     _visitType,
        providerId:    widget.providerId,
        isEnquiry:     false,
        // providerName and providerUserId are resolved inside OrderService
        // from the providerId — the named params below satisfy the signature
        // only if your OrderService still exposes them externally.
        // Remove the two lines below if your OrderService signature
        // no longer includes them (the version provided doesn't need them).
        providerName:  '',   // resolved internally by OrderService
      );

      // ── Clear cart ──────────────────────────────────────────
      Cart.clear('Salon');

      // ── Success popup ───────────────────────────────────────
      _showPopup(
        result == 'offline'
            ? 'Booking Placed Successfully!'
            : 'Payment Successful!',
        true,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // ── Navigate home ───────────────────────────────────────
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: phone,
            userEmail: email,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      debugPrint('[SalonBooking] placeOrder error: $e');
      _showPopup('Something went wrong. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showPopup('Location services are disabled', false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showPopup('Location permission denied', false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressController.text =
            '${p.street ?? ''}, ${p.locality ?? ''}, '
            '${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'
                .replaceAll(RegExp(r',\s*,'), ',')
                .trim();
      }
    } catch (e) {
      debugPrint('[SalonBooking] location error: $e');
      _showPopup('Could not fetch location: $e', false);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // ==========================================================
  // POPUP
  // ==========================================================

  void _showPopup(String message, bool success) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (success) return; // success dialog is dismissed manually after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: child,
      );

  Widget _visitChip(IconData icon, String label, bool active) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFB38BFA), Color(0xFFE8A0BF)],
                  )
                : null,
            color: active ? null : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: active ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: const Color(0xFFB38BFA)),
          ),
        ),
      );
}