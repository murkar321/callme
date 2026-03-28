import 'package:callme/screens/ServiceViewDetailPage.dart';
import 'package:flutter/material.dart';
import '../models/service_product.dart';


class PlumbingServiceCard extends StatelessWidget {
  final ServiceProduct product;
  final String serviceName;
  final Color primaryColor;
  final VoidCallback onAdd;

  const PlumbingServiceCard({
    super.key,
    required this.product,
    required this.serviceName,
    required this.primaryColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE + DISCOUNT
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.asset(
                  product.imagePath,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              if ((product.discount ?? 0) > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${product.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// NAME
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                /// SLOGAN
                if (product.slogan != null)
                  Text(
                    product.slogan!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 8),

                /// ⭐ RATING + ⏱ TIME
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
                    if (product.time != null) ...[
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        product.time!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                /// PRICE
                Row(
                  children: [
                    Text(
                      "₹${product.calculatedFinalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (product.originalPrice >
                        product.calculatedFinalPrice)
                      Text(
                        "₹${product.originalPrice}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                /// BUTTONS
                Row(
                  children: [
                    /// VIEW DETAILS
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceViewDetailPage(
                                product: product,
                                serviceName: serviceName,
                              ),
                            ),
                          );
                        },
                        child: const Text("View"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// ADD BUTTON
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onAdd,
                        child: const Text("Add"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}