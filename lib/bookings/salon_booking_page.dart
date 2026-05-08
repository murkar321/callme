import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';

class SalonBookingPage extends StatefulWidget {
  final List<dynamic> cartItems;

  const SalonBookingPage({
    super.key,
    required this.cartItems,
  });

  @override
  State<SalonBookingPage> createState() => _SalonBookingPageState();
}

class _SalonBookingPageState extends State<SalonBookingPage> {

  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();

  bool isLoading = false;

  /// ================= VISIT TYPE =================
  bool get hasHome =>
      widget.cartItems.any((e) => e.id.toString().contains("Home"));

  bool get hasSalon =>
      widget.cartItems.any((e) => e.id.toString().contains("Salon"));

  /// ================= TOTAL (SAFE FIX) =================
  double get totalAmount {
    double total = 0;
    for (var item in widget.cartItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  @override
  void dispose() {
    phone.dispose();
    email.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      appBar: AppBar(
        elevation: 0,
        title: const Text("Confirm Booking"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// SERVICES
          _sectionTitle("Selected Services"),

          _card(
            child: Column(
              children: widget.cartItems.map((item) {
                final isHome =
                    item.id.toString().contains("Home");

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text(
                    "${isHome ? "Home" : "Salon"} • ${item.quantity} item(s)",
                  ),
                  trailing: Text(
                    "₹${item.price * item.quantity}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          /// VISIT TYPE
          _sectionTitle("Appointment Type"),

          _card(
            child: Row(
              children: [
                _chip(Icons.home, "Home", hasHome),
                const SizedBox(width: 10),
                _chip(Icons.store, "Salon", hasSalon),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// DETAILS
          _sectionTitle("Your Details"),

          _card(
            child: Column(
              children: [
                _input(phone, "Phone"),
                _input(email, "Email"),

                if (hasHome)
                  _input(address, "Address"),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),

      /// BOTTOM BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "₹$totalAmount",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE91BA),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Confirm Booking"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ================= SUBMIT =================
  void _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (phone.text.isEmpty || email.text.isEmpty) {
      _show("Fill all details");
      return;
    }

    if (hasHome && address.text.isEmpty) {
      _show("Address required");
      return;
    }

    if (user == null) {
      _show("Login required");
      return;
    }

    setState(() => isLoading = true);

    try {
      await OrderService.placeOrder(
        serviceType: "salon",

        services: widget.cartItems.map((e) =>
            "${e.name} (${e.id.toString().contains("Home") ? "Home" : "Salon"}) x${e.quantity}"
        ).toList(),

        userId: user.uid,
        userName: "Salon User",
        phone: phone.text.trim(),
        email: email.text.trim(),

        createdBy: user.uid,
        createdByRole: "user",

        address: hasHome
            ? address.text.trim()
            : "Salon Visit",

        date: DateTime.now(),
        time: TimeOfDay.now().format(context),

        totalAmount: totalAmount.toDouble(),

        visitType: hasHome && hasSalon
            ? "Mixed"
            : hasHome
                ? "Home"
                : "Salon",

        providerId: null,
        providerUserId: null,
        providerName: null,

        isEnquiry: false,
      );

      /// 🔥 MOST IMPORTANT FIX
      Cart.clear("Salon");

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

  /// ================= UI HELPERS =================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _chip(IconData icon, String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFAE91BA) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black54,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}