import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart.dart';
import '../provider/order_service.dart';
import '../screens/bottom_nav_page.dart';
import '../payment/payment_page.dart';

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
      widget.cartItems.any(
            (e) => e.id.toString().contains("Home"),
      );

  bool get hasSalon =>
      widget.cartItems.any(
            (e) => e.id.toString().contains("Salon"),
      );

  /// ================= TOTAL =================
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
        centerTitle: true,
        title: const Text(
          "Confirm Booking",
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          /// ================= SERVICES =================
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
                    "${isHome ? "Home Visit" : "Salon Visit"} • Qty ${item.quantity}",
                  ),

                  trailing: Text(
                    "₹${item.price * item.quantity}",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );

              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          /// ================= APPOINTMENT TYPE =================
          _sectionTitle("Appointment Type"),

          _card(
            child: Row(

              children: [

                _chip(
                  Icons.home,
                  "Home",
                  hasHome,
                ),

                const SizedBox(width: 10),

                _chip(
                  Icons.store,
                  "Salon",
                  hasSalon,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ================= USER DETAILS =================
          _sectionTitle("Your Details"),

          _card(
            child: Column(
              children: [

                _input(
                  phone,
                  "Phone Number",
                ),

                _input(
                  email,
                  "Email Address",
                ),

                if (hasHome)
                  _input(
                    address,
                    "Home Address",
                  ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),

      /// ================= BOTTOM BAR =================
      bottomNavigationBar: Container(

        padding: const EdgeInsets.all(16),

        decoration: const BoxDecoration(
          color: Colors.white,

          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),

        child: Row(
          children: [

            Expanded(
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  Text(
                    "₹${totalAmount.toStringAsFixed(0)}",

                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ElevatedButton(

                onPressed: isLoading
                    ? null
                    : _continueToPayment,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE91BA),

                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: isLoading
                    ? const SizedBox(
                  height: 22,
                  width: 22,

                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Proceed To Pay",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= PAYMENT FLOW =================
  Future<void> _continueToPayment() async {

    final user = FirebaseAuth.instance.currentUser;

    if (phone.text.isEmpty || email.text.isEmpty) {
      _show("Please fill all details");
      return;
    }

    if (hasHome && address.text.isEmpty) {
      _show("Address required");
      return;
    }

    if (user == null) {
      _show("Please login first");
      return;
    }

    final result = await Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) => PaymentPage(

          serviceName: "Salon Booking",

          amount: totalAmount.toInt(),
        ),
      ),
    );

    /// ================= PAYMENT SUCCESS =================
    if (result == true || result == 'offline') {

      setState(() {
        isLoading = true;
      });

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

          totalAmount: totalAmount,

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

        /// CLEAR CART
        Cart.clear("Salon");

        _show(
          result == 'offline'
              ? "Booking Placed Successfully ✅"
              : "Payment Successful ✅",
        );

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

      setState(() {
        isLoading = false;
      });
    }
  }

  /// ================= UI HELPERS =================
  Widget _sectionTitle(String title) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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

  Widget _chip(
      IconData icon,
      String label,
      bool active,
      ) {

    return Expanded(
      child: Container(

        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),

        decoration: BoxDecoration(

          color: active
              ? const Color(0xFFAE91BA)
              : Colors.grey.shade200,

          borderRadius: BorderRadius.circular(20),
        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,

              size: 16,

              color: active
                  ? Colors.white
                  : Colors.black54,
            ),

            const SizedBox(width: 6),

            Text(
              label,

              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
      TextEditingController controller,
      String hint,
      ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 10),

      child: TextField(

        controller: controller,

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }
}