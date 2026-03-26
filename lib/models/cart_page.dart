import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartPage extends StatefulWidget {
  final String? service; // optional filter

  const CartPage({
    super.key,
    this.service, required String serviceName, required List<dynamic> cart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  /// GROUP BY SERVICE
  Map<String, List<CartItem>> groupByService(List<CartItem> items) {
    final Map<String, List<CartItem>> data = {};

    for (var item in items) {
      data.putIfAbsent(item.service, () => []);
      data[item.service]!.add(item);
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {

    /// FILTER ITEMS
    final items = widget.service == null
        ? Cart.allItems
        : Cart.getItems(widget.service!);

    final cartData = groupByService(items);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null
              ? "Your Cart"
              : "${widget.service} Cart",
        ),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text("Cart is empty"),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: cartData.entries.map((entry) {

                final service = entry.key;
                final serviceItems = entry.value;

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// SERVICE TITLE
                    Text(
                      service,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// ITEMS
                    ...serviceItems.map((item) {
                      return Card(
                        child: ListTile(

                          /// IMAGE
                          leading: item.image != null
                              ? Image.asset(
                                  item.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.shopping_bag),

                          /// NAME
                          title: Text(item.name),

                          /// CATEGORY
                          subtitle: Text(
                            "Category: ${item.category}",
                          ),

                          /// PRICE + QTY
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [

                              Text("₹${item.price}"),

                              const SizedBox(height: 4),

                              Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [

                                  /// REMOVE
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Cart.removeById(
                                          item.id,
                                          item.service,
                                        );
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),

                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6),
                                    child: Text(
                                      item.quantity
                                          .toString(),
                                    ),
                                  ),

                                  /// ADD
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Cart.addItem(
                                          name: item.name,
                                          price: item.price,
                                          category:
                                              item.category,
                                          service:
                                              item.service,
                                          id: item.id,
                                          image:
                                              item.image,
                                        );
                                      });
                                    },
                                    child: const Icon(
                                      Icons.add_circle,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    /// SUBTOTAL
                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: Text(
                        "Subtotal: ₹${Cart.getTotal(service)}",
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// BOOK BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingPage(
                                serviceName:
                                    service,
                                products:
                                    serviceItems,
                                price: Cart
                                    .getTotal(
                                        service),
                              ),
                            ),
                          ).then((_) =>
                              setState(() {}));
                        },
                        child: Text(
                          "Book $service",
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Divider(thickness: 2),
                  ],
                );
              }).toList(),
            ),

      /// GRAND TOTAL
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    "${Cart.getTotalItems(widget.service)} items",
                    style: const TextStyle(
                        color: Colors.white),
                  ),

                  Text(
                    "Total: ₹${widget.service == null ? Cart.getGrandTotal() : Cart.getTotal(widget.service!)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}