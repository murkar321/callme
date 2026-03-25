import 'package:flutter/material.dart';
import '../models/service_product.dart';

class CivilServiceCard extends StatelessWidget {
  final ServiceProduct service;
  final String? displayPrice;
  final VoidCallback onAddCart;
  final VoidCallback? onTap;

  const CivilServiceCard({
    super.key,
    required this.service,
    required this.onAddCart,
    this.onTap,
    this.displayPrice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // whole card clickable
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼️ IMAGE (FIXED)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
                child: Image.asset(
                  service.imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// 📋 DETAILS
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANT
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// PRICE
                  Text(
                    displayPrice ?? "₹${service.price}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// RATING
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text("${service.rating ?? 0}"),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// BUTTONS
                  Row(
                    children: [

                      /// VIEW
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: onTap,
                          child: const Text(
                            "View",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      /// ADD / CUSTOM
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: onAddCart,
                          child: Text(
                            service.category == "Renovation"
                                ? "Custom"
                                : "Add",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}