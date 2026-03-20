import 'package:flutter/material.dart';
import 'package:callme/data/salon_data.dart';
import 'salon_booking_page.dart';

class SalonDetailPage extends StatelessWidget {
  final SalonService service;

  const SalonDetailPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20), // 🔥 overflow fix
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              Image.asset(
                service.image, // ✅ dynamic image
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// SLOGAN
                    Text(
                      service.slogan,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// TIME
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 18),
                        const SizedBox(width: 6),
                        Text("Duration: ${service.time}"),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          "₹${service.finalPrice}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹${service.price}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${service.discount}% OFF",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// DESCRIPTION
                    const Text(
                      "Service Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(service.description),

                    const SizedBox(height: 20),

                    /// ✅ INCLUDES SECTION
                    const Text(
                      "What's Included",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    ...service.includes.map((item) => _buildPoint(item)),

                    const SizedBox(height: 20),

                    /// ✅ PROCESS SECTION
                    const Text(
                      "Service Process",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    ...service.process.map((step) => _buildStep(step)),

                    const SizedBox(height: 30),

                    /// BOOK BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showBookingTypeDialog(context);
                        },
                        child: const Text("Book Appointment"),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 BULLET POINT (INCLUDES)
  Widget _buildPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// 🔹 STEP POINT (PROCESS)
  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  /// 🔥 POPUP
  void _showBookingTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Booking Type"),
          content: const Text("Select how you want the service"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonBookingPage(
                      service: service,
                      isHomeVisitDefault: false,
                      serviceName: service.name,
                      services: [],
                      adults: 1,
                      children: 1,
                    ),
                  ),
                );
              },
              child: const Text("Salon Appointment"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonBookingPage(
                      service: service,
                      isHomeVisitDefault: true,
                      serviceName: '',
                      services: [],
                      adults: 1,
                      children: 1,
                    ),
                  ),
                );
              },
              child: const Text("Home Service"),
            ),
          ],
        );
      },
    );
  }
}
