import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/resorts_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:callme/screens/upi_payment.dart';

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

  bool isLoading = false;

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.resort.name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.resort.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.resort.location),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            child: Column(
              children: [
                _counter("Adults", adults, (v) {
                  if (v >= 1) setState(() => adults = v);
                }),
                _counter("Children", children, (v) {
                  if (v >= 0) setState(() => children = v);
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    date == null
                        ? "Select Date"
                        : "${date!.day}/${date!.month}/${date!.year}",
                  ),
                  onTap: _pickDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    time == null ? "Select Time" : time!.format(context),
                  ),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            child: Column(
              children: [
                _field(name, "Full Name"),
                _field(phone, "Phone"),
                _field(email, "Email"),
                _field(address, "Address"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "₹${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE91BA),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Pay & Book"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        address.text.isEmpty ||
        date == null ||
        time == null) {
      _show("Fill required details");
      return;
    }

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

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _show("User not logged in");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "resort",
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

      if (!mounted) return;

      _show("Booking Confirmed ✅");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: phone.text.trim(),
            userEmail: email.text.trim(),
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      _show("Error: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _counter(String title, int value, Function(int) onChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Row(
          children: [
            IconButton(
              onPressed: () => onChange(value - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text("$value"),
            IconButton(
              onPressed: () => onChange(value + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}