import 'package:callme/provider/order_service.dart';
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
  /// 🚀 SUBMIT ENQUIRY
  /// =========================
  Future<void> submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedTime == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date & time")),
      );
      return;
    }

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final servicesList = widget.cart != null && widget.cart!.isNotEmpty
          ? widget.cart!
              .map((e) => "${e.name} x${e.quantity}")
              .toList()
          : [widget.serviceName];

      /// ✅ CALL COMMON ORDER SERVICE
      await OrderService.placeOrder(
        serviceType: widget.serviceName,
        services: servicesList,

        /// USER
        userId: user.uid,
        userName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),

        /// CREATED BY
        createdBy: user.uid,
        createdByRole: "user",

        /// LOCATION
        address: "Not Provided",

        /// SCHEDULE
        date: selectedDate!,
        time: selectedTime!.format(context),

        /// PAYMENT
        totalAmount: 0,

        /// ENQUIRY FLAG
        isEnquiry: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enquiry Submitted Successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      debugPrint("🔥 Enquiry Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  /// =========================
  /// 🎨 UI
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

                  const SizedBox(height: 25),

                  /// NAME
                  _inputField(
                    controller: nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (v) =>
                        v!.isEmpty ? "Enter your name" : null,
                  ),

                  const SizedBox(height: 15),

                  /// PHONE
                  _inputField(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboard: TextInputType.phone,
                    validator: (v) =>
                        v!.isEmpty ? "Enter phone number" : null,
                  ),

                  const SizedBox(height: 15),

                  /// EMAIL
                  _inputField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email,
                    keyboard: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

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

                  const SizedBox(height: 30),

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

  /// =========================
  /// HELPERS
  /// =========================

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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
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
    );
  }
}