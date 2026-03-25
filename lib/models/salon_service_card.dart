import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../screens/salon_booking_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;

  const SalonServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const serviceName = "Salon";
    final id = "Salon_${service.name}";
    final qty = Cart.getQuantity(id, serviceName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// DISCOUNT
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${service.discount}% OFF",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),

                  const SizedBox(height: 2),

                  /// DESC
                  Text(
                    service.slogan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),

                  const SizedBox(height: 4),

                  /// BADGES
                  Row(
                    children: const [
                      Icon(Icons.star, size: 12, color: Colors.orange),
                      SizedBox(width: 2),
                      Text("4.5", style: TextStyle(fontSize: 11)),
                      SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      SizedBox(width: 2),
                      Text("30 min", style: TextStyle(fontSize: 11)),
                    ],
                  ),

                  const Spacer(),

                  /// PRICE
                  Text(
                    "₹${service.finalPrice}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),

                  const SizedBox(height: 4),

                  /// BUTTON ROW (FIXED)
                  Row(
                    children: [

                      /// VIEW DETAILS
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SalonDetailPage(service: service),
                                ),
                              );
                            },
                            child: const Text(
                              "View",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      /// BOOK BUTTON
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            _showBooking(context, service, id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAE91BA),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                          ),
                          child: Text(
                            qty == 0 ? "Book" : "$qty",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBooking(
      BuildContext context, SalonService service, String id) {
    const serviceName = "Salon";

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home Appointment"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonBookingPage(
                      services: [service],
                      isHomeVisitDefault: true,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.store),
              title: const Text("Salon Appointment"),
              onTap: () {
                Cart.add(
                  CartItem(
                    id: id,
                    name: service.name,
                    price: service.finalPrice,
                    service: serviceName,
                    category: service.category,
                    image: service.image,
                  ),
                  service: serviceName,
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}