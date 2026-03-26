import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import '../data/resorts_data.dart';


class ResortBookingPopup extends StatefulWidget {
  final Resort resort;

  const ResortBookingPopup({super.key, required this.resort, required String id, required String name, required int price, required String image});

  @override
  State<ResortBookingPopup> createState() => _ResortBookingPopupState();
}

class _ResortBookingPopupState extends State<ResortBookingPopup> {
  int adults = 1;
  int children = 0;

  int get totalPrice {
    return (adults + children) * widget.resort.price;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text(
              "Select Guests",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// ADULTS
            _guestCounter(
              label: "Adults",
              count: adults,
              onIncrement: () {
                setState(() => adults++);
              },
              onDecrement: () {
                if (adults > 1) setState(() => adults--);
              },
            ),

            const SizedBox(height: 10),

            /// CHILDREN
            _guestCounter(
              label: "Children",
              count: children,
              onIncrement: () {
                setState(() => children++);
              },
              onDecrement: () {
                if (children > 0) setState(() => children--);
              },
            ),

            const SizedBox(height: 20),

            /// TOTAL PRICE
            Text(
              "Total: ₹$totalPrice",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            /// CONTINUE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close popup
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: widget.resort.name,
                        adults: adults,
                        children: children,
                        product: null, products: null,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(14),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// COUNTER WIDGET
  Widget _guestCounter({
    required String label,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              "$count",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}