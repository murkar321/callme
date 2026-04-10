import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import 'booking_page.dart';

class WaterDetailPage extends StatelessWidget {
  final ServiceProduct product;
  final String serviceName;

  const WaterDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.purple.shade300,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// IMAGE
            Image.asset(
              product.imagePath,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            /// DETAILS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// DESCRIPTION
                  Text(
                    product.description ??
                        "Premium service available",
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// PRICE
                  Text(
                    "Price: ₹${product.calculatedFinalPrice}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(
                          255, 196, 153, 204),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// INCLUDES
                  const Text(
                    "Service Includes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text("• Fast delivery"),
                  const Text("• Premium quality"),
                  const Text("• Same day service"),
                  const Text("• Reliable support"),

                  const SizedBox(height: 30),

                  /// BOOK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(
                                255,
                                223,
                                170,
                                233),
                        padding:
                            const EdgeInsets.all(
                                16),
                      ),

                      onPressed: () {

                        /// ADD TO CART
                        Cart.addProduct(
                          product,
                          "Water",
                        );

                        /// GO TO BOOKING PAGE
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(
                              products: Cart.getItems(
                                  "Water"),
                              serviceName: "Water",
                            ),
                          ),
                        );
                      },

                      child: const Text(
                        "Book Now",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}