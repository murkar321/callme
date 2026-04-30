
import 'package:flutter/material.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/bookings/booking_page.dart';

class LaundryDetailPage extends StatelessWidget {
  final ServiceProduct product;
  final String category;
  final String serviceName;

  const LaundryDetailPage({
    super.key,
    required this.product,
    required this.category,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: const Color(0xFFAE91BA),
        elevation: 0,
        title: const Text(
          "Service Details",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 IMAGE
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(product.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🧾 DETAILS
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// RATING + TIME
                  Row(
                    children: [

                      const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 16,
                      ),

                      const SizedBox(width: 4),

                      Text(product.safeRating.toString()),

                      const SizedBox(width: 15),

                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 16,
                      ),

                      const SizedBox(width: 4),

                      Text(product.serviceTime),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// PRICE
                  Row(
                    children: [

                      Text(
                        "₹${product.calculatedFinalPrice}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFAE91BA),
                        ),
                      ),

                      const SizedBox(width: 10),

                      if (product.discount != null)
                        Text(
                          "₹${product.price}",
                          style: const TextStyle(
                            decoration:
                                TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// CATEGORY
                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const Divider(height: 25),

                  /// DESCRIPTION
                  if (product.description != null)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          product.description!,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),

                  /// INCLUDES
                  if (product.safeIncludes.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "What's Included",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ...product.safeIncludes.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.only(
                                    bottom: 8),
                            child: Row(
                              children: [

                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    item,
                                    style:
                                        const TextStyle(
                                            fontSize:
                                                14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),

                  /// TOOLS
                  if (product.tools != null)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Tools Used",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          product.tools!,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      /// 🛒 BOTTOM ACTION
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
            )
          ],
        ),

        child: Row(
          children: [

            /// PRICE
            Expanded(
              child: Text(
                "₹${product.calculatedFinalPrice}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// ADD TO CART
            Expanded(
              child: ElevatedButton(
                onPressed: () {

                  Cart.addLaundry(
                    id: product.id,
                    name: product.name,
                    price: product.calculatedFinalPrice,
                    category: category,
                    image: product.imagePath,
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text("Added to cart"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize:
                      const Size(0, 50),
                ),
                child: const Text(
                  "ADD",
                  style:
                      TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(width: 10),

            /// BOOK
            Expanded(
              child: ElevatedButton(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: serviceName,
                        product: product, products: [],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFAE91BA),
                  minimumSize:
                      const Size(0, 50),
                ),
                child: const Text(
                  "BOOK",
                  style:
                      TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}