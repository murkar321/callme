import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';

class WaterServiceCard extends StatelessWidget {
  final ServiceProduct product;
  final VoidCallback onUpdate;

  const WaterServiceCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  CartItem get cartItem => CartItem(
        id: product.id,
        name: product.name,
        price: product.calculatedFinalPrice,
        service: "Water",
        category: "Water",
        image: product.imagePath,
      );

  @override
  Widget build(BuildContext context) {
    final quantity = Cart.getQuantity(product.id, "Water");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.shade300,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 FIX OVERFLOW
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 IMAGE + DISCOUNT
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  product.imagePath,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              /// 🔥 DISCOUNT BADGE
              if (product.discount != null && product.discount! > 0)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${product.discount}% OFF",
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
            ],
          ),

          /// 🔹 CONTENT
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// 🔹 TEXT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (product.description != null)
                        Text(
                          product.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),

                  /// 🔹 PRICE + BUTTON
                  Row(
                    children: [
                      /// 🔹 PRICE SECTION
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${product.calculatedFinalPrice}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                                fontSize: 13,
                              ),
                            ),

                            /// ORIGINAL PRICE
                            if (product.originalPrice >
                                product.calculatedFinalPrice)
                              Text(
                                "₹${product.originalPrice}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// 🔹 ADD / QTY
                      quantity == 0
                          ? SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  Cart.add(cartItem, service: "Water");
                                  onUpdate();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                ),
                                child: const Text(
                                  "ADD",
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            )
                          : Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Cart.removeById(product.id, "Water");
                                      onUpdate();
                                    },
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(quantity.toString(),
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Cart.add(cartItem, service: "Water");
                                      onUpdate();
                                    },
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ],
                              ),
                            ),
                    ],
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
