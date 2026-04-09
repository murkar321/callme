import 'package:flutter/material.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/screens/booking_page.dart';

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
    final screenHeight =
        MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Container(
        height: screenHeight * 0.85,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            /// 🔝 HEADER
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "Service Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),

            const SizedBox(height: 5),

            /// 🖼 IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                product.imagePath,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            /// 🧺 NAME
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// ⭐ RATING + TIME
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [

                const Icon(Icons.star,
                    color: Colors.orange, size: 16),

                const SizedBox(width: 4),

                Text(product.safeRating.toString()),

                const SizedBox(width: 12),

                const Icon(Icons.access_time,
                    size: 16, color: Colors.grey),

                const SizedBox(width: 4),

                Text(product.serviceTime),
              ],
            ),

            const SizedBox(height: 6),

            /// 💬 SLOGAN
            if (product.slogan != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  product.slogan!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

            const Divider(height: 20),

            /// 📄 SCROLL CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// DESCRIPTION
                    if (product.description != null)
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Text(
                            "Description",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            product.description!,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          ...product.safeIncludes.map(
                            (item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [

                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            product.tools!,
                            style: const TextStyle(
                                fontSize: 13),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            /// 💰 PRICE + BUTTONS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  /// PRICE
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "₹${product.calculatedFinalPrice}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

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

                      Text(
                        category,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// 🛒 ADD TO CART
                  ElevatedButton(
                    onPressed: () {

                      Cart.addLaundry(
                        id: product.id,
                        name: product.name,
                        price:
                            product.calculatedFinalPrice,
                        category: category,
                        image: product.imagePath,
                      );

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize:
                          const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// ✅ CONFIRM BOOKING
                  ElevatedButton(
                    onPressed: () {

                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingPage(
                            serviceName: serviceName,
                            product: product,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFAE91BA),
                      minimumSize:
                          const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Confirm Booking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}