import 'package:flutter/material.dart';
import 'package:callme/screens/booking_page.dart';
import '../models/cart.dart';
import '../screens/salon_booking_page.dart';
import '../data/salon_data.dart';

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
  @override
  Widget build(BuildContext context) {
    List<CartItem> items = Cart.getItems(widget.service);

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
              itemBuilder: (context, index) {
                CartItem item = items[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      if (item.image != null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// KEEP SALON SAME
                            if (widget.service ==
                                    "Salon" &&
                                item.visitType != null)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.pink
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                ),
                                child: Text(
                                  item.visitType!,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.pink,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 4),

                            Text("₹${item.price}"),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons
                                        .remove_circle_outline,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      Cart.remove(
                                          item);
                                    });
                                  },
                                ),

                                Text(item.quantity
                                    .toString()),

                                IconButton(
                                  icon: const Icon(
                                    Icons
                                        .add_circle_outline,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      Cart.add(
                                        item,
                                        service: item
                                            .service,
                                      );
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            Cart.delete(
                              item.id,
                              widget.service,
                            );
                          });
                        },
                      )
                    ],
                  ),
                );
              },
            ),

      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFAE91BA),
                ),
                onPressed: () {
                  /// ================= SALON KEEP SAME =================
                  if (widget.service == "Salon") {
                    List<SalonService>
                        selectedServices = [];

                    Map<String, String>
                        visitTypeMap = {};

                    for (var item in items) {
                      try {
                        final service =
                            salonServices.firstWhere(
                          (s) =>
                              s.id
                                  .toString()
                                  .trim() ==
                              item.id
                                  .toString()
                                  .trim(),
                        );

                        selectedServices
                            .add(service);

                        visitTypeMap[service.id
                                .toString()] =
                            item.visitType ??
                                "Salon";
                      } catch (e) {
                        debugPrint(
                          "Salon match failed for id: ${item.id}",
                        );
                      }
                    }

                    if (selectedServices
                        .isEmpty) {
                      ScaffoldMessenger.of(
                              context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "No valid salon services found",
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SalonBookingPage(
                          services:
                              selectedServices,
                          visitTypeMap:
                              visitTypeMap,
                        ),
                      ),
                    );
                  }

                  /// ================= STRICT PLUMBING FIX =================
                  else if (widget.service ==
                      "Plumbing") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingPage(
                          serviceName:
                              "Plumbing",
                          cart: items,
                          products: null,
                        ),
                      ),
                    );
                  }

                  /// ================= OTHER SERVICES SAME =================
                  else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingPage(
                          serviceName:
                              widget.service,
                          cart: Cart.getItems(
                              widget.service),
                          products: null,
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                    "Proceed to Booking"),
              ),
            ),
    );
  }
}