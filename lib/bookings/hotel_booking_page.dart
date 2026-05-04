import 'package:callme/data/hotel_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart.dart';

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

  List<CartItem> get cart => Cart.getItems("Hotel");

  int get total {
    int sum = 0;
    for (var item in cart) {
      sum += item.price * item.quantity;
    }
    return sum;
  }

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
      appBar: AppBar(title: const Text("Hotel Booking")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// HOTEL INFO
          Card(
            child: ListTile(
              leading: const Icon(Icons.hotel),
              title: Text(widget.hotel.name),
              subtitle: Text(widget.hotel.location),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Your Selection"),

          /// CART ITEMS
          Card(
            child: Column(
              children: cart.map((e) => ListTile(
                title: Text(e.name),
                subtitle: Text("Qty: ${e.quantity}"),
                trailing: Text("₹${e.price * e.quantity}"),
              )).toList(),
            ),
          ),

          /// TOTAL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount"),
              Text("₹$total"),
            ],
          ),

          const SizedBox(height: 20),

          /// DATE
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              date == null
                  ? "Select Date"
                  : "${date!.day}/${date!.month}/${date!.year}",
            ),
            onTap: _pickDate,
          ),

          /// TIME
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              time == null ? "Select Time" : time!.format(context),
            ),
            onTap: _pickTime,
          ),

          const SizedBox(height: 20),

          /// INPUTS
          TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: address, decoration: const InputDecoration(labelText: "Address")),

          const SizedBox(height: 30),

          /// BUTTON
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text("Confirm Booking"),
          )
        ],
      ),
    );
  }

  /// ================= SUBMIT =================
  void _submit() async {
    final user = FirebaseAuth.instance.currentUser;

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

    if (user == null) {
      _show("User not logged in");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "hotel", // ✅ IMPORTANT

        services: cart
            .map((e) => "${e.name} x${e.quantity}")
            .toList(),

        /// USER
        userId: user.uid,
        userName: name.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),

        /// CREATOR
        createdBy: user.uid,
        createdByRole: "user",

        /// LOCATION
        address: address.text.trim(),
        note: "",

        /// SCHEDULE
        date: date!,
        time: time!.format(context),

        /// PAYMENT
        totalAmount: total.toDouble(),

        /// BOOKING
        isEnquiry: false,
      );

      Cart.clear("Hotel");

      _show("Booking Confirmed ✅");

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavPage(
            userPhone: phone.text,
            userEmail: email.text,
          ),
        ),
        (route) => false,
      );

    } catch (e) {
      _show("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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