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

  /// CONTROLLERS
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  /// BOOKING DATA
  int adults = 1;
  int children = 0;

  DateTime? date;
  TimeOfDay? time;

  /// SUCCESS STATE
  bool isSuccess = false;
  String bookingId = "";

  /// PRICE
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

        /// 🏨 RESORT NAME
        Text(
          widget.resort.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        /// 👥 GUESTS
        _counter("Adults", adults, (v) {
          if (v >= 1) setState(() => adults = v);
        }),
        _counter("Children", children, (v) {
          if (v >= 0) setState(() => children = v);
        }),

        const SizedBox(height: 15),

        /// 📅 DATE
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
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

        /// ⏰ TIME
        ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          tileColor: Colors.grey.shade100,
          title: Text(
            time == null
                ? "Select Time *"
                : time!.format(context),
          ),
          trailing: const Icon(Icons.access_time),
          onTap: _pickTime,
        ),

        const SizedBox(height: 15),

        /// 👤 USER DETAILS
        _field(name, "Full Name *"),
        _field(phone, "Phone *"),
        _field(email, "Email"),
        _field(address, "Address *"),

        const SizedBox(height: 15),

        /// 💰 TOTAL
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.green.shade50,
          ),
          child: Text(
            "Total: ₹${total.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// 🚀 BUTTON
        ElevatedButton(
          onPressed: _validateAndPay,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
          ),
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
          const Icon(Icons.check_circle,
              size: 90, color: Colors.green),

          const SizedBox(height: 15),

          const Text(
            "Booking Confirmed!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text("Booking ID: $bookingId"),

          const SizedBox(height: 20),

          const Text("Redirecting to home..."),
        ],
      ),
    );
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

  /// ================= LOGIC =================

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

  void _validateAndPay() {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        address.text.isEmpty ||
        date == null ||
        time == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
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

    if (success == true) {
      _save();
    }
  }

  /// 🔥 FINAL SAVE + NAVIGATION
  void _save() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      final doc = await OrderService.placeOrder(
        serviceType: "Resort",
        services: [widget.resort.name],

        userId: user.uid,
        userName: name.text,
        phone: phone.text,
        email: email.text,

        createdBy: user.uid,
        createdByRole: "user",

        address: address.text,

        date: date!,
        time: time!.format(context),

        totalAmount: total,

        /// ✅ ONLY RESORT USES THIS
        adults: adults,
        children: children,
        visitType: "resort",

        providerId: widget.resort.providerId,
      );

      setState(() {
        isSuccess = true;
        bookingId = doc.id;
      });

      /// ✅ NAVIGATE TO HOME (BOTTOM NAV)
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
}