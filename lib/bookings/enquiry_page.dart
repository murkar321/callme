import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
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

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;

  /// =========================
  /// 🔥 NORMALIZED SERVICE TYPE
  /// =========================
  String get serviceType =>
      widget.serviceName.trim().toLowerCase();

  /// =========================
  /// 📦 SAFE SERVICES LIST
  /// =========================
  List<String> get servicesList {
    if (widget.cart != null && widget.cart!.isNotEmpty) {
      return widget.cart!
          .map((e) => "${e.name} x${e.quantity}")
          .toList();
    }
    return [widget.serviceName];
  }

  /// =========================
  /// 🚀 SUBMIT
  /// =========================
  Future<void> submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null || selectedTime == null) {
      _show("Please select date & time");
      return;
    }

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      await OrderService.placeOrder(
        serviceType: serviceType,
        services: servicesList,

        /// USER
        userId: user.uid,
        userName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),

        /// CREATOR
        createdBy: user.uid,
        createdByRole: "user",

        /// LOCATION
        address: "Not Provided",

        /// SCHEDULE
        date: selectedDate!,
        time: selectedTime!.format(context),

        /// 💰 ENQUIRY (NO PAYMENT)
        totalAmount: 0,

        /// 🔥 IMPORTANT
        isEnquiry: true,
      );

      /// 🔥 CLEAR CART (THIS WAS MISSING)
      if (widget.cart != null && widget.cart!.isNotEmpty) {
        Cart.clear(widget.serviceName);
      }

      if (!mounted) return;

      _show("Enquiry submitted successfully ✅");

      Navigator.pop(context);

    } catch (e) {
      _show("Error: $e");
    }

    setState(() => isLoading = false);
  }

  /// =========================
  /// UI HELPERS
  /// =========================

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      setState(() => selectedTime = t);
    }
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
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Enquiry"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Request callback / visit",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  /// SERVICES PREVIEW (NEW UX)
                  if (widget.cart != null && widget.cart!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: servicesList
                            .map((e) => Text("• $e"))
                            .toList(),
                      ),
                    ),

                  /// NAME
                  _input(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter your name" : null,
                  ),

                  /// PHONE
                  _input(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboard: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter phone number" : null,
                  ),

                  /// EMAIL
                  _input(
                    controller: emailController,
                    label: "Email (optional)",
                    icon: Icons.email,
                    keyboard: TextInputType.emailAddress,
                  ),

                  /// DATE
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    ),
                    onTap: _pickDate,
                  ),

                  /// TIME
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      selectedTime == null
                          ? "Select Time"
                          : selectedTime!.format(context),
                    ),
                    onTap: _pickTime,
                  ),

                  const SizedBox(height: 25),

                  /// SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitEnquiry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAE91BA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Enquiry",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}