import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'package:callme/bookings/hotel_booking_page.dart';

class HotelDetailPage extends StatelessWidget {
  final HotelRoom hotel;

  const HotelDetailPage({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    int finalPrice = hotel.price - ((hotel.price * hotel.discount) ~/ 100);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔝 APPBAR
      appBar: AppBar(
        title: Text(hotel.hotelName),
        backgroundColor: Colors.purple.shade200,
      ),

      /// 📱 BODY
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼️ IMAGE WITH OVERLAY
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20)),
                      child: Image.asset(
                        hotel.image,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// 🔥 DISCOUNT BADGE
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${hotel.discount}% OFF",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                /// 🏨 HOTEL INFO CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel.hotelName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(child: Text(hotel.address)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// 💰 PRICE SECTION
                          Row(
                            children: [
                              Text(
                                "₹${hotel.price}",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "₹$finalPrice",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Text("/ night"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// ⭐ FEATURES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text("Features",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.features
                        .map((f) => Chip(
                              label: Text(f),
                              backgroundColor: Colors.purple.shade50,
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 15),

                /// 🏢 FACILITIES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text("Facilities",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.facilities
                        .map((f) => Chip(
                              label: Text(f),
                              backgroundColor: Colors.green.shade50,
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 20),

                /// 📄 DESCRIPTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text("Description",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    hotel.description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 STICKY BOOK BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
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
                  backgroundColor: const Color.fromARGB(255, 201, 178, 206),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
