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

    const String serviceName = "Salon";
    final String id = "Salon_${service.name}";
    final int qty = Cart.getQuantity(id, serviceName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),

      child: Row(
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              service.image,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 10),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 4),

                /// SLOGAN
                Text(
                  service.slogan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                /// PRICE
                Row(
                  children: [

                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      "₹${service.price}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// VIEW DETAILS
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SalonDetailPage(service: service),
                      ),
                    );
                  },
                  child: const Text(
                    "View Details",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// BOOK BUTTON
          ElevatedButton(
            onPressed: () {

              showDialog(
                context: context,
                builder: (context) {

                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    title: const Text("Choose Appointment"),

                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        /// HOME APPOINTMENT
                        ListTile(
                          leading: const Icon(Icons.home, color: Colors.purple),
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

                        const Divider(),

                        /// SALON APPOINTMENT
                        ListTile(
                          leading: const Icon(Icons.store, color: Colors.green),
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

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${service.name} added to cart",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAE91BA),
            ),

            child: Text(
              qty == 0 ? "Book" : "Added ($qty)",
            ),
          ),
        ],
      ),
    );
  }
}