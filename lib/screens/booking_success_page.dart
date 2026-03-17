import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/salon_data.dart';

class BookingSuccessPage extends StatelessWidget {
  final List<SalonService> services;
  final String bookingId;
  final DateTime date;
  final TimeOfDay time;
  final bool isHomeVisit;
  final String address;

  const BookingSuccessPage({
    super.key,
    required this.services,
    required this.bookingId,
    required this.date,
    required this.time,
    required this.isHomeVisit,
    required this.address,
  });

  /// ✅ SAFE TOTAL
  int get totalPrice {
    return services.fold(
      0,
      (sum, item) => sum + (item.finalPrice ?? item.price),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String salonName = "Beauty Glow Salon";
    final String salonAddress = "45, MG Road, Pune, Maharashtra";
    final String contact = "9876543210";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Confirmed"),
        automaticallyImplyLeading: false,
      ),

      /// 🔥 RESPONSIVE BODY
      body: LayoutBuilder(
        builder: (context, constraints) {

          double maxWidth = constraints.maxWidth > 600 ? 500 : double.infinity;

          return Center(
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  /// 🔽 SCROLLABLE CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// ✅ SUCCESS ICON
                          const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 90,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// MESSAGE
                          Center(
                            child: Text(
                              isHomeVisit
                                  ? "Your home service is booked successfully!"
                                  : "Your salon appointment is booked successfully!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          /// 📋 DETAILS CARD
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Booking ID: $bookingId"),
                                Text("Date: ${DateFormat('dd MMM yyyy').format(date)}"),
                                Text("Time: ${time.format(context)}"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// 🔥 SERVICES CARD
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Services Booked",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),

                                ...services.map((service) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(service.name),
                                      trailing: Text(
                                        "₹${service.finalPrice ?? service.price}",
                                      ),
                                    )),

                                const Divider(),

                                Text(
                                  "Total: ₹$totalPrice",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// 📍 LOCATION CARD
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isHomeVisit) ...[
                                  Text("Service Address: $address"),
                                  const SizedBox(height: 8),
                                  const Text("Provider: Riya Sharma"),
                                  const Text("Contact: 9876543210"),
                                ] else ...[
                                  Text("Salon: $salonName"),
                                  Text("Address: $salonAddress"),
                                  Text("Contact: $contact"),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 🔥 STICKY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text("Back to Home"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🔥 REUSABLE CARD
  Widget _card({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}