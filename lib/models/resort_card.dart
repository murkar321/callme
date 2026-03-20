import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_product.dart';
import '../models/cart_provider.dart';

class ResortCard extends StatelessWidget {
  final ServiceProduct resort;
  final VoidCallback onTap;

  const ResortCard({
    super.key,
    required this.resort,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isAdded = cart.isAdded(resort);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 IMAGE (CLICK = VIEW)
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.asset(
                    resort.imagePath,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  /// ⭐ RATING
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              size: 12, color: Colors.orange),
                          Text(
                            " ${resort.safeRating}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔹 DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  Text(
                    resort.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),

                  const SizedBox(height: 4),

                  /// PRICE
                  Row(
                    children: [
                      Text(
                        "₹${resort.finalPrice ?? resort.price}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (resort.discount != null)
                        Text(
                          "₹${resort.price}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  /// 🔥 BUTTON ROW (ADD + VIEW)
                  Row(
                    children: [
                      /// ADD BUTTON
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAdded
                                  ? Colors.green
                                  : const Color(0xffAE91BA),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              cart.toggle(resort);
                            },
                            child: FittedBox(
                              child: Text(
                                isAdded ? "Added ✓" : "Add",
                                style: const TextStyle(fontSize: 11),
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
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: Colors.black12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: onTap,
                            child: const Text(
                              "View",
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
