import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../screens/booking_page.dart';
import '../screens/salon_booking_page.dart';
import '../models/enquiry_page.dart';
import '../data/salon_data.dart';

class CartPage extends StatefulWidget {
  final String service;

  const CartPage({
    super.key,
    required this.service, required String serviceName, required List<dynamic> cart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    List<CartItem> items = Cart.getItems(widget.service);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔝 APP BAR
      appBar: AppBar(
        title: Text("${widget.service} Cart"),
        centerTitle: true,
      ),

      /// 📦 BODY
      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
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
                      /// 🖼 IMAGE
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

                      /// 📄 DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text("₹${item.price}"),
                            const SizedBox(height: 10),

                            /// ➕➖ QUANTITY
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      Cart.removeById(
                                        item.id,
                                        widget.service,
                                      );
                                    });
                                  },
                                ),
                                Text("${item.quantity}"),
                                IconButton(
                                  icon: const Icon(
                                      Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      Cart.add(
                                        item,
                                        service: widget.service,
                                      );
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      /// 🗑 DELETE
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            Cart.delete(item.id, widget.service);
                          });
                        },
                      )
                    ],
                  ),
                );
              },
            ),

      /// 🔻 BOTTOM BUTTON
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAE91BA),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {

                  /// ================= SALON =================
                  if (widget.service == "Salon") {
                    List<SalonService> selectedServices = [];
                    Map<String, String> visitTypeMap = {};

                    for (var item in items) {
                      try {
                        final realId =
                            item.id.toString().split("_")[0];

                        final service =
                            salonServices.firstWhere(
                          (s) =>
                              s.id.toString().trim() ==
                              realId.trim(),
                        );

                        selectedServices.add(service);

                        visitTypeMap[realId] =
                            (item.visitType ?? "Salon");
                      } catch (e) {
                        debugPrint(
                            "Salon match failed: ${item.id}");
                      }
                    }

                    if (selectedServices.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                              "No valid salon services found"),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonBookingPage(
                          services: selectedServices,
                          visitTypeMap: visitTypeMap,
                        ),
                      ),
                    );
                  }

                  /// ================= EDUCATION (ENQUIRY) =================
                  else if (widget.service == "Education") {
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

                  /// ================= DEFAULT FLOW =================
                  else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(
                          serviceName: widget.service,
                          cart: items, products: [], // ✅ FIXED
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