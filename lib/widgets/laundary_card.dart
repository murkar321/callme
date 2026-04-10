import 'package:flutter/material.dart';
import '../models/service_product.dart';

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
    required this.onView, required Null Function() onTap,
  });

  @override
  Widget build(BuildContext context) {

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
            child: Image.asset(
              product.imagePath,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    "₹${product.calculatedFinalPrice}",
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  Row(
                    children: [

                      Expanded(
                        child:
                            ElevatedButton(
                          onPressed: onAdd,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            padding:
                                EdgeInsets.zero,
                            backgroundColor:
                                const Color(
                                    0xFFAE91BA),
                          ),
                          child:
                              const Text(
                            "ADD",
                            style: TextStyle(
                                fontSize:
                                    12,
                                color: Colors
                                    .white),
                          ),
                        ),
                      ),

                      const SizedBox(
                          width: 5),

                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: onView,
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                EdgeInsets.zero,
                          ),
                          child:
                              const Text(
                            "VIEW",
                            style: TextStyle(
                                fontSize:
                                    12),
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