import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../models/cart_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;
  final VoidCallback? onUpdate;

  const SalonServiceCard({
    super.key,
    required this.service,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {

    const serviceName = "Salon";

    final homeId = "${service.id}_home";
    final salonId = "${service.id}_salon";

    final qtyHome = Cart.getQuantity(homeId, serviceName);
    final qtySalon = Cart.getQuantity(salonId, serviceName);

    final totalQty = qtyHome + qtySalon;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.asset(
              service.image,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  service.slogan,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${service.price}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalonDetailPage(service: service),
                            ),
                          );
                        },
                        child: const Text("View"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAE91BA),
                        ),
                        onPressed: () => _showPopup(context),
                        child: Text(
                          totalQty == 0 ? "Book" : "Added ($totalQty)",
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showPopup(BuildContext context) {

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [

              const Center(
                child: Text(
                  "Choose Appointment Type",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home Appointment"),
                onTap: () {

                  Cart.addSalon(
                    id: "${service.id}_home",
                    name: service.name,
                    price: service.finalPrice,
                    category: service.category,
                    visitType: "Home",
                    image: service.image,
                  );

                  Navigator.pop(context);
                  if (onUpdate != null) onUpdate!();
                },
              ),

              ListTile(
                leading: const Icon(Icons.store),
                title: const Text("Salon Appointment"),
                onTap: () {

                  Cart.addSalon(
                    id: "${service.id}_salon",
                    name: service.name,
                    price: service.finalPrice,
                    category: service.category,
                    visitType: "Salon",
                    image: service.image,
                  );

                  Navigator.pop(context);
                  if (onUpdate != null) onUpdate!();
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text("View Cart"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(
                        service: "Salon",
                        serviceName: "Salon",
                        cart: [],
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
  }
}