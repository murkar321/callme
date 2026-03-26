import 'package:flutter/material.dart';
import '../models/service_product.dart';
import 'package:callme/screens/booking_page.dart';

class ResortDetailPage extends StatefulWidget {
  final ServiceProduct service;

  const ResortDetailPage({super.key, required this.service});

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {
  int adults = 1;
  int children = 0;

  void _showGuestPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Guests"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Adults
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Adults"),
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          if (adults > 1) setState(() => adults--);
                        },
                        icon: const Icon(Icons.remove)),
                    Text(adults.toString()),
                    IconButton(
                        onPressed: () => setState(() => adults++),
                        icon: const Icon(Icons.add)),
                  ],
                )
              ],
            ),
            // Children
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Children"),
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          if (children > 0) setState(() => children--);
                        },
                        icon: const Icon(Icons.remove)),
                    Text(children.toString()),
                    IconButton(
                        onPressed: () => setState(() => children++),
                        icon: const Icon(Icons.add)),
                  ],
                )
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingPage(
                    service: widget.service,
                    adults: adults,
                    children: children,
                    serviceName:
                        '${widget.service.name} - $adults Adults, $children Children',
                    products: [],
                  ),
                ),
              );
            },
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Discount
            Stack(
              children: [
                SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Image.asset(service.imagePath, fit: BoxFit.cover)),
                if (service.discount != null && service.discount! > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${service.discount}% OFF',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(service.rating.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₹${service.finalPrice}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      if (service.price != service.finalPrice)
                        Text(
                          '₹${service.price}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Includes
                  if (service.includes != null &&
                      service.includes!.isNotEmpty) ...[
                    const Text("Includes",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...service.includes!
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(e)),
                                ],
                              ),
                            ))
                        .toList(),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Booking Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _showGuestPicker,
          child: const Text("Book Now"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ),
    );
  }
}
