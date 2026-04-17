import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../models/cart.dart';
import '../screens/booking_page.dart';

class EducationDetailPage extends StatelessWidget {
  final EducationService service;

  const EducationDetailPage({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      /// 🔝 APP BAR
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: Colors.blue,
      ),

      /// 📜 BODY
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 IMAGE WITH OVERLAY
            Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// 🔻 GRADIENT
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                /// 📌 TITLE ON IMAGE
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            /// 📦 CONTENT
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// ⏱ DURATION
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 18,
                          color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "Duration: ${service.duration}",
                        style: TextStyle(
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// 💰 PRICE CARD
                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                              12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          color: Colors.black12,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "₹${service.finalPrice}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "₹${service.price}",
                          style: const TextStyle(
                            decoration:
                                TextDecoration
                                    .lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                                      horizontal:
                                          8,
                                      vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Colors.red.shade100,
                            borderRadius:
                                BorderRadius
                                    .circular(8),
                          ),
                          child: Text(
                            "${service.discount}% OFF",
                            style:
                                const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📄 DESCRIPTION
                  const Text(
                    "About this course",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    service.description,
                    style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// 🔻 BOTTOM ACTION BUTTONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        child: Row(
          children: [

            /// 🛒 ADD TO CART
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Cart.addItem(
                    id: service.id, // ✅ FIXED
                    name: service.name,
                    price: service.finalPrice,
                    service: "Education", // ✅ FIXED
                    category: service.category,
                    image: service.image,
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                          "${service.name} added to cart"),
                    ),
                  );
                },
                child: const Text("Add to Cart"),
              ),
            ),

            const SizedBox(width: 10),

            /// ⚡ BOOK NOW
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingPage(
                        serviceName:
                            "Education",
                        cart: [
                          CartItem(
                            id: service.id,
                            name:
                                service.name,
                            price: service
                                .finalPrice,
                            service:
                                "Education",
                            category: service
                                .category,
                            image:
                                service.image,
                          )
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton
                    .styleFrom(
                  backgroundColor:
                      Colors.blue,
                  padding:
                      const EdgeInsets
                          .symmetric(
                              vertical: 14),
                ),
                child: const Text(
                  "Book Now",
                  style:
                      TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}