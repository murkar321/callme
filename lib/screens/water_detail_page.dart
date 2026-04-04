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
            Image.asset(
              product.imagePath,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    product.description ??
                        "Premium service available",
                    style: const TextStyle(fontSize: 15),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Price: ₹${product.calculatedFinalPrice}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 196, 153, 204),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Service Includes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text("• Fast delivery"),
                  const Text("• Premium quality"),
                  const Text("• Same day service"),
                  const Text("• Reliable support"),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 223, 170, 233),
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () {
                        Cart.addProduct(product, "Water");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(
                              products:
                                  Cart.getItems("Water"),
                              serviceName: "Water",
                              service: null,
                              cart: [],
                            ),
                          ),
                        );
                      },
                      child: const Text("Book Now"),
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