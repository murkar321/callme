import 'package:flutter/material.dart';

class CivilBookingPage extends StatefulWidget {
  final String serviceName;

  const CivilBookingPage({super.key, required this.serviceName});

  @override
  State<CivilBookingPage> createState() => _CivilBookingPageState();
}

class _CivilBookingPageState extends State<CivilBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final pincodeController = TextEditingController();

  final requestController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book ${widget.serviceName}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// 👤 CUSTOMER DETAILS
              _sectionTitle("Customer Details"),
              _input(nameController, "Full Name"),
              _input(phoneController, "Mobile Number"),
              _input(emailController, "Email ID"),

              /// 📍 ADDRESS
              _sectionTitle("Site Address"),
              _input(addressController, "Full Address"),
              _input(cityController, "City"),
              _input(pincodeController, "Pincode"),

              /// 📅 DATE & TIME
              _sectionTitle("Preferred Site Visit"),
              ListTile(
                title: Text(selectedDate == null
                    ? "Select Date"
                    : selectedDate.toString().split(" ")[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                title: Text(selectedTime == null
                    ? "Select Time"
                    : selectedTime!.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),

              /// ⭐ REQUEST
              _sectionTitle("Special Request"),
              _input(requestController, "Optional Message", maxLines: 3),

              const SizedBox(height: 10),

              /// 📌 NOTE
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.yellow.shade100,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📌 Note",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("• Site inspection before quotation"),
                    Text("• 3–5 budget options provided"),
                    Text("• Work starts after confirmation"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// SUBMIT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Submit Booking"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 UI HELPERS
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (val) =>
            val == null || val.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// 📅 PICKERS
  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  /// 🚀 SUBMIT
  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Submitted")),
      );
    }
  }
}