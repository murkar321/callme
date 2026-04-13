import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import '../screens/water_detail_page.dart';

class WaterServiceCard extends StatelessWidget {
  final ServiceProduct product;
  final VoidCallback onUpdate;

  const WaterServiceCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = Cart.getQuantity(product.id, "Water");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// =========================
            /// IMAGE + BADGE
            /// =========================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    product.imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// BADGE (if exists)
                if (product.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            /// =========================
            /// TITLE
            /// =========================
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// =========================
            /// RATING + TIME
            /// =========================
            Row(
              children: [
                if (product.rating != null) ...[
                  const Icon(Icons.star,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                ],
                if (product.time != null)
                  Text(
                    product.time!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            /// DESCRIPTION
            Text(
              product.description ?? "Premium water service",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            /// =========================
            /// PRICE + DISCOUNT
            /// =========================
            Row(
              children: [
                Text(
                  "₹${product.calculatedFinalPrice}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                  "₹${product.price}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),

                const SizedBox(width: 10),

                /// DISCOUNT %
                if (product.discount != null)
                  Text(
                    "${product.discount}% OFF",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            /// =========================
            /// BUTTONS (UNCHANGED)
            /// =========================
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 140, 192, 229),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WaterDetailPage(
                              product: product,
                              serviceName: "Water",
                            ),
                          ),
                        );
                      },
                      child: const Text("View"),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: quantity == 0
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFFF3EAF4),
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Cart.addProduct(product, "Water");
                              onUpdate();
                            },
                            child: const Text("ADD"),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Cart.removeById(product.id, "Water");
                                    onUpdate();
                                  },
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Cart.addProduct(product, "Water");
                                    onUpdate();
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}