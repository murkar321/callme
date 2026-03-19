import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/screens/salon_booking_page.dart';
import 'package:callme/data/salon_data.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: Cart.items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView.builder(
              itemCount: Cart.items.length,
              itemBuilder: (context, index) {
                final item = Cart.items[index];
                final guests = Cart.guestData[item];

                return ListTile(
                  leading: Image.asset(item.imagePath, width: 50),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("₹${item.price}"),
                      if (guests != null)
                        Text(
                          "Adults: ${guests["adults"]}, Children: ${guests["children"]}",
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Cart.items.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  final firstItem = Cart.items.first;
                  final guests = Cart.guestData[firstItem];

                  /// 🔥 MAP CART → SALON SERVICES
                  final selectedServices = salonServices
                      .where(
                          (s) => Cart.items.any((item) => item.name == s.name))
                      .toList();

                  /// 🔥 SHOW HOME / SALON OPTION
                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text("Salon Appointment"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SalonBookingPage(
                                    services: selectedServices,
                                    isHomeVisitDefault: false,
                                    service: selectedServices.first,
                                    serviceName: selectedServices.first.name,

                                    /// ✅ PASS GUESTS
                                    adults: guests?["adults"] ?? 1,
                                    children: guests?["children"] ?? 0,
                                  ),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            title: const Text("Home Visit"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SalonBookingPage(
                                    services: selectedServices,
                                    isHomeVisitDefault: true,
                                    service: selectedServices.first,
                                    serviceName: selectedServices.first.name,

                                    /// ✅ PASS GUESTS
                                    adults: guests?["adults"] ?? 1,
                                    children: guests?["children"] ?? 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Proceed to Booking"),
              ),
            )
          : null,
    );
  }
}
