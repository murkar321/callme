import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../screens/salon_booking_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;

  const SalonServiceCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    const serviceName = "Salon";
    final id = "Salon_${service.name}";
    final qty = Cart.getQuantity(id, serviceName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (service.discount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${service.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// NAME
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// SLOGAN
                    Text(
                      service.slogan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// RATING + TIME
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          service.rating.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            service.time,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          "₹${service.finalPrice}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (service.discount > 0)
                          Text(
                            "₹${service.price}",
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SalonDetailPage(
                                      service: service,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("View"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                _showBooking(context, service, id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFAE91BA),
                              ),
                              child: Text(
                                qty == 0 ? "Book" : "$qty",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBooking(BuildContext context, SalonService service, String id) {
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
