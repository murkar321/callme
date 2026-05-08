import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../bookings/booking_page.dart';
import '../bookings/salon_booking_page.dart';
import '../bookings/enquiry_page.dart';

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

  /// ================= TOTAL =================
  int get totalAmount => Cart.getTotal(widget.service);

  /// ================= VISIT TYPE =================
  String getVisitType(dynamic item) {
    if (widget.service != "Salon") return "";
    return item.id.toString().contains("Home")
        ? "Home Visit"
        : "Salon Visit";
  }

  @override
  Widget build(BuildContext context) {
    final items = Cart.getItems(widget.service);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      /// ================= APP BAR =================
      appBar: AppBar(
        title: Text("${widget.service} Cart"),
        centerTitle: true,
      ),

      /// ================= BODY =================
      body: items.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [

                      /// IMAGE
                      if (item.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            item.image!,
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(width: 12),

                      /// DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// NAME
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// VISIT TYPE
                            if (widget.service == "Salon")
                              Text(
                                getVisitType(item),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                            const SizedBox(height: 6),

                            /// PRICE
                            Text(
                              "₹${item.price}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// QTY CONTROLS
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Cart.removeById(
                                        item.id, widget.service);
                                    refresh();
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text("${item.quantity}"),
                                IconButton(
                                  onPressed: () {
                                    Cart.add(item,
                                        service: widget.service);
                                    refresh();
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      /// DELETE
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

      /// ================= BOTTOM =================
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text(
                        "₹$totalAmount",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAE91BA),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {

                        /// 🎓 EDUCATION
                        if (widget.service == "Education") {
                          await Navigator.push(
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalonBookingPage(
                                cartItems: items,
                              ),
                            ),
                          );
                        }

                        /// 🌍 DEFAULT
                        else {
                          await Navigator.push(
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

                        /// 🔥 REFRESH AFTER RETURN
                        refresh();
                      },
                      child: Text(
                        widget.service == "Education"
                            ? "Proceed to Enquiry"
                            : "Proceed to Booking",
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ================= EMPTY STATE =================
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 70, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Cart is empty",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}