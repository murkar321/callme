import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../bookings/booking_page.dart';
import '../bookings/salon_booking_page.dart';
import '../bookings/enquiry_page.dart';

class CartPage extends StatefulWidget {
  final String service;

  const CartPage({
    super.key,
    required this.service,
    required String serviceName,
    required List<dynamic> cart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = Cart.getItems(widget.service);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: Text("${widget.service} Cart"),
        centerTitle: true,
      ),

      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (item.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            item.image!,
                            height: 65,
                            width: 65,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text("₹${item.price}"),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    Cart.removeById(
                                        item.id, widget.service);
                                    refresh();
                                  },
                                ),
                                Text("${item.quantity}"),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    Cart.add(item,
                                        service: widget.service);
                                    refresh();
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Cart.delete(item.id, widget.service);
                          refresh();
                        },
                      )
                    ],
                  ),
                );
              },
            ),

      /// 🔻 BUTTON
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () {

                  /// 🎓 EDUCATION
                  if (widget.service == "Education") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EnquiryPage(
                          serviceName: "Education",
                          cart: items,
                        ),
                      ),
                    );
                  }

                  /// 💇 SALON
                  else if (widget.service == "Salon") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SalonBookingPage(services: [], visitTypeMap: {}),
                      ),
                    );
                  }

                  /// 🌍 DEFAULT (Cleaning, Water, Plumbing etc.)
                  else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(
                          serviceName: widget.service,
                          cart: items,
                          products: [],
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  widget.service == "Education"
                      ? "Proceed to Enquiry"
                      : "Proceed to Booking",
                ),
              ),
            ),
    );
  }
}