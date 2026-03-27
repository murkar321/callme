import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import '../models/cleaning_service.dart';
import '../models/cart.dart';
import '../screens/cleaning_service_detail_page.dart';

class CleaningServiceCard extends StatelessWidget {
  final CleaningService service;
  final String serviceName;
  final String category;
  final int index;
  final VoidCallback onAdd;

  const CleaningServiceCard({
    super.key,
    required this.service,
    required this.serviceName,
    required this.category,
    required this.index,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// DISCOUNT
                if (service.discount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${service.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// SERVICE NAME
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                /// DESCRIPTION
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                /// TIME
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.time,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// PRICE
                Row(
                  children: [
                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (service.discount > 0)
                      Text(
                        "₹${service.price}",
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                /// BUTTONS
                Row(
                  children: [

                    /// VIEW BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CleaningServiceDetailPage(
                                  product: service,
                                  serviceName: serviceName,
                                ),
                              ),
                            );
                          },
                          child: const Text("View"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// ADD BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {

                            /// add to cart
                            Cart.addCleaning(service);

                            /// callback
                            onAdd();

                            /// navigate to cart
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CartPage(
                                  service: serviceName,
                                  serviceName: serviceName,
                                  cart: Cart.cleaningItems,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFAE91BA),
                          ),
                          child: const Text("Add"),
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
    );
  }
}