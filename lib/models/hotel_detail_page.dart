import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'hotel_booking_page.dart';

class HotelDetailPage extends StatelessWidget {
  final HotelRoom hotel;

  const HotelDetailPage({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hotel.hotelName)),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(hotel.image),

            const SizedBox(height: 10),

            Text(hotel.hotelName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            Text(hotel.address),

            const SizedBox(height: 10),

            Text("₹${hotel.price} / Night"),

            const SizedBox(height: 10),

            const Text("Features"),
            ...hotel.features.map((e) => Text("• $e")),

            const SizedBox(height: 10),

            ElevatedButton(
              child: const Text("Book Now"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HotelBookingPage(hotel: hotel),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}