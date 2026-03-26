import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../models/cart.dart';
import 'package:callme/widgets/rbooking_popup.dart';

class ResortDetailPage extends StatelessWidget {
  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort, Object? service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: Stack(
        children: [

          /// SCROLLABLE CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// IMAGE BANNER
                Stack(
                  children: [
                    Image.asset(
                      resort.image,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),

                    Positioned(
                      top: 40,
                      left: 12,
                      child: CircleAvatar(
                        backgroundColor:
                            Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              Navigator.pop(context),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${resort.discount}% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// CONTENT
                Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      /// NAME
                      Text(
                        resort.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// CITY
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(resort.city),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// RATING
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${resort.rating} Rating",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// PRICE CARD
                      _card(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [

                            const Text(
                              "Price per person",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),

                            Row(
                              children: [
                                Text(
                                  "₹${resort.price}",
                                  style:
                                      const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.green,
                                  ),
                                ),

                                const SizedBox(
                                    width: 8),

                                Text(
                                  "₹${resort.originalPrice}",
                                  style:
                                      const TextStyle(
                                    decoration:
                                        TextDecoration
                                            .lineThrough,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// DESCRIPTION
                      const Text(
                        "About Resort",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        resort.description,
                        style:
                            const TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// FACILITIES
                      const Text(
                        "Facilities",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: resort.facilities
                            .map(
                              (f) => Chip(
                                label: Text(f),
                                backgroundColor:
                                    Colors.white,
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      /// ADD TO CART
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {

                            Cart.addItem(
                              name: resort.name,
                              price: resort.price,
                              category: "Resort",
                              service: "Resort",
                              image: resort.image, id: '',
                            );

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Added to cart"),
                              ),
                            );
                          },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.orange,
                            padding:
                                const EdgeInsets
                                    .all(14),
                          ),
                          child: const Text(
                              "Add to Cart"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// BOTTOM BOOK BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        ResortBookingPopup(
                      resort: resort, id: '', name: '', price: 0, image: '',
                    ),
                  );
                },
                style: ElevatedButton
                    .styleFrom(
                  backgroundColor:
                      Colors.green,
                  padding:
                      const EdgeInsets.all(14),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CARD
  Widget _card({required Widget child}) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}