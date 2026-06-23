import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnquiryPage extends StatefulWidget {
  final String serviceName;
  final List<dynamic>? cart;

  const EnquiryPage({
    super.key,
    required this.serviceName,
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

  // ─── PROVIDER LOOKUP ────────────────────────────────────────
  Future<void> _loadProvider() async {
    if (!mounted) return;
    setState(() {
      isLoadingProvider = true;
      _noProviderMessage = null;
    });

    try {
      final normalised = serviceType;

      var snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: normalised)
          .where('status',      isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        final allSnap = await FirebaseFirestore.instance
            .collection('providers')
            .where('status', isEqualTo: 'approved')
            .get();

        final match = allSnap.docs.where((doc) {
          final st = (doc.data()['serviceType'] ?? '').toString().toLowerCase();
          return st == normalised;
        }).toList();

        if (match.isEmpty) throw Exception('no_provider');
        _setProvider(match.first.id);
      } else {
        _setProvider(snap.docs.first.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _noProviderMessage =
              'No approved provider found for "${widget.serviceName}".\n'
              'Please try again later.';
          isLoadingProvider = false;
        });
      }
    }
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
  String get serviceType => widget.serviceName.trim().toLowerCase();

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

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty)  return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7)             return 'Enter at least 7 digits';
    if (digits.length > 15)            return 'Phone number is too long';
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(v.trim())) {
      return 'Enter a valid phone number';
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
        providerName:  'service provider',
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
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
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
    final mq     = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
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
        icon:    const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enquiry',
            style: const TextStyle(
              fontSize:   17,
              fontWeight: FontWeight.w700,
              color:      _textDark,
            ),
          ),
          Text(
            widget.serviceName,
            style: const TextStyle(
              fontSize: 12,
              color:    _textMid,
              fontWeight: FontWeight.w400,
            ),
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Finding a provider…',
              style: TextStyle(color: _textMid, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── NO PROVIDER ────────────────────────────────────────────
  Widget _noProviderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:  _primarySoft,
                shape:  BoxShape.circle,
              ),
              child: const Icon(Icons.store_outlined,
                  size: 40, color: _primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Provider Available',
              style: const TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      _textDark),
            ),
            const SizedBox(height: 10),
            Text(
              _noProviderMessage ?? 'No approved provider found for this service.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color:    _textMid,
                  height:   1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _loadProvider,
                icon:  const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
        16, 16, 16, mq.padding.bottom + 24,
      ),
      child: _formCard(),
    );
  }

  Widget _wideLayout(MediaQueryData mq) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, mq.padding.bottom + 32,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionLabel(label: 'Your Details'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    hint:        'e.g. +91 98765 43210',
                    icon:        Icons.phone_outlined,
                    validator:   _validatePhone,
                    keyboard:    TextInputType.phone,
                    inputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\)\s]')),
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
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionLabel(label: 'Schedule'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _dateTile()),
                  const SizedBox(width: 12),
                  Expanded(child: _timeTile()),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: _primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceName,
                  style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      color:      _textDark),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Request a callback or home visit',
                  style: TextStyle(fontSize: 12, color: _textMid),
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
      margin:  const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.receipt_long_outlined,
                  size: 15, color: _primary),
              const SizedBox(width: 6),
              const Text(
                'Services selected',
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      _primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...servicesList.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 5, color: _textMid),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e,
                        style: const TextStyle(
                            fontSize: 13, color: _textDark)),
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
      padding: const EdgeInsets.only(bottom: 14),
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
        style: const TextStyle(
            fontSize: 14, color: _textDark, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText:    label,
          hintText:     hint,
          hintStyle:    const TextStyle(color: Color(0xFFB0ABCB), fontSize: 13),
          labelStyle:   const TextStyle(color: _textMid, fontSize: 13),
          prefixIcon:   Icon(icon, color: _primary, size: 20),
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
          errorStyle: const TextStyle(fontSize: 11.5, color: _error),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
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
        padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                color: selected ? _primary : _textMid, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color:    selected ? _primary : _textMid,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize:   13,
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
      height: 52,
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
            ? const SizedBox(
                width:  20,
                height: 20,
                child: CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2.2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Submit Enquiry',
                      style: TextStyle(
                          fontSize:   15,
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
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              color:         Color(0xFF7C5CBF),
              letterSpacing: 1.2),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: Color(0xFFE0DAF0), thickness: 1),
        ),
      ],
    );
  }
}