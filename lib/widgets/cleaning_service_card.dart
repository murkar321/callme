import 'package:flutter/material.dart';
import '../screens/cleaning_service_detail_page.dart';
import '../models/cleaning_service.dart';

class CleaningServiceCard extends StatelessWidget {
  final CleaningService product;
  final String serviceName;
  final Color primaryColor;
  final VoidCallback onAdd;

  const CleaningServiceCard({
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          )
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
                  product.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// DISCOUNT
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                /// DESCRIPTION
                Text(
                  product.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 8),

                /// RATING + TIME
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "5.0",
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      color: Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.time,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// PRICE
                Row(
                  children: [
                    Text(
                      "₹${product.finalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${product.price}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// BUTTONS
                Row(
                  children: [
                    /// VIEW
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CleaningServiceDetailPage(
                                product: product,
                                serviceName: serviceName,
                              ),
                            ),
                          );
                        },
                        child: const Text("View"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// ADD BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "ADD",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
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
