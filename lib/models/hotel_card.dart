import 'package:callme/models/hotel_booking_page.dart';
import 'package:callme/models/hotel_detail_page.dart';
import 'package:flutter/material.dart';
import '../data/hotel_data.dart';

class HotelCard extends StatelessWidget {
  final HotelRoom hotel;

  const HotelCard({
    super.key,
    required this.hotel,
    required Null Function() onBook,
    required Null Function() onView,
  });

  @override
  Widget build(BuildContext context) {
    final price = hotel.price - (hotel.price * hotel.discount ~/ 100);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        children: [
          /// 🖼 IMAGE (FIXED HEIGHT)
          SizedBox(
            height: 100,
            width: double.infinity,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                hotel.image,
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 📦 CONTENT (NO OVERFLOW ZONE)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🏨 NAME
                  Text(
                    hotel.hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  /// 📍 CITY
                  Text(
                    hotel.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// 💰 PRICE
                  Text(
                    "₹$price",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  /// 🔘 BUTTONS (FORCED VISIBLE)
                  SizedBox(
                    height: 34, // 🔥 GUARANTEED SPACE
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HotelDetailPage(hotel: hotel),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "View",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HotelBookingPage(
                                    hotel: hotel,
                                    products: [],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  const Color.fromARGB(255, 235, 65, 65),
                            ),
                            child: const Text(
                              "Book",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
