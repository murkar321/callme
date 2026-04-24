import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final dateController = TextEditingController();

  bool isLoading = false;

  /// 🔹 CONVERT DATE (dd/MM/yyyy → yyyy-MM-dd)
  String _convertToIso(String input) {
    final parts = input.split('/');
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  /// 🔹 SUBMIT → NOW STORES IN ORDERS COLLECTION
  Future<void> submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final phone = phoneController.text.trim();

      await FirebaseFirestore.instance.collection("orders").add({
        /// 🔹 SERVICE INFO
        "serviceType": widget.serviceName,
        "services": widget.cart?.map((e) => e.name).toList() ?? [],

        /// 🔹 USER (IMPORTANT FOR MY ORDERS + RULES)
        "user": {
          "name": nameController.text.trim(),
          "phone": phone,
          "email": emailController.text.trim(),
        },

        /// 🔹 SCHEDULE
        "schedule": {
          "date": dateController.text.isNotEmpty
              ? Timestamp.fromDate(
                  DateTime.parse(_convertToIso(dateController.text)),
                )
              : null,
          "time": "",
        },

        /// 🔹 LOCATION (EMPTY FOR NOW)
        "location": {
          "address": "",
          "lat": null,
          "lng": null,
        },

        /// 🔹 PAYMENT (ENQUIRY → ₹0)
        "payment": {
          "totalAmount": 0,
          "method": "enquiry",
        },

        /// 🔹 ORDER STATUS
        "status": "pending",

        /// 🔹 PROVIDER (NOT ASSIGNED YET)
        "providerId": null,

        /// 🔹 TIMESTAMP
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enquiry Submitted Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("🔥 Error submitting enquiry: $e");
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
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Enquiry"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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

                  /// 🔹 HEADER
                  Text(
                    widget.serviceName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Fill details to get a callback",
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
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter email";
                      if (!v.contains("@")) return "Enter valid email";
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  /// DATE PICKER
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        initialDate: DateTime.now(),
                      );

                      if (picked != null) {
                        dateController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      }
                    },
                    child: AbsorbPointer(
                      child: _inputField(
                        controller: dateController,
                        label: "Preferred Date",
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitEnquiry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
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

  /// 🔹 COMMON INPUT FIELD
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