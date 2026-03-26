import 'package:flutter/material.dart';
import '../data/hotel_data.dart';

class HotelBookingPage extends StatelessWidget {
  final HotelRoom hotel;

  const HotelBookingPage({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(hotel.hotelName,
                style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 10),

            Text("Price: ₹${hotel.price}"),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Booking Confirmed")),
                );
              },
              child: const Text("Confirm Booking"),
            )
          ],
        ),
      ),
    );
  }
}