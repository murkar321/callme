import 'package:callme/models/service_product.dart';
import 'package:flutter/material.dart';
import '../screens/service_detail_page.dart';

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
          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Stack(
              children: [
                Image.asset(
                  product.imagePath,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (product.discount != null && product.discount! > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

                if (product.slogan != null)
                  Text(
                    product.slogan!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 8),

                /// RATING
                if (product.rating != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
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
                    const SizedBox(width: 10),
                    if (product.originalPrice > product.calculatedFinalPrice)
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
                    /// VIEW → ServiceDetailPage
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailPage(
                                serviceName: serviceName,
                              ),
                            ),
                          );
                        },
                        child: const Text("View"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// ADD
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Text("ADD"),
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
