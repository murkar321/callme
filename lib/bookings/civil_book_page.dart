import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';

class CivilBookingPage extends StatefulWidget {
  final String serviceName;

  /// Pass the providerId of the civil service provider.
  /// Required so OrderService fetches providerName & providerUserId from
  /// Firestore and sends the FCM notification correctly.
  final String providerId;

  const CivilBookingPage({
    super.key,
    required this.serviceName,
    required this.providerId, // ← NEW: pass from caller screen
  });

  @override
  State<CivilBookingPage> createState() => _CivilBookingPageState();
}

class _CivilBookingPageState extends State<CivilBookingPage>
    with SingleTickerProviderStateMixin {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController    = TextEditingController();

  DateTime?  _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading         = false;
  bool _isGettingLocation = false;

  late final AnimationController _animController;
  late final Animation<double>    _fadeIn;

  static const _accent = Color(0xFF5B67F1);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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
      backgroundColor: const Color(0xFFF5F7FC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailsCard(),
                    const SizedBox(height: 20),
                    _buildDateTimeCard(),
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
          colors: [Color(0xFF5B67F1), Color(0xFF7B86FF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            widget.serviceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your project requirements',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Details',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _input(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _phoneController,
            hint: 'Mobile Number',
            icon: Icons.phone,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _input(
            controller: _addressController,
            hint: 'Project Address',
            icon: Icons.location_on,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : _getLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isGettingLocation ? 'Getting Location…' : 'Use Current Location',
              ),
            ),
          ),
          const SizedBox(height: 14),
          _input(
            controller: _noteController,
            hint: 'Describe your requirement (optional)',
            icon: Icons.description,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DATE / TIME CARD
  // ==========================================================

  Widget _buildDateTimeCard() {
    return Row(
      children: [
        Expanded(
          child: _pickerCard(
            icon: Icons.calendar_today,
            title: 'Date',
            value: _selectedDate == null
                ? 'Select'
                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
            selected: _selectedDate != null,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _pickerCard(
            icon: Icons.access_time,
            title: 'Time',
            value: _selectedTime == null
                ? 'Select'
                : _selectedTime!.format(context),
            selected: _selectedTime != null,
            onTap: _pickTime,
          ),
        ),
      ],
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
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withOpacity(0.5),
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
                    'Submit Enquiry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SUBMIT — ENQUIRY ORDER
  // ==========================================================

  Future<void> _submit() async {
    // ── Validation ──────────────────────────────────────────
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showPopup('Please fill your name, phone, and address', false);
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showPopup('Please select a preferred date and time', false);
      return;
    }

    if (widget.providerId.isEmpty) {
      _showPopup('Provider information missing. Please try again.', false);
      return;
    }

    // ── Auth ────────────────────────────────────────────────
    // Civil/enquiry bookings allow guest submission, but we strongly prefer
    // a logged-in user so the order is linked to a real uid.
    final user = FirebaseAuth.instance.currentUser;
    final uid  = user?.uid ?? '';

    setState(() => _isLoading = true);

    try {
      // ── Place enquiry via OrderService ─────────────────────
      // isEnquiry: true → status = 'enquiry', payment.paid = false
      // totalAmount: 0  → quote will be given by the provider
      // OrderService resolves providerName & providerUserId from Firestore
      // using providerId — no need to pass them manually.
      await OrderService.placeOrder(
        serviceType:   widget.serviceName.toLowerCase(),
        services:      [widget.serviceName],
        userId:        uid,
        userName:      _nameController.text.trim(),
        phone:         _phoneController.text.trim(),
        email:         user?.email ?? '',
        createdBy:     uid,
        createdByRole: 'user',
        address:       _addressController.text.trim(),
        note:          _noteController.text.trim(),
        date:          _selectedDate!,
        time:          _selectedTime!.format(context),
        totalAmount:   0,
        visitType:     'Site Visit',
        providerId:    widget.providerId,
        isEnquiry:     true,
        providerName:  '', // resolved internally by OrderService
      );

      if (!mounted) return;

      // ── Success ─────────────────────────────────────────────
      _showPopup('Enquiry Submitted!\nWe will contact you shortly.', true);

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Navigate home if logged in, otherwise just pop
      if (user != null) {
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
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[CivilBooking] placeOrder error: $e');
      _showPopup('Something went wrong. Please try again.', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> _getLocation() async {
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showPopup('Location permission denied', false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isNotEmpty) {
        final p = places.first;
        _addressController.text =
            '${p.street ?? ''}, ${p.locality ?? ''}, '
            '${p.administrativeArea ?? ''} ${p.postalCode ?? ''}'
                .replaceAll(RegExp(r',\s*,'), ',')
                .trim();
      }
    } catch (e) {
      debugPrint('[CivilBooking] location error: $e');
      _showPopup('Could not fetch location', false);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
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
          colorScheme: const ColorScheme.light(primary: _accent),
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
          colorScheme: const ColorScheme.light(primary: _accent),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: child,
      );

  Widget _pickerCard({
    required IconData icon,
    required String title,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? _accent.withOpacity(0.4) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: _accent),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? _accent : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: _accent),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
      );
}