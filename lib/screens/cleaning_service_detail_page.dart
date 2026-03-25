import 'package:flutter/material.dart';
import '../models/cleaning_service.dart';
import 'booking_page.dart';

class CleaningServiceDetailPage extends StatelessWidget {
  final CleaningService product;
  final String serviceName;

  const CleaningServiceDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          Image.asset(
            product.image,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),

          /// DETAILS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(product.description),

                const SizedBox(height: 10),

                Text(
                  "Time: ${product.time}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 10),

                Text(
                  "Price: ₹${product.finalPrice}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          /// BOOK BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: serviceName,
                        products: product,
                      ),
                    ),
                  );
                },
                child: const Text("Book Now"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}