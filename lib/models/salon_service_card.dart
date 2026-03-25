import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_booking_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;

  const SalonServiceCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    const String serviceName = "Salon";
    final String id = "Salon_${service.name}";
    Cart.getQuantity(id, serviceName);

    return Container(
      height: 210, // ✅ FIXED HEIGHT (important)
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

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

          /// 🔹 TOP IMAGE (LIKE YOUR UI)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [

                Image.asset(
                  service.image,
                  height: 95,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// OPTIONAL DISCOUNT TAG
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

          /// 🔹 DETAILS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  /// NAME
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  /// DESCRIPTION
                  Text(
                    service.slogan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  /// RATING + TIME (STATIC LIKE YOUR UI)
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.orange, size: 14),
                      SizedBox(width: 4),
                      Text("4.5", style: TextStyle(fontSize: 12)),
                      SizedBox(width: 10),
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("30 minutes",
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),

                  /// PRICE + BUTTON (FIXED ROW)
                  Row(
                    children: [

                      /// PRICE
                      Expanded(
                        child: Text(
                          "₹${service.finalPrice}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      /// BUTTON (COMPACT → NO OVERFLOW)
                      SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            _showBooking(context, service, id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(fontSize: 11),
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
    const String serviceName = "Salon";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Choose Appointment",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 16),

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
          ),
        );
      },
    );
  }
}