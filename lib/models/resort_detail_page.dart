import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../widgets/rbooking_popup.dart';

class ResortDetailPage extends StatelessWidget {
  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Resort Details"),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            Stack(
              children: [
                Image.asset(
                  resort.image,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${resort.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    resort.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// CITY + RATING
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red),
                      const SizedBox(width: 5),
                      Text(resort.city),

                      const Spacer(),

                      Row(
                        children: List.generate(
                          resort.rating,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// PRICE
                  Row(
                    children: [
                      Text(
                        "₹${resort.price}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "₹${resort.originalPrice}",
                        style: const TextStyle(
                          decoration:
                              TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${resort.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// FACILITIES
                  const Text(
                    "Facilities",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: resort.facilities.map((f) {
                      return Chip(
                        label: Text(f),
                        backgroundColor:
                            Colors.blue.shade50,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    resort.description,
                    style: const TextStyle(fontSize: 15),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      /// BOOK BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {

            showDialog(
              context: context,
              builder: (_) =>
                  ResortBookingPopup(resort: resort),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding:
                const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Book Now",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}