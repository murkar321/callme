import 'package:flutter/material.dart';
import '../data/service_product.dart';

class LaundryCard extends StatelessWidget {
  final ServiceProduct product;
  final String category;
  final VoidCallback onAdd;
  final VoidCallback onView;

  const LaundryCard({
    super.key,
    required this.product,
    required this.category,
    required this.onAdd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// =========================
          /// IMAGE + BADGE
          /// =========================
          Stack(
            children: [
              AspectRatio(
                aspectRatio: screenWidth < 400 ? 4 / 3 : 5 / 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.asset(
                    product.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              /// BADGE (TOP LEFT)
              if (product.badge != null &&
                  product.badge!.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          /// =========================
          /// CONTENT
          /// =========================
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: screenWidth < 400 ? 12 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                /// PRICE + DISCOUNT
                Row(
                  children: [
                    Text(
                      "₹${product.calculatedFinalPrice}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth < 400 ? 13 : 14,
                      ),
                    ),

                    const SizedBox(width: 6),

                    if (product.discount != null &&
                        product.discount! > 0)
                      Text(
                        "${product.discount}% OFF",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                /// RATING + TIME
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 12, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      product.safeRating.toString(),
                      style:
                          const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.serviceTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// =========================
                /// BUTTONS (NO OVERFLOW FIXED)
                /// =========================
                Row(
                  children: [

                    /// ADD BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFAE91BA),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(
                            child: Text(
                              "ADD",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    /// VIEW BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onView,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(
                            child: Text(
                              "VIEW",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}