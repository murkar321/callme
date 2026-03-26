
import 'package:callme/widgets/rbooking_popup.dart';
import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../models/cart.dart';

class ResortDetailPage extends StatefulWidget {
  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort,
  });

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {

  @override
  Widget build(BuildContext context) {

    final resort = widget.resort;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text(resort.name),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            Image.asset(
              resort.image,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(12),
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

                  const SizedBox(height: 6),

                  /// CITY
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      Text(resort.city),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// RATING
                  Row(
                    children: List.generate(
                      resort.rating,
                      (index) => const Icon(
                        Icons.star,
                        color: Colors.orange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// PRICE
                  Row(
                    children: [

                      Text(
                        "₹${resort.price}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "₹${resort.originalPrice}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "${resort.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.green,
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
                    spacing: 8,
                    children: resort.facilities.map((f) {
                      return Chip(
                        label: Text(f),
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

                  const SizedBox(height: 30),

                  /// BUTTONS
                  Row(
                    children: [

                      /// ADD TO CART
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {

                            Cart.addItem(
                              name: resort.name,
                              price: resort.price,
                              category: "Resort", id: '', service: '',
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Added to cart"),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Add to Cart"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// BOOK
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {

                            showDialog(
                              context: context,
                              builder: (_) =>
                                  ResortBookingPopup(resort: resort, id: '', name: '', price: 0, image: '',),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Book"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


