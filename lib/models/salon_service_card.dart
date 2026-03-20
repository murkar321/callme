import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/service_product.dart';
import '../data/salon_data.dart';
import '../screens/salon_detail_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;

  const SalonServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final product = ServiceProduct(
      id: service.name, // ✅ UNIQUE
      service: "Salon", // ✅ IMPORTANT
      name: service.name,
      price: service.price,
      imagePath: "assets/salon.png",
      description: service.description,
      time: service.time,
      discount: service.discount,
      finalPrice: service.finalPrice,
      rating: 4.5,
    );
    final qty = Cart.allItems
        .where((e) => e.id == product.id && e.service == product.service)
        .fold(0, (sum, e) => sum + e.quantity);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              "assets/salon.png",
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 10),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                Text(service.slogan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),

                const SizedBox(height: 6),

                Text("₹${service.finalPrice}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                /// VIEW
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonDetailPage(service: service),
                      ),
                    );
                  },
                  child: const Text("View Details",
                      style: TextStyle(color: Colors.blue, fontSize: 12)),
                ),
              ],
            ),
          ),

          /// ADD / QTY BUTTON
          qty == 0
              ? ElevatedButton(
                  onPressed: () {
                    Cart.add(product as CartItem, service: '');
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text("ADD"),
                )
              : Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Cart.remove(product as CartItem);
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text(qty.toString()),
                    IconButton(
                      onPressed: () {
                        Cart.add(product as CartItem, service: '');
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
