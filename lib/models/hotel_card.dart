import 'package:flutter/material.dart';
import '../data/hotel_data.dart';

class HotelCard extends StatelessWidget {
  final HotelRoom hotel;
  final VoidCallback onView;
  final VoidCallback onAddCart;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onView,
    required this.onAddCart,
  });

  @override
  Widget build(BuildContext context) {
    final price =
        hotel.price - (hotel.price * hotel.discount ~/ 100);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Image.asset(hotel.image, height: 100, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hotel.hotelName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                Text(hotel.city, style: const TextStyle(fontSize: 10)),

                Text("₹$price",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onView,
                        child: const Text("View",
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAddCart,
                        child: const Text("Book",
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}