import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/provider/order_service.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/screens/upi_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;
  final ServiceProduct? product;
  final List<CartItem>? cart;

  const BookingPage({
    super.key,
    required this.serviceName,
    this.product,
    this.cart, required List<CartItem> products,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  /// CONTROLLERS
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final note = TextEditingController();

  DateTime? date;
  TimeOfDay? time;

  /// SUCCESS STATE
  bool isSuccess = false;
  String bookingId = "";

  List<CartItem> get cartItems =>
      widget.cart ?? Cart.getItems(widget.serviceName);

  bool get isCart => cartItems.isNotEmpty;
  bool get isSingle => widget.product != null && cartItems.isEmpty;

  double get total {
    if (isCart) return Cart.getTotal(widget.serviceName).toDouble();
    if (isSingle) return widget.product!.calculatedFinalPrice.toDouble();
    return 0;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName)),
      body: isSuccess ? _successView() : _bookingForm(),
    );
  }

  /// ================= BOOKING FORM =================

  Widget _bookingForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [

          _field(name, "Full Name *"),
          _field(phone, "Phone *"),
          _field(email, "Email"),
          _field(address, "Address *"),

          ListTile(
            title: Text(
              date == null
                  ? "Select Date *"
                  : DateFormat('dd MMM yyyy').format(date!),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),

          ListTile(
            title: Text(
              time == null ? "Select Time *" : time!.format(context),
            ),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),

          _field(note, "Note"),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.green.shade50,
            ),
            child: Text(
              "Total: ₹$total",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _validateAndPay,
            child: const Text("Proceed to Payment"),
          )
        ],
      ),
    );
  }

  /// ================= SUCCESS VIEW =================

  Widget _successView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          const SizedBox(height: 40),

          const Icon(Icons.check_circle,
              color: Colors.green, size: 100),

          const SizedBox(height: 20),

          const Text(
            "Booking Confirmed!",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text("Booking ID: $bookingId"),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _row("Name", name.text),
                  _row("Phone", phone.text),
                  _row("Date",
                      DateFormat('dd MMM yyyy').format(date!)),
                  _row("Time", time!.format(context)),
                  _row("Address", address.text),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Services",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ..._servicesList(),

                  const Divider(),

                  Text("Total: ₹$total",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _servicesList() {
    if (isCart) {
      return cartItems
          .map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.name),
                trailing: Text("x${e.quantity}"),
              ))
          .toList();
    } else {
      return [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(widget.product?.name ?? ""),
        )
      ];
    }
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$k: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  /// 🔥 FINAL SAVE (PROPER STRUCTURE)
  void _save() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("User not logged in");

      final services = isCart
          ? cartItems.map((e) => "${e.name} x${e.quantity}").toList()
          : [widget.product?.name ?? widget.serviceName];

      final docRef = await OrderService.placeOrder(
        serviceType: widget.serviceName,
        services: services,

        userId: user.uid,
        userName: name.text,
        phone: phone.text,
        email: email.text,

        address: address.text,
        note: note.text,

        date: date!,
        time: time!.format(context),

        totalAmount: total,

        /// ✅ FIXED
        createdBy: user.uid,
        createdByRole: "user",

        providerId: null, isEnquiry: true,
      );

      setState(() {
        isSuccess = true;
        bookingId = docRef.id;
      });

      if (isCart) Cart.clear(widget.serviceName);

      /// 🔥 REDIRECT TO HOME WITH NAV
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