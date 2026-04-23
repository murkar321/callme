import 'package:flutter/material.dart';
import '../models/service_product.dart';
import 'booking_page.dart';

class ServiceViewDetailPage extends StatelessWidget {
  final ServiceProduct product;
  final String serviceName;

  const ServiceViewDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFAE91BA);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(product.name),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Image.asset(
              product.imagePath,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 6),
                  Text(product.description ?? ""),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange),
                      Text(" ${product.rating}"),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time),
                      Text(" ${product.time}"),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "₹${product.calculatedFinalPrice}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  /// INCLUDES
                  const Text("What's Included",
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  ...product.includes!.map((e) => Text("• $e")),

                  const SizedBox(height: 16),

                  /// PROCESS
                  if (product.process != null) ...[
                    const Text("Service Process",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...product.process!.map((e) => Text("• $e")),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      /// BOOK BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.all(14),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingPage(
                  serviceName: serviceName,
                  products: [],
                  cart: [],
                ),
              ),
            );
          },
          child: const Text("Book Now"),
        ),
      ),
    );
  }
}