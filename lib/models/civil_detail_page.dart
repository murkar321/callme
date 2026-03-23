import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import 'package:callme/screens/civil_book_page.dart';

class CivilDetailPage extends StatefulWidget {
  final ServiceProduct service;

  const CivilDetailPage({super.key, required this.service});

  @override
  State<CivilDetailPage> createState() => _CivilDetailPageState();
}

class _CivilDetailPageState extends State<CivilDetailPage> {
  /// Refresh UI
  void refresh() => setState(() {});

  /// Add Service to Cart
  void addToCart() {
    final imagePath = widget.service.imagePath.isNotEmpty ? widget.service.imagePath : 'assets/civil.png';

    Cart.add(
      CartItem(
        id: "civil_${widget.service.id}",
        name: widget.service.name,
        price: widget.service.price,
        service: "Civil Contract Services",
        category: widget.service.category ?? "Unknown",
        image: imagePath,
      ),
      service: "Civil Contract Services",
    );

    refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.service.name} added to booking"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Navigate to Booking Page
  void navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CivilBookPage()),
    ).then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = Cart.getTotalItems("Civil Contract Services");
    final int totalPrice = Cart.getTotal("Civil Contract Services");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.service.name),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: Image.asset(
                    widget.service.imagePath.isNotEmpty ? widget.service.imagePath : 'assets/civil.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 15),

                // Service Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    widget.service.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),

                // Slogan
                if (widget.service.slogan != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      widget.service.slogan!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                const SizedBox(height: 12),

                // Price
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: Colors.green),
                      Text(
                        "${widget.service.price}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(width: 6),
                      const Text("Inspection Booking Price", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text("Service Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    widget.service.description ?? "No description available",
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
                const SizedBox(height: 30),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: addToCart,
                          child: const Text("Add to Booking", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            addToCart();
                            navigateToBooking();
                          },
                          child: const Text("Book Inspection", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Mini Cart
          if (totalItems > 0)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Text("$totalItems items", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const Spacer(),
                    Text("₹$totalPrice", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: navigateToBooking,
                      child: const Text("View Cart"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}