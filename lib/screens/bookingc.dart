import 'package:flutter/material.dart';
import '../models/cleaning_service.dart';

class CleaningBookingPage extends StatelessWidget {
  final CleaningService service;

  const CleaningBookingPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(service.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Select Date & Time (Coming Soon)"),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Confirm Booking"),
            )
          ],
        ),
      ),
    );
  }
}
