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
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F5F7),
        title: Text(
          "${widget.service} Cart",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      /// ================= BODY =================
      body: items.isEmpty
          ? _emptyState()

          : ListView.builder(

              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                140,
              ),

              itemCount: items.length,

              itemBuilder: (_, index) {

                final item = items[index];

                return Container(

                  margin: const EdgeInsets.only(
                    bottom: 14,
                  ),

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      /// ================= IMAGE =================
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(16),

                        child: Container(
                          width: 95,
                          height: 95,
                          color: Colors.grey.shade100,

                          child: item.image != null

                              ? Image.asset(
                                  item.image!,
                                  fit: BoxFit.cover,

                                  errorBuilder:
                                      (_, __, ___) {

                                    return Icon(
                                      Icons.image,
                                      color: Colors
                                          .grey.shade400,
                                    );
                                  },
                                )

                              : Icon(
                                  Icons.image,
                                  color:
                                      Colors.grey.shade400,
                                ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// ================= DETAILS =================
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            /// TITLE
                            Text(
                              item.name,

                              maxLines: 2,

                              overflow:
                                  TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 18,
                                height: 1.3,
                              ),
                            ),

                            /// VISIT TYPE
                            if (widget.service ==
                                "Salon") ...[

                              const SizedBox(height: 6),

                              Text(
                                getVisitType(item),

                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            /// PRICE
                            Text(
                              "₹${item.price}",

                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 14),

                            /// QTY CONTROLS
                            Row(
                              children: [

                                _qtyButton(
                                  icon: Icons.remove,

                                  onTap: () {

                                    Cart.removeById(
                                      item.id,
                                      widget.service,
                                    );

                                    refresh();
                                  },
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 14,
                                  ),

                                  child: Text(
                                    "${item.quantity}",

                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                _qtyButton(
                                  icon: Icons.add,

                                  onTap: () {

                                    Cart.add(
                                      item,
                                      service:
                                          widget.service,
                                    );

                                    refresh();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// ================= DELETE =================
                      IconButton(

                        onPressed: () {

                          Cart.delete(
                            item.id,
                            widget.service,
                          );

                          refresh();
                        },

                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

      /// ================= BOTTOM BAR =================
      bottomNavigationBar: items.isEmpty

          ? null

          : SafeArea(

              child: Container(

                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  16,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],

                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [

                    /// TOTAL ROW
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        const Text(
                          "Total Amount",

                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        Text(
                          "₹$totalAmount",

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// BUTTON
                    SizedBox(

                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton(

                        style:
                            ElevatedButton.styleFrom(
                          elevation: 0,

                          backgroundColor:
                              const Color(0xFFAE91BA),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),

                        onPressed: () async {

                          /// EDUCATION
                          if (widget.service ==
                              "Education") {

                            await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    EnquiryPage(
                                  serviceName:
                                      "Education",

                                  cart: items,
                                ),
                              ),
                            );
                          }

                          /// SALON
                          else if (widget.service ==
                              "Salon") {

                            await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    SalonBookingPage(
                                  cartItems: items,
                                ),
                              ),
                            );
                          }

                          /// DEFAULT
                          else {

                            await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingPage(
                                  serviceName:
                                      widget.service,

                                  cart: items,

                                  products: [],
                                ),
                              ),
                            );
                          }

                          refresh();
                        },

                        child: Text(

                          widget.service ==
                                  "Education"

                              ? "Proceed to Enquiry"

                              : "Proceed to Booking",

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= QTY BUTTON =================
  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return InkWell(

      borderRadius: BorderRadius.circular(50),

      onTap: onTap,

      child: Container(

        width: 34,
        height: 34,

        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
          ),

          shape: BoxShape.circle,
        ),

        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// ================= EMPTY STATE =================
  Widget _emptyState() {

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 14),

          Text(
            "Cart is empty",

            style: TextStyle(
              fontSize: 17,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}