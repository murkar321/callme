import 'package:flutter/material.dart';
import '../models/service_product.dart';
import 'booking_page.dart';

class ResortDetailPage extends StatefulWidget {
  final ServiceProduct service;

  const ResortDetailPage({super.key, required this.service});

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {
  int adultCount = 1;
  int childCount = 0;

  /// 🔹 GUEST POPUP (UNCHANGED)
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 8),
                      Text(
                        "Select Guests",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(
                              serviceName: widget.service.name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffAE91BA),
                      ),
                      child: const Text("Continue"),
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

  /// 🔹 COUNTER CARD
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              _circleButton(Icons.remove, onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text("$count"),
              ),
              _circleButton(Icons.add, onAdd),
            ],
          )
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xffAE91BA).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18),
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

      /// 🔹 BOOK BUTTON
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: showGuestSelectionPopup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffAE91BA),
          ),
          child: const Text("Book Now"),
        ),
      ),

      /// 🔥 LEFT + RIGHT PANEL UI
      body: Row(
        children: [
          /// 🔹 LEFT PANEL (INFO)
          Container(
            width: 100,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sideItem(Icons.star, service.safeRating.toString()),
                _sideItem(Icons.access_time, service.serviceTime),
                _sideItem(Icons.currency_rupee,
                    service.formattedPrice.replaceAll("₹", "")),
              ],
            ),
          ),

          /// 🔹 RIGHT PANEL (DETAILS)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IMAGE
                  Image.asset(
                    service.imagePath,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TITLE
                        Text(
                          service.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        /// DESCRIPTION
                        if (service.description != null)
                          Text(
                            service.description!,
                            style: const TextStyle(color: Colors.grey),
                          ),

                        const SizedBox(height: 20),

                        /// INCLUDES
                        if (service.safeIncludes.isNotEmpty)
                          const Text(
                            "Includes",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                        const SizedBox(height: 10),

                        ...service.safeIncludes.map(
                          (e) => Row(
                            children: [
                              const Icon(Icons.check,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(e),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 SIDE ITEM
  Widget _sideItem(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
