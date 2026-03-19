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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              "assets/salon.png",
              width: double.infinity,
              height: 230,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    service.slogan,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text("Duration: ${service.time}"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// PRICE
                  Row(
                    children: [
                      Text(
                        "₹${service.finalPrice}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "₹${service.price}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("${service.discount}% OFF",
                            style: const TextStyle(color: Colors.white)),
                      )
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Service Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(service.description),

                  const SizedBox(height: 30),

                  /// ✅ BOOK BUTTON WITH POPUP
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
    );
  }

  /// 🔥 POPUP FUNCTION
  void _showBookingTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Booking Type"),
          content: const Text("Select how you want the service"),
          actions: [
            /// SALON
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

            /// HOME
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
