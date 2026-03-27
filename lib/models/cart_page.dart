import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';

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

  @override
  Widget build(BuildContext context) {

    List<CartItem> items = Cart.getItems(widget.service);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// APPBAR
      appBar: AppBar(
        title: Text("${widget.service} Cart"),
        centerTitle: true,
      ),

      /// EMPTY CART
      body: items.isEmpty
          ? const Center(
              child: Text(
                "Cart is empty",
                style: TextStyle(fontSize: 16),
              ),
            )

          /// CART LIST
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

                      /// IMAGE
                      if (item.image != null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
                          child: Image.asset(
                            item.image!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(width: 12),

                      /// DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            /// NAME
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// PRICE
                            Text(
                              "₹${item.price}",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// COUNTER
                            Row(
                              children: [

                                /// REMOVE
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      Cart.remove(item);
                                    });
                                  },
                                ),

                                Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                /// ADD
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      Cart.add(
                                        CartItem(
                                          id: item.id,
                                          name: item.name,
                                          price: item.price,
                                          service: item.service,
                                          category: item.category,
                                          image: item.image,
                                        ),
                                        service: item.service,
                                      );
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),

                      /// DELETE
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

      /// BOTTOM BOOKING
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// TOTAL
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${Cart.getTotal(widget.service)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// BOOKING BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFAE91BA),
                      ),
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(
                              serviceName: widget.service,
                              cart: Cart.getItems(widget.service), products: null,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Proceed to Booking",
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}