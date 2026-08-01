import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/screens/map_picker_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import 'package:intl/intl.dart';

class CivilBookingPage extends StatefulWidget {
  final String serviceName;   // Display name, e.g. "Standard Package"
  final String serviceType;   // Firestore lookup key, e.g. "civil"
  final List<CartItem>? cart;
  final List<dynamic>? products;
  final List<String>? selectedRenovationItems;
  final String? initialProviderId;

  const CivilBookingPage({
    super.key,
    required this.serviceName,
    // ✅ serviceType defaults to 'civil' so existing call-sites that don't
    //    pass it (e.g. CartPage → CivilBookingPage) keep working unchanged.
    this.serviceType = 'civil',
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
  bool _isLoadingProvider = true;
  bool _phoneComplete     = false;

  // ✅ Auto-fill + edit-lock state. When a value is successfully pulled
  // from the `users` collection, the field starts locked (read-only,
  // shown with an edit pencil) so users don't accidentally retype details
  // that are already correct — tapping the pencil unlocks it for editing.
  bool _nameLocked  = false;
  bool _phoneLocked = false;

  LatLng? _pickedLatLng;
  String  _enquiryId = '';

  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  // ✅ Dark-mode flag. FIX: this used to be derived manually from
  // SettingsController.instance.themeMode + MediaQuery.platformBrightnessOf
  // inside a ValueListenableBuilder wrapping the whole scaffold. That
  // extra layer could fall out of sync with what the rest of the app
  // (and MaterialApp.themeMode, which is already wired to
  // SettingsController) was actually showing — which is why this page
  // could stay light even after switching to dark in Settings.
  //
  // Theme.of(context) always reflects the FINAL resolved brightness
  // (light/dark/system already resolved by Flutter), and since Theme is
  // an InheritedWidget, this page rebuilds automatically whenever the
  // app's theme changes — no manual listening required.
  bool _isDark = false;

  String get _resolvedCategory => _resolvedCategoryValue;
  String get _resolvedSubCategory => _resolvedSubCategoryValue;
  String _resolvedCategoryValue = '';
  String _resolvedSubCategoryValue = '';

  late final AnimationController _pageAnim;
  late final AnimationController _revealAnim;
  late final Animation<double>   _pageFade;
  late final Animation<Offset>   _revealSlide;
  late final Animation<double>   _revealFade;

  static const _accent  = Color(0xFF6A5AE0);
  static const _accent2 = Color(0xFF8F7CFF);

  // ── Theme tokens (light / dark aware) ────────────────────────────────────
  Color get _bgColor      => _isDark ? const Color(0xFF121218) : const Color(0xFFF0F1F8);
  Color get _cardColor    => _isDark ? const Color(0xFF1E1E27) : Colors.white;
  Color get _cardBorder   => _isDark ? const Color(0xFF2C2C38) : Colors.grey.shade200;
  Color get _inputFill    => _isDark ? const Color(0xFF262631) : const Color(0xFFF5F6FC);
  Color get _textPrimary  => _isDark ? const Color(0xFFEDEDF3) : const Color(0xFF1A1A2E);
  Color get _textSecondary=> _isDark ? const Color(0xFFA1A1B5) : Colors.grey.shade500;
  Color get _textFaint    => _isDark ? const Color(0xFF7B7B90) : Colors.grey.shade400;
  Color get _dividerColor => _isDark ? const Color(0xFF2A2A36) : Colors.grey.shade100;
  Color get _shadowColor  => _isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.05);
  Color get _chipBg       => _isDark ? const Color(0xFF262631) : Colors.grey.shade100;

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

    // Pre-fill phone from FirebaseAuth first (fast, no network round trip)…
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    // …then refine/complete from the `users` collection (name + phone),
    // which also drives the lock state on those fields.
    _fetchUserProfile();

    _resolveCategorySelection();

    if (widget.initialProviderId != null && widget.initialProviderId!.isNotEmpty) {
      _providerId        = widget.initialProviderId;
      _isLoadingProvider = false;
      _fetchProviderName(widget.initialProviderId!);
    } else {
      _loadProvider();
    }
  }

