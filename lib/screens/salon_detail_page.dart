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

            /// SERVICE IMAGE
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

                  /// SERVICE NAME
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// SLOGAN
                  Text(
                    service.slogan,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// TIME
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Duration: ${service.time}",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// PRICE SECTION
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
                          fontSize: 16,
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

                        child: Text(
                          "${service.discount}% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// DESCRIPTION
                  const Text(
                    "Service Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    service.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 25),

                  /// WHAT'S INCLUDED
                  const Text(
                    "What's Included",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: service.includes.map((item) {

                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(item),
                        dense: true,
                      );

                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// SERVICE PROCESS
                  const Text(
                    "Service Process",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children: service.process.asMap().entries.map((entry) {

                      int index = entry.key + 1;
                      String step = entry.value;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.purple,
                          child: Text(
                            "$index",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        title: Text(step),
                        dense: true,
                      );

                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  /// BOOK BUTTON
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        backgroundColor:
                            const Color.fromARGB(255, 143, 134, 157),
                      ),

                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SalonBookingPage(
                              serviceName: service.name,
                            ),
                          ),
                        );

                      },

                      child: const Text(
                        "Book Appointment",
                        style: TextStyle(fontSize: 16),
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