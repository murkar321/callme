import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/data/hotel_data.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';

class HotelBookingPage extends StatefulWidget {
  final HotelRoom hotel;
  final List<dynamic> products;

  const HotelBookingPage({
    super.key,
    required this.hotel,
    required this.products,
  });

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  DateTime? date;
  TimeOfDay? time;

  bool isLoading = false;

  List<CartItem> get cartItems => Cart.getItems("Hotel");

  double get total => Cart.getTotal("Hotel").toDouble();

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
    final cart = cartItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("Hotel Booking"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.hotel),
              ),
              title: Text(
                widget.hotel.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(widget.hotel.location),
            ),
          ),

          const SizedBox(height: 16),

          _title("Selected Rooms"),

          _card(
            child: cart.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("No items selected"),
                  )
                : Column(
                    children: cart
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.name),
                            subtitle: Text("Qty: ${e.quantity}"),
                            trailing: Text(
                              "₹${e.price * e.quantity}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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

          const SizedBox(height: 16),

          _title("Schedule"),

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

          _title("Guest Details"),

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

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE91BA),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Confirm Booking"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (name.text.isEmpty ||
        phone.text.isEmpty ||
        email.text.isEmpty ||
        address.text.isEmpty) {
      _show("Fill all details");
      return;
    }

    if (date == null || time == null) {
      _show("Select date & time");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _show("User not logged in");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "hotel",
        services: cartItems.map((e) => "${e.name} x${e.quantity}").toList(),
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
        isEnquiry: false,
      );

      /// IMPORTANT FIX
      Cart.clear("Hotel");

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

  Widget _title(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
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