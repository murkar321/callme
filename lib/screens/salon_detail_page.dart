import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class SalonDetailPage extends StatefulWidget {
  final SalonService service;

  const SalonDetailPage({
    super.key,
    required this.service,
  });

  @override
  State<SalonDetailPage> createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  static const String serviceName = "Salon";

  void refresh() => setState(() {});

  /// ✅ FIXED IDS (IMPORTANT)
  String _id(String type) => "${widget.service.id}_$type";

  int _qty(String type) =>
      Cart.getQuantity(_id(type), serviceName);

  int get totalQty => _qty("Home") + _qty("Salon");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        backgroundColor: const Color(0xFFAE91BA),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                widget.service.image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            /// NAME
            Text(
              widget.service.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.service.slogan,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 15),

            /// PRICE
            Row(
              children: [
                Text(
                  "₹${widget.service.finalPrice}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.service.discount > 0)
                  Text(
                    "₹${widget.service.price}",
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            /// DESCRIPTION
            const Text(
              "Description",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.service.description),

            const SizedBox(height: 20),

            /// INCLUDES
            const Text(
              "Includes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            ...widget.service.includes.map(
              (e) => Row(
                children: [
                  const Icon(Icons.check,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(e)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE91BA),
                ),
                onPressed: () => _showBookingPopup(context),
                child: Text(
                  totalQty == 0
                      ? "Book Service"
                      : "Added ($totalQty) • Add More",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// VIEW CART
            if (totalQty > 0)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartPage(
                          service: serviceName,
                          serviceName: serviceName,
                          cart: Cart.getItems(serviceName),
                        ),
                      ),
                    ).then((_) => refresh());
                  },
                  child: const Text("View Cart"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= POPUP =================
  void _showBookingPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Choose Appointment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// HOME
              ListTile(
                leading: const Icon(Icons.home, color: Colors.purple),
                title: const Text("Home Appointment"),
                onTap: () {
                  Cart.addSalon(
                    id: _id("Home"), // ✅ FIXED
                    name: widget.service.name,
                    price: widget.service.finalPrice,
                    category: widget.service.category,
                    visitType: "Home", // ✅ FIXED
                    image: widget.service.image,
                  );

                  Navigator.pop(context);
                  refresh();
                  _showSnack("Added to Cart (Home)");
                },
              ),

              const Divider(),

              /// SALON
              ListTile(
                leading: const Icon(Icons.store, color: Colors.green),
                title: const Text("Salon Appointment"),
                onTap: () {
                  Cart.addSalon(
                    id: _id("Salon"), // ✅ FIXED
                    name: widget.service.name,
                    price: widget.service.finalPrice,
                    category: widget.service.category,
                    visitType: "Salon", // ✅ FIXED
                    image: widget.service.image,
                  );

                  Navigator.pop(context);
                  refresh();
                  _showSnack("Added to Cart (Salon)");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}