  // ✅ Pulls name + phone from the `users` collection (doc ID = the
  // logged-in user's email, per the app's existing schema — see
  // notification_service.dart / order_service.dart FCM mirroring) and
  // pre-fills + locks whichever fields come back non-empty. If a field
  // is already filled some other way, or the lookup finds nothing, it's
  // simply left editable.
  Future<void> _fetchUserProfile() async {
    try {
      final user  = FirebaseAuth.instance.currentUser;
      final email = user?.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (!mounted || !doc.exists) return;

      final data          = doc.data() ?? {};
      final fetchedName   = (data['name'] ?? '').toString().trim();
      final fetchedPhone  = (data['phone'] ?? '').toString().trim();

      setState(() {
        if (fetchedName.isNotEmpty && _nameController.text.trim().isEmpty) {
          _nameController.text = fetchedName;
          _nameLocked = true;
        }
        if (fetchedPhone.isNotEmpty && _phoneController.text.trim().isEmpty) {
          final digits = fetchedPhone.replaceAll(RegExp(r'[^\d]'), '');
          _phoneController.text = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
          _phoneLocked = true;
        }
      });
      _onPhoneChanged();
    } catch (e) {
      debugPrint('[Civil] Could not fetch user profile: $e');
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

  void _resolveCategorySelection() {
    final normalizedServiceType = widget.serviceType.trim().toLowerCase();
    final serviceNames = _hasCartItems
        ? _cartItems.map((e) => e.name).toList()
        : (widget.selectedRenovationItems?.isNotEmpty ?? false)
            ? widget.selectedRenovationItems!
            : [widget.serviceName];

    final rawCategoryInput =
        serviceNames.isNotEmpty ? serviceNames.first : widget.serviceName;

    final subParent =
        parentCategoryForSubService(rawCategoryInput, normalizedServiceType);

    if (subParent != null) {
      _resolvedCategoryValue    = subParent;
      _resolvedSubCategoryValue = cleanSubCategory(rawCategoryInput);
    } else {
      _resolvedCategoryValue    = resolveCanonicalCategory(rawCategoryInput, normalizedServiceType);
      _resolvedSubCategoryValue = '';
    }

    debugPrint('[Civil] resolved category="$_resolvedCategoryValue" '
        'subCategory="$_resolvedSubCategoryValue" from raw="$rawCategoryInput"');
  }

  Map<String, dynamic> _orderLikeDataForLookup(String normalizedServiceType) {
    final serviceNames = _hasCartItems
        ? _cartItems.map((e) => e.name).toList()
        : (widget.selectedRenovationItems?.isNotEmpty ?? false)
            ? widget.selectedRenovationItems!
            : [widget.serviceName];

    return <String, dynamic>{
      'category':    _resolvedCategory,
      'subCategory': _resolvedSubCategory,
      'services':    serviceNames,
      'serviceType': normalizedServiceType,
    };
  }

  Future<void> _loadProvider() async {
    if (!mounted) return;
    setState(() { _isLoadingProvider = true; _noProviderMessage = null; });

    try {
      final normalizedServiceType = widget.serviceType.trim().toLowerCase();
      final orderLikeData = _orderLikeDataForLookup(normalizedServiceType);

      debugPrint('[Civil] serviceType="$normalizedServiceType" '
          'resolvedCategory="$_resolvedCategory" '
          'resolvedSubCategory="$_resolvedSubCategory"');

      final primarySnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: normalizedServiceType)
          .get();

      final fallbackSnap = await FirebaseFirestore.instance
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      final seen       = <String>{};
      final candidates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in primarySnap.docs) {
        if (seen.add(doc.id)) candidates.add(doc);
      }
      for (final doc in fallbackSnap.docs) {
        if (seen.contains(doc.id)) continue;
        final docSvc = providerServiceType(doc.data());
        if (docSvc.isNotEmpty && normalizeServiceType(docSvc) == normalizedServiceType) {
          seen.add(doc.id);
          candidates.add(doc);
        }
      }

      debugPrint('[Civil] ${candidates.length} approved $normalizedServiceType '
          'provider(s) to check');

      for (final doc in candidates) {
        final data    = doc.data();
        final cats    = providerCategories(data);
        final subCats = providerSubCategories(data);
        final pool    = providerCategoryPool(cats, subCats);

        final matched = categoryMatchFuzzy(
          orderLikeData,
          pool,
          debugOrderId: 'civil-lookup:${doc.id}',
        );

        if (matched) {
          debugPrint('[Civil] category-matched provider: ${doc.id}');
          _setProvider(doc.id, data);
          return;
        }
      }

      if (candidates.isNotEmpty) {
        debugPrint('[Civil] no category match — falling back to first '
            'approved $normalizedServiceType provider: ${candidates.first.id}');
        _setProvider(candidates.first.id, candidates.first.data());
        return;
      }

      if (mounted) {
        setState(() {
          _noProviderMessage =
              'No Civil provider found.\n'
              'Check that a Civil provider has registered and been approved.';
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

  void _clearCartAfterBooking() {
    final cartKey = widget.serviceName.trim();
    if (cartKey.isEmpty) return;

    Cart.clear(cartKey);
    widget.cart?.clear();

    debugPrint('[Civil] Cart cleared after booking (Done tapped) for "$cartKey".');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ✅ Read the resolved brightness straight from the ambient Theme.
    // This is the same theme MaterialApp already resolves from
    // SettingsController (including "System" mode), so this page just
    // follows it directly instead of re-deriving it a second time.
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15),
        ),
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
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
      Text('Finding a provider…', style: TextStyle(color: _textSecondary)),
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
                      const SizedBox(height: 16),
                      _buildProviderContactNote(),
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
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(_isDark ? 0.28 : 0.15)),
        boxShadow: [BoxShadow(blurRadius: 14, offset: const Offset(0, 5), color: _shadowColor)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 14),
          child: Column(children: [
            ..._cartItems.asMap().entries.map((e) => Column(children: [
              _buildCartItemRow(e.value, isSmall: isSmall),
              if (e.key < _cartItems.length - 1) Divider(height: 20, color: _dividerColor),
            ])),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 14, vertical: isSmall ? 10 : 12),
              decoration: BoxDecoration(color: _accent.withOpacity(_isDark ? 0.14 : 0.06), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.currency_rupee_rounded, color: _accent, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text('Estimated Total',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textPrimary))),
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
                style: TextStyle(color: Colors.amber.shade700, fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
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
          color: _chipBg,
          child: item.image != null
              ? Image.asset(item.image!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: _textFaint, size: 22))
              : Icon(Icons.construction_rounded, color: _accent.withOpacity(0.4), size: 22),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmall ? 13 : 14,
                color: _textPrimary, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Text('₹${item.price}', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(' / unit', style: TextStyle(color: _textFaint, fontSize: 11)),
        ]),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _accent.withOpacity(_isDark ? 0.18 : 0.09), borderRadius: BorderRadius.circular(20)),
          child: Text('x$qty', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 6),
        Text('₹${item.price * qty}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textPrimary)),
      ]),
    ]);
  }

  // ── Selected renovation items card ────────────────────────────────────────
  Widget _buildSelectedItemsCard() {
    final items = widget.selectedRenovationItems!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(_isDark ? 0.30 : 0.18)),
        boxShadow: [BoxShadow(blurRadius: 14, offset: const Offset(0, 5), color: _shadowColor)],
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
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textPrimary)),
            Text('${items.length} service${items.length > 1 ? 's' : ''} selected',
                style: TextStyle(color: _textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _accent.withOpacity(_isDark ? 0.2 : 0.10), borderRadius: BorderRadius.circular(20)),
            child: Text('${items.length}',
                style: const TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ]),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: _dividerColor)),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _accent.withOpacity(_isDark ? 0.16 : 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withOpacity(_isDark ? 0.35 : 0.20), width: 1)),
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
            decoration: BoxDecoration(color: _chipBg, shape: BoxShape.circle),
            child: Icon(Icons.store_mall_directory_outlined, size: 52, color: _textFaint),
          ),
          const SizedBox(height: 20),
          Text(_noProviderMessage ?? 'No provider available',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.6)),
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
    final isEmoji  = number == '📋';
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.2))),
    ]);
  }

  // ── Details card ──────────────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return _card(child: Column(children: [
      _field(
        controller: _nameController,
        hint: 'Full Name',
        icon: Icons.person_outline_rounded,
        readOnly: _nameLocked,
        suffix: _nameLocked ? _editIcon(() => setState(() => _nameLocked = false)) : null,
      ),
      const SizedBox(height: 14),
      _field(
        controller: _phoneController, hint: 'Mobile Number (10 digits)',
        icon: Icons.phone_outlined, keyboard: TextInputType.phone, focusNode: _phoneFocus,
        readOnly: _phoneLocked,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        suffix: _phoneLocked
            ? _editIcon(() => setState(() => _phoneLocked = false))
            : (_phoneComplete ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20) : null),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: !_phoneComplete
            ? Padding(
                key: const ValueKey('hint'),
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 13, color: _textFaint),
                  const SizedBox(width: 6),
                  Text('Enter 10-digit phone to continue',
                      style: TextStyle(color: _textFaint, fontSize: 12)),
                ]))
            : const SizedBox.shrink(key: ValueKey('no-hint')),
      ),
      const SizedBox(height: 14),
      _field(controller: _addressController, hint: 'Project Address', icon: Icons.location_on_outlined, maxLines: 3),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openMapPicker,
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent, side: const BorderSide(color: _accent, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.map_outlined, size: 17),
          label: const Text('Pick on Map', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
      const SizedBox(height: 14),
      _field(controller: _noteController, hint: 'Describe your requirement (optional)',
          icon: Icons.notes_rounded, maxLines: 3),
    ]));
  }

  // ✅ Small reusable "edit" affordance shown on locked/auto-filled fields.
  Widget _editIcon(VoidCallback onTap) => IconButton(
    icon: Icon(Icons.edit_outlined, size: 18, color: _accent),
    splashRadius: 18,
    tooltip: 'Edit',
    onPressed: onTap,
  );

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
          color: selected ? _accent.withOpacity(_isDark ? 0.14 : 0.06) : _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _accent.withOpacity(0.5) : _cardBorder, width: 1.5),
          boxShadow: [BoxShadow(blurRadius: 10, color: _shadowColor)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: selected ? _accent.withOpacity(_isDark ? 0.22 : 0.12) : _chipBg,
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: selected ? _accent : _textFaint, size: 17),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: selected ? _accent : _textFaint,
              fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    );
  }

  // ── Provider contact note ─────────────────────────────────────────────────
  Widget _buildProviderContactNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(_isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(_isDark ? 0.3 : 0.18), width: 1),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: _accent.withOpacity(0.8)),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'A provider will contact you with a quote after reviewing your enquiry.',
          style: TextStyle(color: _accent.withOpacity(0.9), fontSize: 12, height: 1.4),
        )),
      ]),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final mq         = MediaQuery.of(context);
    final canProceed = !_isLoading && !_isLoadingProvider && _providerId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18,
          mq.viewInsets.bottom > 0 ? 8 : mq.viewPadding.bottom + 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(blurRadius: 18, color: _shadowColor)],
      ),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildStepProgress(),
        const SizedBox(height: 12),
        if (_hasCartItems)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _accent.withOpacity(_isDark ? 0.14 : 0.07), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded, color: _accent, size: 15),
              const SizedBox(width: 8),
              Text('${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'}',
                  style: TextStyle(color: _textSecondary, fontSize: 12)),
              const Spacer(),
              Text('Total: ', style: TextStyle(color: _textSecondary, fontSize: 12)),
              Text('₹$_cartTotal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _accent)),
            ]),
          ),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: canProceed && _phoneComplete ? _validateAndSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, disabledBackgroundColor: _isDark ? const Color(0xFF35353F) : Colors.grey.shade300,
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
          decoration: BoxDecoration(color: done ? _accent : (_isDark ? const Color(0xFF35353F) : Colors.grey.shade300), shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10,
          color: done ? _accent : _textFaint,
          fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
    ]),
  );

  Widget _progressLine({required bool done}) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    height: 2, width: 32,
    color: done ? _accent : _dividerColor,
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
            Text('Enquiry Submitted!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: _textPrimary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: _chipBg, borderRadius: BorderRadius.circular(20)),
              child: Text('ID: $_enquiryId',
                  style: TextStyle(color: _textSecondary, fontSize: 12, fontFamily: 'monospace')),
            ),
            if (_hasCartItems) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF1D1D28) : const Color(0xFFF5F5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withOpacity(_isDark ? 0.28 : 0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR ORDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: _accent, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ..._cartItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Expanded(child: Text(item.name,
                          style: TextStyle(fontSize: 13, color: _textPrimary))),
                      Text('₹${item.price * (item.quantity)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _accent, fontSize: 13)),
                    ]),
                  )),
                  Divider(color: _dividerColor),
                  Row(children: [
                    Expanded(child: Text('Total',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textPrimary))),
                    Text('₹$_cartTotal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _accent)),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            Text('We will contact you shortly with a quote and confirm your visit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.6)),
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
    _clearCartAfterBooking();

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
        data: (_isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: _isDark ? Brightness.dark : Brightness.light)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: (_isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: _isDark ? Brightness.dark : Brightness.light)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
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
        serviceType:   widget.serviceType.trim().toLowerCase(),
        services:      servicesList,
        category:      _resolvedCategory.isNotEmpty ? _resolvedCategory : null,
        subCategory:   _resolvedSubCategory.isNotEmpty ? _resolvedSubCategory : null,
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
        isEnquiry:     true, itemBreakdown: [], subCategories: [_resolvedSubCategory],
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
      color: _cardColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 5), color: _shadowColor)],
    ),
    child: child,
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) =>
      Container(
        decoration: BoxDecoration(color: _inputFill, borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: controller, keyboardType: keyboard,
          maxLines: maxLines, focusNode: focusNode,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: hint, hintStyle: TextStyle(color: _textFaint, fontSize: 14),
            prefixIcon: Icon(icon, color: _accent, size: 19),
            suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      );
}