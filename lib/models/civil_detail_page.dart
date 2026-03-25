import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import 'package:callme/screens/civil_book_page.dart';

class CivilServiceDetailPage extends StatelessWidget {
  final SubService service;
  final String mainServiceId;

  const CivilServiceDetailPage({
    super.key,
    required this.service,
    required this.mainServiceId,
  });

  @override
  Widget build(BuildContext context) {
    final isRenovation = mainServiceId == "renovation";

    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🖼️ IMAGE
            Image.asset(
              service.image,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 10),

            /// 📋 DETAILS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    service.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  /// PRICE
                  Text(
                    service.price,
                    style: const TextStyle(
                        color: Colors.green, fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  /// ⭐ RATING + DISCOUNT
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text("${service.rating}"),
                      const SizedBox(width: 10),
                      Text(
                        "${service.discount}% OFF",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 🔥 FEATURES FROM DATA (FIXED)
                  if (service.features != null &&
                      service.features!.isNotEmpty) ...[
                    const Text(
                      "What’s Included",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    ...service.features!
                        .map((e) => _bullet(e))
                        .toList(),
                  ],

                  const SizedBox(height: 20),

                  /// 📌 NOTE (ONLY FOR RENOVATION)
                  if (isRenovation)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📌 Note",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("• Customize services before booking"),
                          Text("• Final cost depends on selection"),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// 🔘 BOOK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isRenovation) {
                          /// 👉 CLOSE DETAIL → OPEN POPUP (BACK FLOW)
                          Navigator.pop(context);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CivilBookingPage(
                                serviceName: service.name,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        isRenovation ? "Customize & Book" : "Book Now",
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ✅ BULLET WIDGET
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}