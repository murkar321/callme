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

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.asset(
                  product.imagePath,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              if ((product.discount ?? 0) > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${product.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    product.description ??
                        "Premium service",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        "₹${product.calculatedFinalPrice}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "₹${product.price}",
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration:
                              TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      /// VIEW BUTTON
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: OutlinedButton(
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
                            child:
                                const Text("View"),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// ADD / COUNTER
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: quantity == 0
                              ? ElevatedButton(
                                  style:
                                      ElevatedButton
                                          .styleFrom(
                                    backgroundColor:
                                        Colors
                                            .purple
                                            .shade200,
                                  ),
                                  onPressed: () {
                                    Cart.addProduct(
                                        product,
                                        "Water");
                                    onUpdate();
                                  },
                                  child: const Text(
                                      "ADD"),
                                )
                              : Container(
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .purple
                                        .shade100,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                30),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Cart.removeById(
                                            product.id,
                                            "Water",
                                          );
                                          onUpdate();
                                        },
                                        child: const Icon(
                                            Icons
                                                .remove),
                                      ),
                                      Text(
                                        quantity
                                            .toString(),
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Cart.addProduct(
                                            product,
                                            "Water",
                                          );
                                          onUpdate();
                                        },
                                        child: const Icon(
                                            Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}