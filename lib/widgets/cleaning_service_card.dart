import 'package:flutter/material.dart';
import '../screens/cleaning_service_detail_page.dart';
import '../models/cleaning_service.dart';

class CleaningServiceCard extends StatelessWidget {
  final CleaningService product;
  final String serviceName;
  final String category;
  final String id;
  final int qty;
  final Color primaryColor;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CleaningServiceCard({
    super.key,
    required this.product,
    required this.serviceName,
    required this.category,
    required this.id,
    required this.qty,
    required this.primaryColor,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.asset(
                  product.image,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${product.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TEXT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        product.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  /// PRICE + ACTION
                  Column(
                    children: [

                      Row(
                        children: [

                          /// PRICE
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${product.price}",
                                  style: const TextStyle(
                                    decoration:
                                        TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  "₹${product.finalPrice}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// BUTTON / QTY
                          qty == 0
                              ? SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: onAdd,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                    ),
                                    child: const Text(
                                      "ADD",
                                      style:
                                          TextStyle(fontSize: 11),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: primaryColor),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [

                                      GestureDetector(
                                        onTap: onRemove,
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: primaryColor,
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      Text(
                                        qty.toString(),
                                        style: const TextStyle(
                                            fontSize: 12),
                                      ),

                                      const SizedBox(width: 6),

                                      GestureDetector(
                                        onTap: onAdd,
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// VIEW DETAILS
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CleaningServiceDetailPage(
                                  product: product,
                                  serviceName: serviceName,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Details",
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}