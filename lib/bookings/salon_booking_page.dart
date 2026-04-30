import 'package:callme/provider/order_service.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;

  const SalonBookingPage({
    super.key,
    required this.services,
    required Map<dynamic, dynamic> visitTypeMap,
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  String visitType = "Home";
  bool isLoading = false;

  int get totalAmount {
    int total = 0;
    for (var item in widget.services) {
      total += item.finalPrice;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salon Booking")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Selected Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Card(
            child: Column(
              children: widget.services.map((s) => ListTile(
                title: Text(s.name),
                subtitle: Text(s.time),
                trailing: Text("₹${s.finalPrice}"),
              )).toList(),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount"),
              Text("₹$totalAmount"),
            ],
          ),

          const SizedBox(height: 20),

          const Text("Service Type"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Home"),
                selected: visitType == "Home",
                onSelected: (_) => setState(() => visitType = "Home"),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("Salon"),
                selected: visitType == "Salon",
                onSelected: (_) => setState(() => visitType = "Salon"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text("Your Details"),

          const SizedBox(height: 10),

          TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone")),
          const SizedBox(height: 10),
          TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
          const SizedBox(height: 10),

          if (visitType == "Home")
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

    if (phone.text.isEmpty || email.text.isEmpty) {
      _show("Fill all details");
      return;
    }

    if (visitType == "Home" && address.text.isEmpty) {
      _show("Address required");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "Salon",
        services: widget.services.map((e) => e.name).toList(),
        userName: "Salon User",
        phone: phone.text,
        email: email.text,
        address: visitType == "Home" ? address.text : "Salon Visit",
        note: "",
        date: DateTime.now(),
        time: TimeOfDay.now().format(context),
        totalAmount: totalAmount.toDouble(),
        visitType: visitType,

        /// ✅ FIX
        userId: user?.uid ?? "",
        createdBy: user?.phoneNumber ?? phone.text,
        createdByRole: "user",
      );

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
}