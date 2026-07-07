import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';
import '../payment/payment_page.dart';

import '../screens/map_picker_page.dart';

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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();

  bool _isLoading          = false;
  bool _isPickingLocation  = false;
  bool _isLoadingProvider  = true;

  // Provider resolved from Firestore
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  // FIX: keep the structured pick around too (not just the display text
  // in _addressController) so re-opening the picker can seed it at the
  // same spot, and so lat/lng + the "Flat/Floor/Building" details entered
  // in the picker's bottom sheet aren't silently dropped on the floor.
  LatLng? _pickedLatLng;

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

  // ══════════════════════════════════════════════════════════════════════
  // CATEGORY DATA FOR OrderService
  //
  // FIX: this used to build a single descriptive string per item like
  // "Haircut (Home) x2" and hand the WHOLE thing to OrderService as the
  // `services[]` list. That string then went straight into
  // orderCategoryCandidates() in order_service.dart, which only strips
  // separators/casing — it never strips out "(Home) x2" — so the exact
  // and fuzzy category-match stages were being fed junk text instead of
  // a clean category name, and provider matching silently degraded to
  // best-effort fuzzy word overlap (or failed) even for salon categories
  // that should have matched exactly.
  //
  // Now: `_categoriesForOrder` holds ONLY the clean category name for
  // each cart item (e.g. "Haircut", "Facial") — these are the exact
  // strings from serviceConfigs["salon"].serviceCategories, which is
  // also what a provider's `categories[]` field is populated from at
  // registration. That's what gets passed as `services:` AND as the
  // primary `category:` hint to OrderService.placeOrder(), so
  // categoryMatchFuzzy() gets to run Stage-1 EXACT matching the way it's
  // meant to.
  //
  // The old descriptive text (visit type + quantity) isn't lost — it's
  // now composed into the order's `note` field instead, purely for
  // human/provider readability on the dashboard card, completely
  // separate from what matching logic reads.
  // ══════════════════════════════════════════════════════════════════════
  List<String> get _categoriesForOrder => widget.cartItems
      .map((e) => e.name.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  String get _primaryCategory =>
      _categoriesForOrder.isNotEmpty ? _categoriesForOrder.first : '';

  String get _itemsSummary => widget.cartItems
      .map((e) =>
          '${e.name} (${e.id.toString().contains("Home") ? "Home" : "Salon"}) x${e.quantity}')
      .join(', ');

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

    final user = FirebaseAuth.instance.currentUser;

    // Pre-fill name from Firebase auth, if available.
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      _nameController.text = user.displayName!.trim();
    }

    // Pre-fill phone from Firebase auth
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
    _nameController.dispose();
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
  // RESPONSIVE HELPERS
  // ==========================================================================

  // Base reference width (standard phone). Scale factor clamped so very
  // small or very large screens (tablets) don't blow up the UI.
  double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final factor = width / 390.0; // iPhone 13 / common Android baseline
    return factor.clamp(0.85, 1.25);
  }

  double _sp(BuildContext context, double value) => value * _scale(context);

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _isLoadingProvider
                      ? _buildLoadingState(context)
                      : _noProviderMessage != null
                          ? _buildNoProviderState(context)
                          : _buildScrollBody(context),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar:
            (!_isLoadingProvider && _noProviderMessage == null)
                ? _buildBottomBar(context)
                : null,
      ),
    );
  }

  // ==========================================================================
  // LOADING / NO PROVIDER STATES
  // ==========================================================================

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB38BFA)),
          SizedBox(height: _sp(context, 16)),
          Text('Finding a salon provider…',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: _sp(context, 14))),
        ],
      ),
    );
  }

  Widget _buildNoProviderState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(_sp(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_sp(context, 24)),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.store_mall_directory_outlined,
                  size: _sp(context, 52), color: Colors.grey.shade400),
            ),
            SizedBox(height: _sp(context, 20)),
            Text(
              _noProviderMessage ?? 'No provider available',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: _sp(context, 15),
                  height: 1.6),
            ),
            SizedBox(height: _sp(context, 24)),
            ElevatedButton.icon(
              onPressed: _loadProvider,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB38BFA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                    horizontal: _sp(context, 24), vertical: _sp(context, 14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Try Again',
                  style: TextStyle(fontSize: _sp(context, 14))),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SCROLL BODY
  // ==========================================================================

  Widget _buildScrollBody(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          _sp(context, 20),
          _sp(context, 20),
          _sp(context, 20),
          _sp(context, 20),
        ),
        children: [
          _sectionTitle(context, 'Selected Services'),
          _buildServicesCard(context),
          SizedBox(height: _sp(context, 20)),
          _sectionTitle(context, 'Appointment Type'),
          _buildVisitTypeCard(context),
          SizedBox(height: _sp(context, 20)),
          _sectionTitle(context, 'Your Details'),
          _buildDetailsCard(context),
          SizedBox(height: _sp(context, 120)),
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_sp(context, 24)),
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
                  padding: EdgeInsets.all(_sp(context, 10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.arrow_back,
                      color: Colors.white, size: _sp(context, 22)),
                ),
              ),
              const Spacer(),
              if (_providerName != null && _providerName!.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _sp(context, 12), vertical: _sp(context, 6)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded,
                            size: _sp(context, 12), color: Colors.white),
                        SizedBox(width: _sp(context, 5)),
                        Flexible(
                          child: Text(
                            _providerName!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _sp(context, 12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: _sp(context, 24)),
          Text(
            'Salon Booking',
            style: TextStyle(
              color: Colors.white,
              fontSize: _sp(context, 30),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _sp(context, 6)),
          Text(
            '${widget.cartItems.length} service${widget.cartItems.length == 1 ? '' : 's'} selected',
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: _sp(context, 14)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SERVICES CARD
  // ==========================================================================

  Widget _buildServicesCard(BuildContext context) {
    return _card(
      context: context,
      child: Column(
        children: widget.cartItems.map<Widget>((item) {
          final isHome = item.id.toString().contains('Home');
          return Container(
            margin: EdgeInsets.only(bottom: _sp(context, 14)),
            padding: EdgeInsets.all(_sp(context, 14)),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  height: _sp(context, 54),
                  width: _sp(context, 54),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB38BFA), Color(0xFFE8A0BF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.content_cut,
                      color: Colors.white, size: _sp(context, 24)),
                ),
                SizedBox(width: _sp(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _sp(context, 15)),
                      ),
                      SizedBox(height: _sp(context, 4)),
                      Text(
                        '${isHome ? "Home Visit" : "Salon Visit"} • Qty ${item.quantity}',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: _sp(context, 13)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _sp(context, 8)),
                Text(
                  '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: _sp(context, 16)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // VISIT TYPE CARD  (home/salon indicator)
  // ==========================================================================

  Widget _buildVisitTypeCard(BuildContext context) {
    return _card(
      context: context,
      child: Row(
        children: [
          _visitChip(context, Icons.home_rounded, 'Home', _hasHome),
          SizedBox(width: _sp(context, 12)),
          _visitChip(context, Icons.store_rounded, 'Salon', _hasSalon),
        ],
      ),
    );
  }

  // ==========================================================================
  // DETAILS CARD
  // ==========================================================================

  Widget _buildDetailsCard(BuildContext context) {
    return _card(
      context: context,
      child: Column(
        children: [
          _input(
            context,
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Name is required';
              return null;
            },
          ),
          SizedBox(height: _sp(context, 16)),

          // FIX: was `RegExp(r'^[6-9]\d{9}$')` (India-mobile-specific
          // first-digit rule). Now just checks the digit count — exactly
          // 10 digits, no other restriction.
          _input(
            context,
            controller: _phoneController,
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Phone number is required';
              if (v.length != 10) return 'Enter exactly 10 digits';
              return null;
            },
          ),
          SizedBox(height: _sp(context, 16)),

          // FIX: email is now OPTIONAL. Only validated for shape if the
          // person actually types something in — an empty field is fine.
          _input(
            context,
            controller: _emailController,
            hint: 'Email Address (optional)',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return null; // optional — no error when empty
              final emailRegex =
                  RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
              if (!emailRegex.hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: _sp(context, 16)),

          // Address shown only for home-visit items.
          // Location is filled ONLY through "Pick on Map" — no GPS
          // auto-fill on this field.
          if (_hasHome) ...[
            _input(
              context,
              controller: _addressController,
              hint: 'Home Address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              readOnly: true,
              onTap: _pickOnMap,
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) {
                  return 'Please pick your address on the map';
                }
                return null;
              },
            ),
            SizedBox(height: _sp(context, 12)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPickingLocation ? null : _pickOnMap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB38BFA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: _sp(context, 16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  disabledBackgroundColor:
                      const Color(0xFFB38BFA).withOpacity(0.6),
                ),
                icon: _isPickingLocation
                    ? SizedBox(
                        height: _sp(context, 18),
                        width: _sp(context, 18),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.map_rounded, size: _sp(context, 20)),
                label: Text(
                  _isPickingLocation ? 'Opening Map…' : 'Pick on Map',
                  style: TextStyle(fontSize: _sp(context, 14)),
                ),
              ),
            ),
            SizedBox(height: _sp(context, 16)),
          ],

          _input(
            context,
            controller: _noteController,
            hint: 'Additional Note (optional)',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BOTTOM BAR
  // ==========================================================================

  Widget _buildBottomBar(BuildContext context) {
    final canPay = !_isLoading && _providerId != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
          _sp(context, 18), _sp(context, 16), _sp(context, 18), 0),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total Amount',
                      style: TextStyle(
                          color: Colors.grey, fontSize: _sp(context, 13))),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: _sp(context, 24),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(width: _sp(context, 16)),
            Expanded(
              child: ElevatedButton(
                onPressed: canPay ? _continueToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB38BFA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFB38BFA).withOpacity(0.4),
                  padding: EdgeInsets.symmetric(vertical: _sp(context, 16)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: _sp(context, 22),
                        width: _sp(context, 22),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Proceed To Pay',
                        style: TextStyle(
                            fontSize: _sp(context, 15),
                            fontWeight: FontWeight.bold)),
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
    // Trigger form validation; enable autovalidate so further edits revalidate live.
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showPopup('Please fix the highlighted fields', false);
      return;
    }

    final name    = _nameController.text.trim();
    final phone   = _phoneController.text.trim();
    final email   = _emailController.text.trim();
    final address = _addressController.text.trim();

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
      // Human-readable breakdown (visit type + quantity per item) is kept
      // for the provider dashboard, but composed into `note` — completely
      // separate from the clean category data used for matching below.
      final userNote = _noteController.text.trim();
      final composedNote = [
        _itemsSummary,
        if (userNote.isNotEmpty) userNote,
      ].join(' — ');

      await OrderService.placeOrder(
        serviceType:   'salon',
        // Clean category names only — exactly what serviceConfigs["salon"]
        // and a provider's registered categories[] use, so
        // categoryMatchFuzzy() can do a real Stage-1 exact match instead
        // of falling back to fuzzy word overlap.
        services:      _categoriesForOrder,
        category:      _primaryCategory,
        userId:        user.uid,
        userName:      name,
        phone:         phone,
        email:         email, // may be empty — that's fine, it's optional
        createdBy:     user.uid,
        createdByRole: 'user',
        address:       _hasHome ? address : 'Salon Visit',
        note:          composedNote,
        date:          DateTime.now(),
        time:          TimeOfDay.now().format(context),
        totalAmount:   _totalAmount,
        visitType:     _visitType,
        providerId:    _providerId!,
        isEnquiry:     false,
        providerName:  _providerName ?? '', itemBreakdown: [],
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
  // LOCATION — map picker only, no GPS
  // ==========================================================================
  //
  // FIX: MapPickerPage's `_confirmLocation()` does:
  //
  //     Navigator.pop(context, MapPickerResult(
  //       shortAddress: ..., fullAddress: ..., addressDetails: ..., latLng: ...,
  //     ));
  //
  // i.e. it ALWAYS pops a `MapPickerResult` object — never a raw String,
  // never a Map. The old code here only handled `result is String` and
  // `result is Map`, so every real return value fell through both checks
  // and hit the "Could not read the picked location" error branch. Location
  // picking looked broken, but the picker page itself was working the whole
  // time — this page just wasn't listening for the type it actually sends.
  //
  // Fixed by matching on `MapPickerResult` directly and building the
  // address text from its fields (prefer the more precise `fullAddress`,
  // fall back to `shortAddress`, and fold in any manually-typed
  // `addressDetails` like a flat/floor/building name).
  Future<void> _pickOnMap() async {
    setState(() => _isPickingLocation = true);
    try {
      final result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(
          builder: (_) => MapPickerPage(initialLatLng: _pickedLatLng),
        ),
      );

      if (result == null) return;

      String? pickedAddress;
      LatLng? pickedLatLng;

      if (result is MapPickerResult) {
        // The real, current return type from MapPickerPage.
        final baseAddress = result.fullAddress.trim().isNotEmpty
            ? result.fullAddress.trim()
            : result.shortAddress.trim();
        final details = result.addressDetails.trim();
        pickedAddress =
            details.isNotEmpty ? '$details, $baseAddress' : baseAddress;
        pickedLatLng = result.latLng;
      } else if (result is String) {
        // Kept for backwards compatibility in case an older/alternate
        // picker implementation is ever swapped in.
        pickedAddress = result;
      } else if (result is Map) {
        final map = result.cast<String, dynamic>();
        pickedAddress = (map['address'] ??
                map['formattedAddress'] ??
                map['fullAddress'] ??
                '')
            .toString();
      }

      if (pickedAddress != null && pickedAddress.trim().isNotEmpty) {
        setState(() {
          _addressController.text = pickedAddress!.trim();
          _pickedLatLng = pickedLatLng ?? _pickedLatLng;
        });
        _formKey.currentState?.validate();
      } else {
        _showPopup('Could not read the picked location. Please try again.', false);
      }
    } catch (e) {
      debugPrint('[SalonBookingPage] map picker error: $e');
      _showPopup('Could not open the map. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isPickingLocation = false);
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
          padding: EdgeInsets.all(_sp(context, 28)),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: _sp(context, 80),
                width: _sp(context, 80),
                decoration: BoxDecoration(
                  color: success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: success ? Colors.green : Colors.red,
                  size: _sp(context, 52),
                ),
              ),
              SizedBox(height: _sp(context, 20)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: _sp(context, 17), fontWeight: FontWeight.bold),
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

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: EdgeInsets.only(bottom: _sp(context, 10)),
        child: Text(title,
            style: TextStyle(
                fontSize: _sp(context, 17), fontWeight: FontWeight.bold)),
      );

  Widget _card({required BuildContext context, required Widget child}) =>
      Container(
        padding: EdgeInsets.all(_sp(context, 18)),
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

  Widget _visitChip(
          BuildContext context, IconData icon, String label, bool active) =>
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: _sp(context, 14)),
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
                  size: _sp(context, 18),
                  color: active ? Colors.white : Colors.black54),
              SizedBox(width: _sp(context, 6)),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: _sp(context, 14),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _input(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(fontSize: _sp(context, 15)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFB38BFA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: _sp(context, 20), vertical: _sp(context, 18)),
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: _sp(context, 15)),
        prefixIcon: Icon(icon,
            color: const Color(0xFFB38BFA), size: _sp(context, 22)),
        suffixIcon: readOnly ? const Icon(Icons.map_rounded, size: 18) : null,
        errorStyle: TextStyle(fontSize: _sp(context, 12)),
      ),
    );
  }
}