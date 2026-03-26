import 'package:callme/models/resort_detail_page.dart';
import 'package:callme/widgets/rbooking_popup.dart';
import 'package:flutter/material.dart';
import '../data/resorts_data.dart';

class ResortCard extends StatelessWidget {
  final Resort resort;

  const ResortCard({super.key, required this.resort});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE + DISCOUNT
          Stack(
            children: [
              Image.asset(
                resort.image,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${resort.discount}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  resort.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                /// CITY + RATING
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(resort.city)),
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${resort.rating}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// PRICE ROW
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "₹${resort.price}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "₹${resort.originalPrice}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    /// BUTTONS
                    Row(
                      children: [

                        /// VIEW DETAILS
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ResortDetailPage(resort: resort),
                              ),
                            );
                          },
                          child: const Text("View Details"),
                        ),

                        /// BOOK
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  ResortBookingPopup(resort: resort, id: '', name: '', price: 0, image: '',),
                            );
                          },
                          child: const Text("Book"),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}