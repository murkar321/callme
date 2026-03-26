import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import 'booking_page.dart';

class WaterDetailPage extends StatefulWidget {
  final ServiceProduct product;

  const WaterDetailPage({super.key, required this.product});

  @override
  State<WaterDetailPage> createState() => _WaterDetailPageState();
}

class _WaterDetailPageState extends State<WaterDetailPage> {
  int qty = 0;

  CartItem get cartItem => CartItem(
        id: widget.product.id,
        name: widget.product.name,
        price: widget.product.calculatedFinalPrice,
        service: "Water",
        category: "Water",
        image: widget.product.imagePath,
      );

  @override
  void initState() {
    super.initState();
    qty = Cart.getQuantity(widget.product.id, "Water");
  }

  void updateQty() {
    setState(() {
      qty = Cart.getQuantity(widget.product.id, "Water");
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.purple.shade200,
      ),
      body: Column(
        children: [
          /// 🔷 IMAGE
          Image.asset(
            product.imagePath,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          /// 🔷 CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  /// PRICE
                  Text(
                    "₹${product.calculatedFinalPrice}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 215, 180, 221)),
                  ),

                  const SizedBox(height: 10),

                  /// DESCRIPTION
                  Text(
                    product.description ?? "No description available",
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 ADD / REMOVE
                  qty == 0
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Cart.add(cartItem, service: "Water");
                              updateQty();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                            child: const Text("Add to Cart"),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                Cart.remove(cartItem);
                                updateQty();
                              },
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                            ),
                            Text(qty.toString(),
                                style: const TextStyle(fontSize: 18)),
                            IconButton(
                              onPressed: () {
                                Cart.add(cartItem, service: "Water");
                                updateQty();
                              },
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          /// ✅ CONFIRM BOOKING BUTTON
          Container(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (Cart.getItems("Water").isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please add item first"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        products: Cart.getItems("Water"),
                        serviceName: "Water",
                        service: null,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: const Text(
                  "Confirm Booking",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
