import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnquiryPage extends StatefulWidget {
  final String serviceName;
  final String? subCategory;
  final List<dynamic>? cart;

  const EnquiryPage({
    super.key,
    required this.serviceName,
    this.subCategory,
    this.cart,
  });

  @override
  State<EnquiryPage> createState() => _EnquiryPageState();
}

class _EnquiryPageState extends State<EnquiryPage>
    with SingleTickerProviderStateMixin {
  // ─── THEME TOKENS ────────────────────────────────────────────
  static const Color _primary    = Color(0xFF7C5CBF);
  static const Color _primarySoft= Color(0xFFEDE7F6);
  static const Color _surface    = Color(0xFFFFFFFF);
  static const Color _bg         = Color(0xFFF6F4FB);
  static const Color _textDark   = Color(0xFF1A1235);
  static const Color _textMid    = Color(0xFF6B6880);
  static const Color _border     = Color(0xFFE0DAF0);
  static const Color _error      = Color(0xFFD32F2F);
  static const Color _success    = Color(0xFF2E7D32);

  // ─── KEYS / CONTROLLERS ─────────────────────────────────────
  final _formKey        = GlobalKey<FormState>();
  final nameController  = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final _nameFocus  = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  late AnimationController _fadeCtrl;
  late Animation<double>    _fadeAnim;

  // ─── STATE ──────────────────────────────────────────────────
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading         = false;
  bool isLoadingProvider = true;
  String? _providerId;
  String? _noProviderMessage;

  // ─── ADAPTIVE SCALE (set each build) ─────────────────────────
  double _scale = 1.0;
  double _s(double v) => v * _scale;

  // ─── LIFECYCLE ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProvider();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── CATEGORY HELPERS ───────────────────────────────────────
  // Collapses whitespace/casing so "Home  Cleaning" and "home cleaning"
  // both normalise to a comparable canonical form. This is separate
  // from order_service.dart's normalizeServiceType()/normalizeCategory()
  // (which strip ALL separators) — this one is only used to build the
  // display-friendly / storage-friendly strings passed into
  // OrderService.placeOrder(), matching exactly how placeOrder's own
  // `serviceType.trim().toLowerCase()` normalizes things.
  String _resolveCanonical(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String get serviceType => _resolveCanonical(widget.serviceName);
  String? get subCategoryNormalized =>
      widget.subCategory == null || widget.subCategory!.trim().isEmpty
          ? null
          : _resolveCanonical(widget.subCategory!);

  // ─── PROVIDER LOOKUP
  //
  // This picks ONE provider to route the enquiry to (stored as
  // `providerId` on the order, with `isAssigned: true` from the moment
  // it's created — see OrderService.placeOrder()). It prefers an
  // exact categories[]/subCategories[] match via categoryMatchFuzzy(),
  // but if NONE of the same-service-type providers have a matching
  // category, it still falls back to `candidates.first.id` rather than
  // showing "no provider available".
  //
  // FIX (see business_dashboard_page.dart): that fallback used to be
  // dangerous, because the provider it picked in the no-exact-match
  // case would then fail business_dashboard_page.dart's category check
  // and the resulting enquiry would become invisible on THAT
  // provider's own dashboard — assigned in Firestore, but shown
  // nowhere. That has been fixed on the dashboard side: any enquiry
  // that is directly assigned to a provider (isAssigned=true +
  // matching providerId/providerUserId) is now ALWAYS shown to that
  // exact provider in their Available tab, regardless of category —
  // exactly like a directly-assigned "pending" order already was. So
  // the fallback here is safe again: whichever provider gets chosen
  // (exact match or fallback) is now guaranteed to actually see the
  // enquiry.
  //
  // Reads the SAME categories[] + subCategories[] arrays, through the
  // SAME categoryMatchFuzzy() pipeline that both
  // business_dashboard_page.dart's Available tab and
  // order_service.dart's push-notification fan-out use — so "who we
  // found" and "who gets shown this order" never disagree on the
  // category-match tier. The `matchData` map below is built exactly
  // the way placeOrder() will populate the real order document
  // (canonical category + canonical services), so there's no drift
  // between the lookup and the eventual order document.
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadProvider() async {
    if (!mounted) return;
    setState(() {
      isLoadingProvider = true;
      _noProviderMessage = null;
    });

    try {
      final found = await _findMatchingProvider(approvedOnly: true) ??
          await _findMatchingProvider(approvedOnly: false);

      if (found == null) throw Exception('no_provider');
      _setProvider(found);
    } catch (_) {
      if (mounted) {
        setState(() {
          _noProviderMessage =
              'No approved provider found for "${widget.serviceName}"'
              '${widget.subCategory != null ? ' (${widget.subCategory})' : ''}.\n'
              'Please try again later.';
          isLoadingProvider = false;
        });
      }
    }
  }

  // Finds ONE provider doc id matching this enquiry's service type +
  // category/sub-category, or null if none exists at this tier.
  // Called first with approvedOnly=true, then (if that finds nothing)
  // with approvedOnly=false as a last-resort fallback.
  Future<String?> _findMatchingProvider({required bool approvedOnly}) async {
    final category    = serviceType;             // e.g. "civil construction"
    final subCategory = subCategoryNormalized;    // e.g. "structural assessment"
    final normSvc     = normalizeServiceType(category);

    final col = FirebaseFirestore.instance.collection('providers');

    // Primary: fast indexed query — works whenever the provider's
    // stored serviceType is byte-identical to ours.
    Query<Map<String, dynamic>> primaryQuery =
        col.where('serviceType', isEqualTo: category);
    if (approvedOnly) {
      primaryQuery = primaryQuery.where('status', isEqualTo: 'approved');
    }
    final primarySnap = await primaryQuery.get();

    // Fallback: broad scan, filtered client-side via
    // normalizeServiceType() — rescues providers whose serviceType
    // field differs only in casing/spacing. Mirrors
    // order_service.dart's _notifyMatchingProviders() fallback.
    Query<Map<String, dynamic>> fallbackQuery = col;
    if (approvedOnly) {
      fallbackQuery = fallbackQuery.where('status', isEqualTo: 'approved');
    }
    final fallbackSnap = await fallbackQuery.get();

    final seen = <String>{};
    final candidates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in primarySnap.docs) {
      if (seen.add(doc.id)) candidates.add(doc);
    }
    for (final doc in fallbackSnap.docs) {
      if (seen.contains(doc.id)) continue;
      final docSvc = providerServiceType(doc.data());
      if (docSvc.isNotEmpty && normalizeServiceType(docSvc) == normSvc) {
        seen.add(doc.id);
        candidates.add(doc);
      }
    }

    if (candidates.isEmpty) return null;

    // Build an order-shaped map, canonicalized exactly the way
    // placeOrder() will populate the real order — same category
    // resolution, same services list — so matching here and
    // matching once the order actually exists never disagree.
    final effectiveCategory =
        servicesList.isNotEmpty ? servicesList.first : category;
    final canonicalCategory = resolveCanonicalCategory(effectiveCategory, category);
    final canonicalServices =
        servicesList.map((s) => resolveCanonicalCategory(s, category)).toList();

    final matchData = <String, dynamic>{
      'category':    canonicalCategory,
      'subCategory': subCategory ?? '',
      'services':    canonicalServices,
      'serviceType': category,
    };

    // Prefer a provider whose categories[] / subCategories[] pool
    // actually matches this enquiry — reads BOTH fields, merged, via
    // the shared helpers, then runs the shared fuzzy pipeline.
    for (final doc in candidates) {
      final data            = doc.data();
      final providerCats    = providerCategories(data);
      final providerSubCats = providerSubCategories(data);

      final matched = categoryMatchFuzzy(
        matchData,
        providerCats,
        providerSubCats: providerSubCats,
        debugOrderId: 'enquiry-lookup:${doc.id}',
      );
      if (matched) return doc.id;
    }

    // No category-level match among same-service-type providers —
    // fall back to any of them rather than showing "no provider
    // available". Safe now that business_dashboard_page.dart's
    // direct-assignment bypass covers `enquiry` status too (see the
    // FIX note on _loadProvider() above) — this provider WILL see the
    // enquiry on their dashboard even without a category match.
    return candidates.first.id;
  }

  void _setProvider(String id) {
    if (!mounted) return;
    setState(() {
      _providerId       = id;
      isLoadingProvider = false;
    });
    _fadeCtrl.forward();
  }

  // ─── HELPERS ────────────────────────────────────────────────
  List<String> get servicesList {
    if (widget.cart != null && widget.cart!.isNotEmpty) {
      return widget.cart!.map((e) => '${e.name} x${e.quantity}').toList();
    }
    return [widget.serviceName];
  }

  bool get _hasCart => widget.cart != null && widget.cart!.isNotEmpty;

  // ─── VALIDATIONS ────────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty)  return 'Full name is required';
    if (v.trim().length < 2)            return 'Name must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s\.''\-]+$").hasMatch(v.trim())) {
      return 'Name can only contain letters, spaces, or hyphens';
    }
    return null;
  }

  // Strict 10-digit phone validation. Tolerates a leading +91/91
  // country code by stripping it before the digit-count check.
  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';

    var digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty)  return null; // optional
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ─── SUBMIT ─────────────────────────────────────────────────
  Future<void> submitEnquiry() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fix the errors above', isError: true);
      return;
    }
    if (selectedDate == null) {
      _showSnack('Please select a date', isError: true);
      return;
    }
    if (selectedTime == null) {
      _showSnack('Please select a time', isError: true);
      return;
    }
    if (_providerId == null || _providerId!.isEmpty) {
      _showSnack('No provider available for this service', isError: true);
      return;
    }
    if (isLoading) return;

    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('You must be logged in');

      await OrderService.placeOrder(
        serviceType:   serviceType,
        subCategory:   subCategoryNormalized,
        services:      servicesList,
        userId:        user.uid,
        userName:      nameController.text.trim(),
        phone:         phoneController.text.trim(),
        email:         emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        createdBy:     user.uid,
        createdByRole: 'user',
        address:       'Not Provided',
        date:          selectedDate!,
        time:          selectedTime!.format(context),
        totalAmount:   0,
        isEnquiry:     true,
        providerId:    _providerId!,
        providerName:  'service provider', itemBreakdown: [],
      );

      if (_hasCart) Cart.clear(widget.serviceName);

      if (!mounted) return;
      _showSnack('Enquiry submitted — we\'ll be in touch soon ✅');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnack('Something went wrong: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── UI HELPERS ─────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: _s(18),
            ),
            SizedBox(width: _s(10)),
            Expanded(child: Text(msg, style: TextStyle(fontSize: _s(14)))),
          ],
        ),
        backgroundColor: isError ? _error : _success,
        behavior:   SnackBarBehavior.floating,
        shape:      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin:     const EdgeInsets.all(16),
        duration:   const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final max  = DateTime(now.year + 1);
    final picked = await showDatePicker(
      context:     context,
      firstDate:   now,
      lastDate:    max,
      initialDate: selectedDate ?? now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:      _primary,
            onPrimary:    Colors.white,
            onSurface:    _textDark,
            surfaceVariant: _primarySoft,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context:     context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   _primary,
            onPrimary: Colors.white,
            onSurface: _textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => selectedTime = t);
  }

  // ─── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // sw/390 baseline scale, clamped so tiny/huge screens stay usable.
    _scale = (mq.size.width / 390).clamp(0.85, 1.25);
    final isWide = mq.size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        extendBody: true,
        extendBodyBehindAppBar: false,
        appBar: _buildAppBar(),
        body: SafeArea(
          bottom: false,
          child: isLoadingProvider
              ? _loadingState()
              : _noProviderMessage != null
                  ? _noProviderState()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: isWide
                          ? _wideLayout(mq)
                          : _narrowLayout(mq),
                    ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor:    Colors.white,
      foregroundColor:    _textDark,
      elevation:          0,
      scrolledUnderElevation: 1,
      shadowColor:        _border,
      titleSpacing:       0,
      leading: IconButton(
        icon:    Icon(Icons.arrow_back_ios_new_rounded, size: _s(20)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enquiry',
            style: TextStyle(
              fontSize:   _s(17),
              fontWeight: FontWeight.w700,
              color:      _textDark,
            ),
          ),
          Text(
            widget.subCategory != null
                ? '${widget.serviceName} • ${widget.subCategory}'
                : widget.serviceName,
            style: TextStyle(
              fontSize: _s(12),
              color:    _textMid,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ─── LOADING ────────────────────────────────────────────────
  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
          SizedBox(height: _s(16)),
          Text('Finding a provider…',
              style: TextStyle(color: _textMid, fontSize: _s(14))),
        ],
      ),
    );
  }

  // ─── NO PROVIDER ────────────────────────────────────────────
  Widget _noProviderState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _s(36)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_s(20)),
              decoration: const BoxDecoration(
                color:  _primarySoft,
                shape:  BoxShape.circle,
              ),
              child: Icon(Icons.store_outlined,
                  size: _s(40), color: _primary),
            ),
            SizedBox(height: _s(20)),
            Text(
              'No Provider Available',
              style: TextStyle(
                  fontSize:   _s(18),
                  fontWeight: FontWeight.w700,
                  color:      _textDark),
            ),
            SizedBox(height: _s(10)),
            Text(
              _noProviderMessage ?? 'No approved provider found for this service.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: _s(14),
                  color:    _textMid,
                  height:   1.6),
            ),
            SizedBox(height: _s(28)),
            SizedBox(
              width: _s(160),
              height: _s(46),
              child: ElevatedButton.icon(
                onPressed: _loadProvider,
                icon:  Icon(Icons.refresh_rounded, size: _s(18)),
                label: Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: _s(14))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LAYOUTS ────────────────────────────────────────────────
  Widget _narrowLayout(MediaQueryData mq) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        _s(16), _s(16), _s(16), mq.viewPadding.bottom + _s(24),
      ),
      child: _formCard(),
    );
  }

  Widget _wideLayout(MediaQueryData mq) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          _s(24), _s(24), _s(24), mq.viewPadding.bottom + _s(32),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _formCard(),
        ),
      ),
    );
  }

  // ─── FORM CARD ──────────────────────────────────────────────
  Widget _formCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFF7C5CBF).withOpacity(0.08),
            blurRadius: 24,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(),
            if (_hasCart) _cartPreview(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(20)),
              child: _SectionLabel(label: 'Your Details', scale: _scale),
            ),
            SizedBox(height: _s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(20)),
              child: Column(
                children: [
                  _inputField(
                    controller:  nameController,
                    focusNode:   _nameFocus,
                    nextFocus:   _phoneFocus,
                    label:       'Full Name',
                    hint:        'e.g. Priya Sharma',
                    icon:        Icons.person_outline_rounded,
                    validator:   _validateName,
                    inputAction: TextInputAction.next,
                  ),
                  _inputField(
                    controller:  phoneController,
                    focusNode:   _phoneFocus,
                    nextFocus:   _emailFocus,
                    label:       'Phone Number',
                    hint:        '10-digit mobile number',
                    icon:        Icons.phone_outlined,
                    validator:   _validatePhone,
                    keyboard:    TextInputType.phone,
                    inputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\)\s]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  _inputField(
                    controller:  emailController,
                    focusNode:   _emailFocus,
                    label:       'Email Address',
                    hint:        'Optional — for confirmation',
                    icon:        Icons.mail_outline_rounded,
                    validator:   _validateEmail,
                    keyboard:    TextInputType.emailAddress,
                    inputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            SizedBox(height: _s(20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(20)),
              child: _SectionLabel(label: 'Schedule', scale: _scale),
            ),
            SizedBox(height: _s(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(20)),
              child: Row(
                children: [
                  Expanded(child: _dateTile()),
                  SizedBox(width: _s(12)),
                  Expanded(child: _timeTile()),
                ],
              ),
            ),
            SizedBox(height: _s(28)),
            Padding(
              padding: EdgeInsets.fromLTRB(_s(20), 0, _s(20), _s(24)),
              child: _submitButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CARD HEADER ────────────────────────────────────────────
  Widget _cardHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(_s(20), _s(22), _s(20), _s(18)),
      decoration: const BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_s(10)),
            decoration: BoxDecoration(
              color:        _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.support_agent_rounded,
                color: _primary, size: _s(22)),
          ),
          SizedBox(width: _s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subCategory != null
                      ? '${widget.serviceName} • ${widget.subCategory}'
                      : widget.serviceName,
                  style: TextStyle(
                      fontSize:   _s(16),
                      fontWeight: FontWeight.w700,
                      color:      _textDark),
                ),
                SizedBox(height: _s(2)),
                Text(
                  'Request a callback or home visit',
                  style: TextStyle(fontSize: _s(12), color: _textMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CART PREVIEW ───────────────────────────────────────────
  Widget _cartPreview() {
    return Container(
      margin:  EdgeInsets.fromLTRB(_s(20), _s(16), _s(20), 0),
      padding: EdgeInsets.all(_s(14)),
      decoration: BoxDecoration(
        color:        const Color(0xFFF3F0FB),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: _s(15), color: _primary),
              SizedBox(width: _s(6)),
              Text(
                'Services selected',
                style: TextStyle(
                    fontSize:   _s(12),
                    fontWeight: FontWeight.w600,
                    color:      _primary),
              ),
            ],
          ),
          SizedBox(height: _s(8)),
          ...servicesList.map(
            (e) => Padding(
              padding: EdgeInsets.only(top: _s(4)),
              child: Row(
                children: [
                  Icon(Icons.circle, size: _s(5), color: _textMid),
                  SizedBox(width: _s(8)),
                  Expanded(
                    child: Text(e,
                        style: TextStyle(
                            fontSize: _s(13), color: _textDark)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INPUT FIELD ────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    TextInputAction inputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: _s(14)),
      child: TextFormField(
        controller:        controller,
        focusNode:         focusNode,
        validator:         validator,
        keyboardType:      keyboard,
        textInputAction:   inputAction,
        inputFormatters:   inputFormatters,
        autovalidateMode:  AutovalidateMode.onUserInteraction,
        onFieldSubmitted:  (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        style: TextStyle(
            fontSize: _s(14), color: _textDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText:    label,
          hintText:     hint,
          hintStyle:    TextStyle(color: const Color(0xFFB0ABCB), fontSize: _s(13)),
          labelStyle:   TextStyle(color: _textMid, fontSize: _s(13)),
          prefixIcon:   Icon(icon, color: _primary, size: _s(20)),
          filled:       true,
          fillColor:    const Color(0xFFFAF9FD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:   const BorderSide(color: _border, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:   const BorderSide(color: _primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:   const BorderSide(color: _error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide:   const BorderSide(color: _error, width: 1.6),
          ),
          errorStyle: TextStyle(fontSize: _s(11.5), color: _error),
          contentPadding: EdgeInsets.symmetric(
              horizontal: _s(14), vertical: _s(14)),
        ),
      ),
    );
  }

  // ─── DATE TILE ──────────────────────────────────────────────
  Widget _dateTile() {
    final hasDate = selectedDate != null;
    return _scheduleTile(
      icon:     Icons.calendar_month_outlined,
      topLabel: 'Date',
      value:    hasDate
          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
          : 'Select',
      selected: hasDate,
      onTap:    _pickDate,
    );
  }

  // ─── TIME TILE ──────────────────────────────────────────────
  Widget _timeTile() {
    final hasTime = selectedTime != null;
    return _scheduleTile(
      icon:     Icons.access_time_rounded,
      topLabel: 'Time',
      value:    hasTime ? selectedTime!.format(context) : 'Select',
      selected: hasTime,
      onTap:    _pickTime,
    );
  }

  Widget _scheduleTile({
    required IconData icon,
    required String topLabel,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  EdgeInsets.symmetric(horizontal: _s(14), vertical: _s(13)),
        decoration: BoxDecoration(
          color:        selected ? _primarySoft : const Color(0xFFFAF9FD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _primary : _textMid, size: _s(18)),
            SizedBox(width: _s(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topLabel,
                      style: TextStyle(
                          fontSize: _s(10),
                          color:    selected ? _primary : _textMid,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                  SizedBox(height: _s(2)),
                  Text(value,
                      style: TextStyle(
                          fontSize:   _s(13),
                          color:      selected ? _textDark : _textMid,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SUBMIT BUTTON ──────────────────────────────────────────
  Widget _submitButton() {
    return SizedBox(
      width:  double.infinity,
      height: _s(52),
      child: ElevatedButton(
        onPressed: isLoading ? null : submitEnquiry,
        style: ElevatedButton.styleFrom(
          backgroundColor:            _primary,
          disabledBackgroundColor:    _primary.withOpacity(0.55),
          foregroundColor:            Colors.white,
          elevation:                  0,
          shadowColor:                Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? SizedBox(
                width:  _s(20),
                height: _s(20),
                child: const CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: _s(18)),
                  SizedBox(width: _s(10)),
                  Text('Submit Enquiry',
                      style: TextStyle(
                          fontSize:   _s(15),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3)),
                ],
              ),
      ),
    );
  }
}

// ─── SECTION LABEL WIDGET ────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final double scale;
  const _SectionLabel({required this.label, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize:      11 * scale,
              fontWeight:    FontWeight.w700,
              color:         const Color(0xFF7C5CBF),
              letterSpacing: 1.2),
        ),
        SizedBox(width: 10 * scale),
        const Expanded(
          child: Divider(color: Color(0xFFE0DAF0), thickness: 1),
        ),
      ],
    );
  }
}