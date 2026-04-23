import 'package:callme/data/hotel_data.dart';
import 'package:callme/provider/order_service.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({super.key, required HotelRoom hotel, required List<dynamic> products});

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

  List<CartItem> get cart => Cart.getItems("Hotel");

  int get total =>
      cart.fold(0, (sum, e) => sum + e.price * e.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hotel Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            _field(name, "Name"),
            _field(phone, "Phone"),
            _field(email, "Email"),
            _field(address, "Address"),

            ListTile(
              title: Text(date == null ? "Select Date" : date.toString()),
              onTap: _pickDate,
            ),
            ListTile(
              title: Text(time == null ? "Select Time" : time!.format(context)),
              onTap: _pickTime,
            ),

            const SizedBox(height: 20),

            Text("Total ₹$total"),

            ElevatedButton(
              onPressed: _submit,
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String t) =>
      TextField(controller: c, decoration: InputDecoration(labelText: t));

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

  void _submit() async {
    await OrderService.placeOrder(
      serviceType: "Hotel",
      services: cart.map((e) => "${e.name} x${e.quantity}").toList(),
      userName: name.text,
      phone: phone.text,
      email: email.text,
      address: address.text,
      note: "",
      date: date!,
      time: time!.format(context),
      totalAmount: total.toDouble(),
    );

    Cart.clear("Hotel");

    Navigator.pop(context);
  }
}