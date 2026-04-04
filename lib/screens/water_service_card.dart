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
    final quantity =
        Cart.getQuantity(
      product.id,
      "Water",
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Container(
        padding:
            const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                      14),
              child: Image.asset(
                product.imagePath,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product.name,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              product.description ??
                  "Premium water service",
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  "₹${product.calculatedFinalPrice}",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(
                    width: 8),
                Text(
                  "₹${product.price}",
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    decoration:
                        TextDecoration
                            .lineThrough,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WaterDetailPage(
                              product:
                                  product,
                              serviceName:
                                  "Water",
                            ),
                          ),
                        );
                      },
                      child: const Text(
                          "View"),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: quantity ==
                            0
                        ? ElevatedButton(
                            onPressed:
                                () {
                              Cart.addProduct(
                                product,
                                "Water",
                              );
                              onUpdate();
                            },
                            child:
                                const Text(
                                    "ADD"),
                          )
                        : Container(
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .purple
                                  .shade100,
                              borderRadius:
                                  BorderRadius.circular(
                                      25),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Cart.removeById(
                                      product.id,
                                      "Water",
                                    );
                                    onUpdate();
                                  },
                                  child:
                                      const Icon(
                                    Icons
                                        .remove,
                                  ),
                                ),
                                Text(
                                  quantity
                                      .toString(),
                                ),
                                InkWell(
                                  onTap: () {
                                    Cart.addProduct(
                                      product,
                                      "Water",
                                    );
                                    onUpdate();
                                  },
                                  child:
                                      const Icon(
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