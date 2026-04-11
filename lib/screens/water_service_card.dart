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
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: Image.asset(
                product.imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 14),

            /// TITLE
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            /// DESCRIPTION
            Text(
              product.description ??
                  "Premium water service",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            /// PRICE
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
                    decoration:
                        TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// BUTTONS
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style:
                          OutlinedButton.styleFrom(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  30),
                        ),
                        side: BorderSide(
                          color:
                              const Color.fromARGB(255, 140, 192, 229),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WaterDetailPage(
                              product: product,
                              serviceName:
                                  "Water",
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "View",
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              const Color.fromARGB(255, 124, 179, 206),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: quantity == 0
                        ? ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                  const Color(
                                      0xFFF3EAF4),
                              foregroundColor:
                                  const Color.fromARGB(255, 106, 210, 242),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        30),
                              ),
                            ),
                            onPressed: () {
                              Cart.addProduct(
                                product,
                                "Water",
                              );
                              onUpdate();
                            },
                            child: const Text(
                              "ADD",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          )
                        : Container(
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .purple
                                  .shade100,
                              borderRadius:
                                  BorderRadius.circular(
                                      30),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Cart.removeById(
                                      product.id,
                                      "Water",
                                    );
                                    onUpdate();
                                  },
                                  icon: const Icon(
                                    Icons.remove,
                                  ),
                                ),
                                Text(
                                  quantity
                                      .toString(),
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Cart.addProduct(
                                      product,
                                      "Water",
                                    );
                                    onUpdate();
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                  ),
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