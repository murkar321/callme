import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:callme/data/resorts_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/payment/payment_page.dart';

// ─── Design tokens (matches booking_page.dart / hotel_booking_page.dart) ────

const _kAccent     = Color(0xFF5B4FCF);
const _kAccentSoft = Color(0xFF7B6FE8);
const _kBg         = Color(0xFFF4F3FB);
const _kCard       = Colors.white;
const _kSuccess    = Color(0xFF34C759);

class ResortBookingPage extends StatefulWidget {
  final Resort resort;

  /// Caller may pass a pre-resolved provider ID to skip the Firestore lookup.
  final String? initialProviderId;

  const ResortBookingPage({
    super.key,
    required this.resort,
    this.initialProviderId,
  });

  @override
  State<ResortBookingPage> createState() => _ResortBookingPageState();
}

class _ResortBookingPageState extends State<ResortBookingPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int adults = 1;
  int children = 0;

  bool _isLoading = false;
  bool _isLoadingProvider = true;
  bool _summaryExpanded = true;

  // FIX: same 10-digit "complete" tracking pattern as booking_page.dart's
  // _phoneComplete — drives the inline checkmark and lets validation give
  // a specific "enter a valid 10-digit number" message instead of lumping
  // name+phone into one generic error.
  bool _phoneComplete = false;

  // Provider resolved from Firestore
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  late final AnimationController _revealAnim;
  late final Animation<double> _revealFade;
  late final Animation<Offset> _revealSlide;

  static const String _kServiceType = 'resort';

  /// True only when the caller explicitly resolved a specific provider
  /// (deep-linked from a provider's own profile, or the resort listing
  /// itself carries a fixed `providerId`). This is the ONLY case where we
  /// should force direct assignment instead of letting placeOrder() fan
  /// the order out to every matching approved provider.
  bool get _isPinnedProvider =>
      (widget.initialProviderId?.isNotEmpty == true) ||
      widget.resort.providerId.isNotEmpty;

  /// MAIN category the order is matched against provider `categories[]` /
  /// `subCategories[]` on — the resort itself, canonicalized against
  /// serviceConfigs['resort'].
  String get _category =>
      resolveCanonicalCategory(widget.resort.name, _kServiceType);

  List<String> get _servicesForOrder => [widget.resort.name];

  // ── Total ─────────────────────────────────────────────────────────────────
  double get totalAmount {
    final adultTotal = widget.resort.price * adults;
    final childrenTotal = (widget.resort.price / 2) * children;
    return (adultTotal + childrenTotal).toDouble();
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

    _revealAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealAnim, curve: Curves.easeOutCubic));
    _revealFade = CurvedAnimation(parent: _revealAnim, curve: Curves.easeOut);

    // Pre-fill phone from Firebase auth
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

    // Provider resolution — use resort's own providerId as hint first
    final hint = widget.initialProviderId?.isNotEmpty == true
        ? widget.initialProviderId
        : (widget.resort.providerId.isNotEmpty ? widget.resort.providerId : null);

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

  // ==========================================================================
  // PROVIDER LOADER
  // ==========================================================================

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

  /// Finds the best approved 'resort' provider whose registered
  /// categories/subCategories match this resort — run through the exact
  /// same categoryMatchFuzzy() pipeline placeOrder()'s fan-out uses, so
  /// this preview agrees with who really gets notified.
  Future<void> _loadProvider() async {
    setState(() {
      _isLoadingProvider = true;
      _noProviderMessage = null;
    });
    try {
      final syntheticOrderData = <String, dynamic>{
        'category': _category,
        'subCategory': '',
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
              'No approved resort provider available yet.\nPlease try again later.';
          _isLoadingProvider = false;
        });
      }
    } catch (e) {
      debugPrint('[ResortBookingPage] _loadProvider error: $e');
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
    debugPrint('[ResortBookingPage] provider: $_providerName (id=$_providerId)');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: _isLoadingProvider
            ? _buildLoadingState()
            : _noProviderMessage != null
                ? _buildNoProviderState()
                : _buildScrollBody(),
      ),
      bottomNavigationBar: (!_isLoadingProvider && _noProviderMessage == null)
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
          const CircularProgressIndicator(color: _kAccent),
          const SizedBox(height: 16),
          Text('Finding a resort provider…',
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
              child: Icon(Icons.villa_outlined,
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
  }

  // ==========================================================================
  // SCROLL BODY — ordered flow:
  // Hero → Summary → (1) Guests → (2) Guest Details → (3) Schedule
  // ==========================================================================

  Widget _buildScrollBody() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(),

                const SizedBox(height: 20),
                _StepHeader(number: 1, label: 'Guests'),
                const SizedBox(height: 10),
                _buildGuestsCard(),

                const SizedBox(height: 20),
                _StepHeader(number: 2, label: 'Guest Details'),
                const SizedBox(height: 10),
                _buildGuestDetailsCard(),

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
        ),
      ],
    );
  }

  // ==========================================================================
  // SLIVER APP BAR
  // ==========================================================================

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isPinnedProvider && _providerName != null && _providerName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.resort.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.resort.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.resort.location,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    child: Text('₹${totalAmount.toStringAsFixed(0)}',
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
                        _summaryLine(
                          '${widget.resort.name} · $adults adult${adults != 1 ? 's' : ''}'
                          '${children > 0 ? ' · $children child${children != 1 ? 'ren' : ''}' : ''}',
                          totalAmount,
                        ),
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
                            Text('₹${totalAmount.toStringAsFixed(0)}',
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

  // ==========================================================================
  // STEP 1 — Guests card
  // ==========================================================================

  Widget _buildGuestsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Resort', widget.resort.name),
          _infoRow('City', widget.resort.city),
          _infoRow('Price Per Adult', '₹${widget.resort.price.toStringAsFixed(0)}'),
          _infoRow('Rating', '⭐ ${widget.resort.rating}'),
          const Divider(height: 24),
          _counterTile(
            title: 'Adults',
            subtitle: '₹${widget.resort.price.toStringAsFixed(0)} each',
            value: adults,
            onMinus: () {
              if (adults > 1) setState(() => adults--);
            },
            onPlus: () => setState(() => adults++),
          ),
          const Divider(height: 20),
          _counterTile(
            title: 'Children',
            subtitle: '₹${(widget.resort.price / 2).toStringAsFixed(0)} each (50% off)',
            value: children,
            onMinus: () {
              if (children > 0) setState(() => children--);
            },
            onPlus: () => setState(() => children++),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STEP 2 — Guest Details card
  // ==========================================================================

  Widget _buildGuestDetailsCard() {
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
          const SizedBox(height: 14),

          // FIX: digitsOnly + 10-digit hard cap via inputFormatters (same
          // as booking_page.dart's phone field), plus a live check-mark
          // suffix once 10 digits are entered.
          _Field(
            controller: _phoneController,
            hint: 'Mobile Number',
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
          const SizedBox(height: 14),
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

  // ==========================================================================
  // STEP 3 — Schedule card
  // ==========================================================================

  Widget _buildScheduleCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 320;
        final dateTile = _PickerTile(
          icon: Icons.calendar_month_rounded,
          label: 'Check-In Date',
          value: selectedDate == null
              ? 'Tap to pick'
              : DateFormat('dd MMM yyyy').format(selectedDate!),
          selected: selectedDate != null,
          onTap: _pickDate,
        );
        final timeTile = _PickerTile(
          icon: Icons.access_time_rounded,
          label: 'Check-In Time',
          value: selectedTime == null ? 'Tap to pick' : selectedTime!.format(context),
          selected: selectedTime != null,
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

  // ==========================================================================
  // BOTTOM BAR
  // ==========================================================================

  Widget _buildBottomBar() {
    final canPay = !_isLoading && _providerId != null;
    final step1Done = _phoneComplete;
    final step2Done = selectedDate != null && selectedTime != null;

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
                onPressed: canPay ? _payNow : null,
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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Proceed to Payment',
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
                            child: Text('₹${totalAmount.toStringAsFixed(0)}',
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

  // ==========================================================================
  // PAYMENT FLOW
  // ==========================================================================

  Future<void> _payNow() async {
    // FIX: split into specific checks (name / phone-digit-count / date+time
    // / provider) instead of one combined "fill your details" message —
    // matches booking_page.dart's _validateAndPay() flow so the person
    // knows exactly which field needs fixing.
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    if (phone.length != 10) {
      _showSnack('Enter a valid 10-digit phone number');
      return;
    }
    if (selectedDate == null || selectedTime == null) {
      _showSnack('Please select check-in date and time');
      return;
    }
    if (_providerId == null || _providerId!.isEmpty) {
      _showSnack('Provider information missing. Please try again.');
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          amount: totalAmount.toInt(),
          serviceName: widget.resort.name,
        ),
      ),
    );

    if (result != true && result != 'offline') return;

    await _saveBooking(result);
  }

  Future<void> _saveBooking(dynamic result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please log in first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await OrderService.placeOrder(
        serviceType: _kServiceType,
        services: _servicesForOrder,
        userId: user.uid,
        userName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: user.email ?? '',
        createdBy: user.uid,
        createdByRole: 'user',
        address: '${widget.resort.name}, ${widget.resort.location}',
        note: _noteController.text.trim(),
        date: selectedDate!,
        time: selectedTime!.format(context),
        totalAmount: totalAmount,
        adults: adults,
        children: children,
        visitType: 'Resort',

        // Properly canonicalized category so the provider's dashboard
        // "Available" tab and the push-notification fan-out both match
        // this order against the correct registered categories — same
        // fix pattern as hotel_booking_page.dart / booking_page.dart.
        category: _category,

        // Only pin a specific provider when the caller (or the resort's
        // own listing data) explicitly resolved one. Otherwise leave
        // providerId null so placeOrder() fans the order out to every
        // approved resort provider whose categories/subCategories match
        // — instead of silently notifying only whoever _loadProvider()'s
        // preview search happened to land on.
        providerId: _isPinnedProvider ? _providerId : null,
        providerName: _isPinnedProvider ? (_providerName ?? '') : '',
        isEnquiry: false,
      );

      if (!mounted) return;

      _showSnack(result == 'offline'
          ? 'Booking Placed Successfully!'
          : 'Payment Successful! Booking Confirmed ✅');

      await Future.delayed(const Duration(seconds: 1));
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
      debugPrint('[ResortBookingPage] placeOrder error: $e');
      _showSnack('Something went wrong. Please try again.');
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
          colorScheme: const ColorScheme.light(primary: _kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

  void _showSnack(String msg) {
    if (!mounted) return;
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

  Widget _infoRow(String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _counterTile({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onMinus,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.remove,
                        size: 18,
                        color: value > (title == 'Adults' ? 1 : 0)
                            ? _kAccent
                            : Colors.grey.shade400),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: onPlus,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, size: 18, color: _kAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ─── Reusable UI pieces (match booking_page.dart / hotel_booking_page.dart) ─

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
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

// ─── Step header (matches hotel_booking_page.dart / booking_page.dart) ──────

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