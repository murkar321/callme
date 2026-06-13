import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';
import '../payment/payment_page.dart';

class SalonBookingPage extends StatefulWidget {
  final List<CartItem> cartItems;

  /// Caller may pass a pre-resolved provider ID so the Firestore lookup is
  /// skipped entirely — same pattern as BookingPage / CivilBookingPage.
  final String? initialProviderId;

  /// Legacy param kept for backwards compat — treated as initialProviderId
  /// when initialProviderId is null.
  final String providerId;

  const SalonBookingPage({
    super.key,
    required this.cartItems,
    this.providerId = '',
    this.initialProviderId,
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

  bool _isLoading          = false;
  bool _isGettingLocation  = false;
  bool _isLoadingProvider  = true;

  // Provider resolved from Firestore
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  // ── Visit-type helpers ──────────────────────────────────────────────────
  bool get _hasHome  => widget.cartItems.any((e) => e.id.toString().contains('Home'));
  bool get _hasSalon => widget.cartItems.any((e) => !e.id.toString().contains('Home'));

  String get _visitType {
    if (_hasHome && _hasSalon) return 'Mixed';
    if (_hasHome) return 'Home';
    return 'Salon';
  }

  // ── Total ───────────────────────────────────────────────────────────────
  double get _totalAmount => widget.cartItems.fold(
      0.0, (sum, item) => sum + item.price * item.quantity);

  // ── Services list for OrderService ─────────────────────────────────────
  List<String> get _servicesForOrder => widget.cartItems
      .map((e) =>
          '${e.name} (${e.id.toString().contains("Home") ? "Home" : "Salon"}) x${e.quantity}')
      .toList();

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Pre-fill phone from Firebase auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }
    if (user?.email != null) _emailController.text = user!.email!;

    // Provider resolution — same pattern as BookingPage
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
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // PROVIDER LOADER  (mirrors BookingPage exactly)
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
        _providerName = (business['businessName'] ?? data['providerName'] ?? '')
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
      // Query by serviceType: "salon"
      final snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: 'salon')
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _setProvider(snap.docs.first.id, snap.docs.first.data());
        return;
      }

      // Fallback: scan all approved providers
      final allSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      final match = allSnap.docs.where((doc) {
        final st = (doc.data()['serviceType'] ?? '').toString().toLowerCase();
        return st == 'salon';
      }).firstOrNull;

      if (match != null) {
        _setProvider(match.id, match.data());
      } else {
        if (mounted) {
          setState(() {
            _noProviderMessage =
                'No approved salon provider available yet.\nPlease try again later.';
            _isLoadingProvider = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[SalonBookingPage] _loadProvider error: $e');
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
      _providerName      = (business['businessName'] ?? data['providerName'] ?? '')
          .toString();
      _isLoadingProvider = false;
    });
    debugPrint('[SalonBookingPage] provider: $_providerName (id=$_providerId)');
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
      ),
      bottomNavigationBar:
          (!_isLoadingProvider && _noProviderMessage == null)
              ? _buildBottomBar()
              : null,
    );
  }

  // ==========================================================================
  // LOADING / NO PROVIDER STATES
  // ==========================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB38BFA)),
          const SizedBox(height: 16),
          Text('Finding a salon provider…',
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
              child: Icon(Icons.store_mall_directory_outlined,
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
                backgroundColor: const Color(0xFFB38BFA),
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
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

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
          Row(
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

  // ==========================================================================
  // SERVICES CARD
  // ==========================================================================

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
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isHome ? "Home Visit" : "Salon Visit"} • Qty ${item.quantity}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // VISIT TYPE CARD  (home/salon popup — kept exactly as original)
  // ==========================================================================

  Widget _buildVisitTypeCard() {
    return _card(
      child: Row(
        children: [
          _visitChip(Icons.home_rounded, 'Home', _hasHome),
          const SizedBox(width: 12),
          _visitChip(Icons.store_rounded, 'Salon', _hasSalon),
        ],
      ),
    );
  }

  // ==========================================================================
  // DETAILS CARD
  // ==========================================================================

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        children: [
          _input(_phoneController, 'Phone Number', Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _input(_emailController, 'Email Address', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),

          // Address shown only for home-visit items
          if (_hasHome) ...[
            _input(
              _addressController,
              'Home Address',
              Icons.location_on_outlined,
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_isGettingLocation
                    ? 'Getting Location…'
                    : 'Use Current Location'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _input(
            _noteController,
            'Additional Note (optional)',
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
    final canPay = !_isLoading && _providerId != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              blurRadius: 20, color: Colors.black.withOpacity(0.07)),
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
                  const Text('Total Amount',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: canPay ? _continueToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB38BFA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFB38BFA).withOpacity(0.4),
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
                    : const Text('Proceed To Pay',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PAYMENT FLOW
  // ==========================================================================

  Future<void> _continueToPayment() async {
    final phone   = _phoneController.text.trim();
    final email   = _emailController.text.trim();
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
    if (_providerId == null || _providerId!.isEmpty) {
      _showPopup('Provider information missing. Please try again.', false);
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          serviceName: 'Salon Booking',
          amount: _totalAmount.toInt(),
        ),
      ),
    );

    if (result != true && result != 'offline') return;

    setState(() => _isLoading = true);
    try {
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
        providerId:    _providerId!,
        isEnquiry:     false,
        providerName:  _providerName ?? '',
      );

      Cart.clear('Salon');

      _showPopup(
        result == 'offline' ? 'Booking Placed Successfully!' : 'Payment Successful!',
        true,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

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
      debugPrint('[SalonBookingPage] placeOrder error: $e');
      _showPopup('Something went wrong. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================================
  // LOCATION
  // ==========================================================================

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
          desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressController.text =
            '${p.street ?? ''}, ${p.locality ?? ''}, '
            '${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'
                .replaceAll(RegExp(r',\s*,'), ',')
                .trim();
      }
    } catch (e) {
      debugPrint('[SalonBookingPage] location error: $e');
      _showPopup('Could not fetch location: $e', false);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // ==========================================================================
  // POPUP  (kept exactly as original)
  // ==========================================================================

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
    if (success) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                    colors: [Color(0xFFB38BFA), Color(0xFFE8A0BF)])
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: const Color(0xFFB38BFA)),
          ),
        ),
      );
}