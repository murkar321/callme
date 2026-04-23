import 'package:callme/provider/order_service.dart';
import 'package:flutter/material.dart';
import '../data/salon_data.dart';

class SalonBookingPage extends StatefulWidget {
  final List<SalonService> services;

  const SalonBookingPage({super.key, required this.services, required Map<String, String> visitTypeMap});

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {

  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salon Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            ...widget.services.map((s) => ListTile(
              title: Text(s.name),
              trailing: Text("₹${s.finalPrice}"),
            )),

            TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: address, decoration: const InputDecoration(labelText: "Address")),

            ElevatedButton(
              onPressed: _submit,
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
  }

  void _submit() async {
    await OrderService.placeOrder(
      serviceType: "Salon",
      services: widget.services.map((e) => e.name).toList(),
      userName: "Salon User",
      phone: phone.text,
      email: email.text,
      address: address.text,
      note: "",
      date: DateTime.now(),
      time: TimeOfDay.now().format(context),
      totalAmount: 0,
      visitType: "Home/Salon",
    );

    Navigator.pop(context);
  }
}