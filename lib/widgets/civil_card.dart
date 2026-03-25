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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
            )
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                service.imagePath,
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 10),

            /// 📋 DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// PRICE
                  Text(
                    displayPrice ?? "₹${service.price}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// RATING
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text("${service.rating ?? 0}"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// BUTTONS
                  Row(
                    children: [

                      /// VIEW BUTTON
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          child: const Text(
                            "View",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      /// ADD BUTTON
                      Expanded(
                        child: ElevatedButton(
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}