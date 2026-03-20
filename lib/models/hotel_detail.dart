import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';

class HotelDetailPage extends StatelessWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailPage(void add, {super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hotel["name"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼 IMAGE
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 12),

            /// 🏨 NAME
            Text(
              hotel["name"],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            /// ⭐ RATING
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text("${hotel["rating"]}"),
              ],
            ),

            const SizedBox(height: 6),

            /// 📄 DESCRIPTION
            Text(
              hotel["desc"],
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 10),

            /// 💰 PRICE
            Row(
              children: [
                Text(
                  "₹${hotel["price"]}",
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "₹${hotel["discount"]}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// 🛒 ADD TO CART
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Cart.add(
                    CartItem(
                      id: hotel["name"], // unique id
                      name: hotel["name"],
                      price: hotel["discount"],
                      service: "Hotel", // 🔥 IMPORTANT
                      category: hotel["category"],
                    ),
                    service: '',
                  );

                  /// 👉 Go to Cart (only hotel items)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(
                        service: "Hotel",
                        serviceName: '',
                      ),
                    ),
                  );
                },
                child: const Text("Add to Cart"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
