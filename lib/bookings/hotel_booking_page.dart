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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hotel Booking")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Card(
            child: ListTile(
              leading: const Icon(Icons.hotel),
              title: Text(widget.hotel.name),
              subtitle: Text(widget.hotel.location),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Your Selection"),

          Card(
            child: Column(
              children: cart.map((e) => ListTile(
                title: Text(e.name),
                subtitle: Text("Qty: ${e.quantity}"),
                trailing: Text("₹${e.price * e.quantity}"),
              )).toList(),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount"),
              Text("₹$total"),
            ],
          ),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(date == null ? "Select Date" : "${date!.day}/${date!.month}/${date!.year}"),
            onTap: _pickDate,
          ),

          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(time == null ? "Select Time" : time!.format(context)),
            onTap: _pickTime,
          ),

          const SizedBox(height: 20),

          TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone")),
          TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
          TextField(controller: address, decoration: const InputDecoration(labelText: "Address")),

          const SizedBox(height: 30),

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

  void _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (name.text.isEmpty || phone.text.isEmpty || email.text.isEmpty || address.text.isEmpty) {
      _show("Fill all details");
      return;
    }

    if (date == null || time == null) {
      _show("Select date & time");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "Hotel",
        services: cart.map((e) => "${e.name} x${e.quantity}").toList(),

        /// ✅ FIX
        userId: user?.uid ?? "",
        createdBy: user?.phoneNumber ?? phone.text,
        createdByRole: "user",

        userName: name.text,
        phone: phone.text,
        email: email.text,
        address: address.text,
        note: "",
        date: date!,
        time: time!.format(context),
        totalAmount: total.toDouble(), isEnquiry: true,
      );

      Cart.clear("Hotel");

      _show("Booking Confirmed ✅");

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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