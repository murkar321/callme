import 'package:flutter/material.dart';
import '../screens/booking_page.dart';
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

          /// IMAGE + DISCOUNT
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  product.image,
                  height: 95,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
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

          /// DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// DESCRIPTION
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

                  /// TIME
                  Text(
                    product.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),

                  const Spacer(),

                  /// PRICE
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "₹${product.price}",
                            style: const TextStyle(
                              decoration:
                                  TextDecoration
                                      .lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),

                          Text(
                            "₹${product.finalPrice}",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      /// ADD / REMOVE
                      qty == 0
                          ? ElevatedButton(
                              onPressed: onAdd,
                              style: ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                    primaryColor,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child:
                                  const Text("ADD"),
                            )
                          : Row(
                              children: [

                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    size: 18,
                                  ),
                                  onPressed: onRemove,
                                ),

                                Text(qty.toString()),

                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    size: 18,
                                  ),
                                  onPressed: onAdd,
                                ),
                              ],
                            )
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// VIEW DETAILS
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(
                              serviceName:
                                  serviceName,
                              products: product,
                            ),
                          ),
                        );
                      },
                      child:
                          const Text("View Details"),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}