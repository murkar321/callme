import 'package:callme/models/cart.dart';
import 'package:flutter/material.dart';
import 'hotel_detail.dart';

class HotelCard extends StatelessWidget {
  final String name;
  final String city;
  final double rating;
  final int price;
  final int discountPrice;
  final String description;
  final String image;
  final String category;

  const HotelCard({
    super.key,
    required this.name,
    required this.city,
    required this.rating,
    required this.price,
    required this.discountPrice,
    required this.description,
    required this.category,
    this.image = "",
  });

  @override
  Widget build(BuildContext context) {
    /// 🔥 HOTEL MAP (PASS TO DETAIL PAGE)
    final Map<String, dynamic> hotel = {
      "name": name,
      "city": city,
      "rating": rating,
      "price": price,
      "discount": discountPrice,
      "desc": description,
      "category": category,
      "image": image,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🖼 IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15),
            ),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 110,
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.hotel)),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🏨 NAME
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                /// ⭐ RATING + CITY
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.location_on, size: 14),
                    Expanded(
                      child: Text(
                        city,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                /// 📝 DESCRIPTION
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                /// 💸 PRICE
                Row(
                  children: [
                    Text(
                      "₹$price",
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "₹$discountPrice",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// 🔘 BUTTONS
                Row(
                  children: [
                    /// ✅ BOOK BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Cart.add(
                            CartItem(
                              id: name,
                              name: name,
                              price: discountPrice,
                              service: "Hotel",
                              category: category,
                            ),
                            service: 'Hotel',
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("$name added to cart"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          "Book",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    /// ✅ DETAILS BUTTON
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HotelDetailPage(
                                hotel,
                                hotel: {},
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        child: const Text(
                          "Details",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
