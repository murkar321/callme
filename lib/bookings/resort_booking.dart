import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/screens/upi_payment.dart';
import '../data/resorts_data.dart';
import '../provider/order_service.dart';

class ResortBookingPage extends StatefulWidget {
  final Resort resort;

  const ResortBookingPage({
    super.key,
    required this.resort,
  });

  @override
  State<ResortBookingPage> createState() => _ResortBookingPageState();
}

class _ResortBookingPageState extends State<ResortBookingPage> {

  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  int adults = 1;
  int children = 0;

  DateTime? date;
  TimeOfDay? time;

  bool isSuccess = false;
  String bookingId = "";

  double get total =>
      (widget.resort.price * adults) +
      ((widget.resort.price / 2) * children);

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.resort.name)),
      body: isSuccess ? _successUI() : _formUI(),
    );
  }

  /// ================= FORM =================
  Widget _formUI() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        Text(widget.resort.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

        const SizedBox(height: 15),

        _counter("Adults", adults, (v) {
          if (v >= 1) setState(() => adults = v);
        }),

        _counter("Children", children, (v) {
          if (v >= 0) setState(() => children = v);
        }),

        const SizedBox(height: 15),

        ListTile(
          tileColor: Colors.grey.shade100,
          title: Text(
            date == null
                ? "Select Date *"
                : "${date!.day}/${date!.month}/${date!.year}",
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _pickDate,
        ),

        const SizedBox(height: 10),

        ListTile(
          tileColor: Colors.grey.shade100,
          title: Text(
            time == null ? "Select Time *" : time!.format(context),
          ),
          trailing: const Icon(Icons.access_time),
          onTap: _pickTime,
        ),

        const SizedBox(height: 15),

        _field(name, "Full Name *"),
        _field(phone, "Phone *"),
        _field(email, "Email"),
        _field(address, "Address *"),

        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Total: ₹${total.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _validateAndPay,
          child: const Text("Pay & Book"),
        ),
      ],
    );
  }

  /// ================= SUCCESS =================
  Widget _successUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 90, color: Colors.green),
          const SizedBox(height: 15),
          const Text("Booking Confirmed!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Booking ID: $bookingId"),
        ],
      ),
    );
  }

  /// ================= LOGIC =================

  void _validateAndPay() {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        address.text.isEmpty ||
        date == null ||
        time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill required fields")),
      );
      return;
    }
    _pay();
  }

  void _pay() async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(amount: total),
      ),
    );

    if (success == true) _save();
  }

  void _save() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("User not logged in");

      final doc = await OrderService.placeOrder(
        serviceType: "resort", // ✅ IMPORTANT

        services: [widget.resort.name],

        userId: user.uid,
        userName: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),

        createdBy: user.uid,
        createdByRole: "user",

        address: address.text.trim(),

        date: date!,
        time: time!.format(context),

        totalAmount: total,

        adults: adults,
        children: children,
        visitType: "resort",

        providerId: widget.resort.providerId,

        isEnquiry: false,
      );

      setState(() {
        isSuccess = true;
        bookingId = doc.id;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => BottomNavPage(
              userPhone: user.phoneNumber ?? "",
              userEmail: user.email ?? "",
            ),
          ),
          (route) => false,
        );
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ================= UI HELPERS =================

  Widget _counter(String title, int value, Function(int) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () => onChange(value - 1),
            ),
            Text(value.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChange(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (d != null) setState(() => date = d);
  }

  void _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) setState(() => time = t);
  }
}