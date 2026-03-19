import 'package:flutter/material.dart';
import '../models/service_product.dart';
import 'booking_page.dart'; // ✅ ADD THIS

class ResortDetailPage extends StatefulWidget {
  final ServiceProduct service;

  const ResortDetailPage({super.key, required this.service});

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {
  int adultCount = 1;
  int childCount = 0;

  /// ✅ MODERN POPUP
  void showGuestSelectionPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔹 TITLE
                  Row(
                    children: const [
                      Icon(Icons.people, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        "Select Guests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 ADULT
                  _modernCounterCard(
                    label: "Adult",
                    subtitle: "Above 10 years",
                    count: adultCount,
                    onAdd: () => setModalState(() => adultCount++),
                    onRemove: () {
                      if (adultCount > 1) {
                        setModalState(() => adultCount--);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 CHILD
                  _modernCounterCard(
                    label: "Child",
                    subtitle: "3 to 9 years",
                    count: childCount,
                    onAdd: () => setModalState(() => childCount++),
                    onRemove: () {
                      if (childCount > 0) {
                        setModalState(() => childCount--);
                      }
                    },
                  ),

                  const SizedBox(height: 18),

                  /// 🔹 CONTINUE BUTTON (UPDATED)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        /// ✅ NAVIGATE TO EXISTING BOOKING PAGE
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(
                              serviceName: widget.service.name,
                              cartItems: {},
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffAE91BA),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 🔹 MODERN CARD
  Widget _modernCounterCard({
    required String label,
    required String subtitle,
    required int count,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF5F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          /// COUNTER
          Row(
            children: [
              _circleButton(Icons.remove, onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _circleButton(Icons.add, onAdd),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 ROUND BUTTON
  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xffAE91BA).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        backgroundColor: const Color(0xffAE91BA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                service.imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 15),

            /// NAME
            Text(
              service.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            /// RATING
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                const SizedBox(width: 5),
                Text(
                  service.safeRating.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// PRICE
            Row(
              children: [
                Text(
                  service.formattedPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                if (service.discount != null && service.discount! > 0)
                  Text(
                    "₹${service.price}",
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 10),
                if (service.discountLabel.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.discountLabel,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            /// TIME
            Text(
              "Duration: ${service.serviceTime}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 15),

            /// DESCRIPTION
            if (service.description != null && service.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 15),

            /// INCLUDES
            if (service.safeIncludes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Includes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: service.safeIncludes.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 25),

            /// BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: showGuestSelectionPopup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xffAE91BA),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
