import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/resorts_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/payment/payment_page.dart';

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
    with SingleTickerProviderStateMixin {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController  = TextEditingController();

  DateTime?  selectedDate;
  TimeOfDay? selectedTime;

  int adults   = 1;
  int children = 0;

  bool _isLoading         = false;
  bool _isLoadingProvider = true;

  // Provider resolved from Firestore
  String? _providerId;
  String? _providerName;
  String? _noProviderMessage;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  // ── Total ─────────────────────────────────────────────────────────────────
  double get totalAmount {
    final adultTotal    = widget.resort.price * adults;
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

    // Pre-fill phone from Firebase auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      final digits = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      _phoneController.text =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    // Provider resolution — use resort's own providerId as hint first
    final hint = widget.initialProviderId?.isNotEmpty == true
        ? widget.initialProviderId
        : (widget.resort.providerId.isNotEmpty ? widget.resort.providerId : null);

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
          .where('serviceType', isEqualTo: 'resort')
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
        return st == 'resort';
      }).firstOrNull;

      if (match != null) {
        _setProvider(match.id, match.data());
      } else {
        if (mounted) {
          setState(() {
            _noProviderMessage =
                'No approved resort provider available yet.\nPlease try again later.';
            _isLoadingProvider = false;
          });
        }
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
      _providerId        = id;
      _providerName      =
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
      backgroundColor: const Color(0xFFF7F8FC),
      body: FadeTransition(
        opacity: _fadeIn,
        child: _isLoadingProvider
            ? _buildLoadingState()
            : _noProviderMessage != null
                ? _buildNoProviderState()
                : _buildScrollBody(),
      ),
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
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Booking Summary
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Booking Summary'),
                      const SizedBox(height: 16),
                      _infoRow('Resort', widget.resort.name),
                      _infoRow('City', widget.resort.city),
                      _infoRow('Price Per Adult',
                          '₹${widget.resort.price.toStringAsFixed(0)}'),
                      _infoRow('Rating', '⭐ ${widget.resort.rating}'),
                      if (_providerName != null && _providerName!.isNotEmpty)
                        _infoRow('Provider', _providerName!),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Guests
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Guests'),
                      const SizedBox(height: 16),
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
                        subtitle:
                            '₹${(widget.resort.price / 2).toStringAsFixed(0)} each (50% off)',
                        value: children,
                        onMinus: () {
                          if (children > 0) setState(() => children--);
                        },
                        onPlus: () => setState(() => children++),
                      ),
                      const SizedBox(height: 16),
                      // Running total inside guests card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$adults adult${adults != 1 ? 's' : ''}'
                              '${children > 0 ? ' · $children child${children != 1 ? 'ren' : ''}' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Schedule
                _sectionCard(
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
                          selectedDate == null
                              ? 'Select Check-In Date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          style: TextStyle(
                            color: selectedDate == null
                                ? Colors.grey.shade500
                                : Colors.black87,
                            fontWeight: selectedDate != null
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
                          child: const Icon(Icons.access_time,
                              color: Colors.deepPurple),
                        ),
                        title: Text(
                          selectedTime == null
                              ? 'Select Check-In Time'
                              : selectedTime!.format(context),
                          style: TextStyle(
                            color: selectedTime == null
                                ? Colors.grey.shade500
                                : Colors.black87,
                            fontWeight: selectedTime != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Guest Details — name, phone, note only (no address)
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Guest Details'),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _phoneController,
                        hint: 'Mobile Number',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: _noteController,
                        hint: 'Special Request (optional)',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Total amount card
                _sectionCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Proceed button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _providerId == null)
                        ? null
                        : _payNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      disabledBackgroundColor:
                          Colors.deepPurple.withOpacity(0.4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Proceed To Payment',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 30),
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
        if (_providerName != null && _providerName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
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

  // ==========================================================================
  // PAYMENT FLOW
  // ==========================================================================

  Future<void> _payNow() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnack('Please fill your name and phone number');
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
        serviceType:   'resort',
        services:      [widget.resort.name],
        userId:        user.uid,
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user.email ?? '',
        createdBy:     user.uid,
        createdByRole: 'user',
        address:       '${widget.resort.name}, ${widget.resort.location}',
        note:          _noteController.text.trim(),
        date:          selectedDate!,
        time:          selectedTime!.format(context),
        totalAmount:   totalAmount,
        adults:        adults,
        children:      children,
        visitType:     'Resort',
        providerId:    _providerId!,
        providerName:  _providerName ?? '',
        isEnquiry:     false,
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
          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
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
          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
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

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

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
                            ? Colors.deepPurple
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
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.add,
                        size: 18, color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.deepPurple),
          ),
        ),
      );
}
