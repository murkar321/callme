import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryPage extends StatefulWidget {
  final String serviceName;
  final List<dynamic>? cart; // optional (for multiple courses)

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

  /// 🔹 SUBMIT TO FIRESTORE
  Future<void> submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("enquiries").add({
        "serviceName": widget.serviceName,
        "courses": widget.cart?.map((e) => e.name).toList() ?? [],
        "userName": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "preferredDate": dateController.text,
        "createdAt": Timestamp.now(),
      });

      /// SUCCESS
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enquiry Submitted Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enquiry"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              /// SERVICE NAME
              Text(
                widget.serviceName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Enter your name" : null,
              ),

              const SizedBox(height: 15),

              /// PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Enter phone number" : null,
              ),

              const SizedBox(height: 15),

              /// EMAIL
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter email";
                  if (!v.contains("@")) return "Enter valid email";
                  return null;
                },
              ),

              const SizedBox(height: 15),

              /// DATE PICKER
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Preferred Date",
                  border: OutlineInputBorder(),
                ),
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
              ),

              const SizedBox(height: 25),

              /// SUBMIT BUTTON
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitEnquiry,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Enquiry"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}