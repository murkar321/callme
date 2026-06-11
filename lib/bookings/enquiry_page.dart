import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

class _EnquiryPageState extends State<EnquiryPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController  = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading         = false;
  bool isLoadingProvider = true;

  // Resolved from Firestore on initState
  String? _providerId;
  String? _noProviderMessage;

  // ─── INIT ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ─── LOOK UP APPROVED PROVIDER FOR THIS SERVICE TYPE ────────
  Future<void> _loadProvider() async {
    if (mounted) setState(() { isLoadingProvider = true; _noProviderMessage = null; });

    try {
      final normalised = serviceType;

      // Try exact lowercase match first
      var snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: normalised)
          .where('status',      isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        // Fallback: fetch all approved and match case-insensitively
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
              'No approved provider available for "${widget.serviceName}" yet. '
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
    debugPrint('[EnquiryPage] provider resolved: id=$_providerId');
  }

  // ─── HELPERS ────────────────────────────────────────────────
  String get serviceType => widget.serviceName.trim().toLowerCase();

  List<String> get servicesList {
    if (widget.cart != null && widget.cart!.isNotEmpty) {
      return widget.cart!
          .map((e) => '${e.name} x${e.quantity}')
          .toList();
    }
    return [widget.serviceName];
  }

  // ─── SUBMIT ─────────────────────────────────────────────────
  Future<void> submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      _show('Please select date & time');
      return;
    }

    if (_providerId == null || _providerId!.isEmpty) {
      _show('No provider available for this service yet.');
      return;
    }

    if (isLoading) return;
    if (mounted) setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

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

        providerId:    _providerId!, providerName: 'service provider',   // ← resolved from Firestore, never empty
      );

      // Clear cart if this was a cart-based enquiry
      if (widget.cart != null && widget.cart!.isNotEmpty) {
        Cart.clear(widget.serviceName);
      }

      if (!mounted) return;
      _show('Enquiry submitted successfully ✅');
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      _show('Error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ─── UI HELPERS ─────────────────────────────────────────────
  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      firstDate:   DateTime.now(),
      lastDate:    DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => selectedDate = picked);
  }

  void _pickTime() async {
    final t = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null && mounted) setState(() => selectedTime = t);
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller:   controller,
        validator:    validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText:  label,
          filled:     true,
          fillColor:  const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title:           const Text('Enquiry'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation:       0,
      ),
      body: isLoadingProvider
          ? const Center(child: CircularProgressIndicator())
          : _noProviderMessage != null
              ? _noProviderState()
              : _formBody(),
    );
  }

  // ─── NO PROVIDER STATE ──────────────────────────────────────
  Widget _noProviderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              _noProviderMessage ?? 'No provider available',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:    Colors.grey.shade600,
                  fontSize: 15,
                  height:   1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProvider,
              icon:      const Icon(Icons.refresh_rounded),
              label:     const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE91BA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FORM BODY — UI unchanged ────────────────────────────────
  Widget _formBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color:      Colors.grey.shade300,
                blurRadius: 12,
                offset:     const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Header
                Text(
                  widget.serviceName,
                  style: const TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text('Request callback / visit',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                // Services preview
                if (widget.cart != null && widget.cart!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin:  const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color:        Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: servicesList
                          .map((e) => Text('• $e'))
                          .toList(),
                    ),
                  ),

                // Fields
                _input(
                  controller: nameController,
                  label:      'Full Name',
                  icon:       Icons.person,
                  validator:  (v) => (v == null || v.isEmpty)
                      ? 'Enter your name'
                      : null,
                ),
                _input(
                  controller: phoneController,
                  label:      'Phone Number',
                  icon:       Icons.phone,
                  keyboard:   TextInputType.phone,
                  validator:  (v) => (v == null || v.isEmpty)
                      ? 'Enter phone number'
                      : null,
                ),
                _input(
                  controller: emailController,
                  label:      'Email (optional)',
                  icon:       Icons.email,
                  keyboard:   TextInputType.emailAddress,
                ),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:        const Icon(Icons.calendar_today),
                  title: Text(
                    selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                  onTap: _pickDate,
                ),

                // Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:        const Icon(Icons.access_time),
                  title: Text(
                    selectedTime == null
                        ? 'Select Time'
                        : selectedTime!.format(context),
                  ),
                  onTap: _pickTime,
                ),

                const SizedBox(height: 25),

                // Submit
                SizedBox(
                  width:  double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitEnquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAE91BA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('Submit Enquiry',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

