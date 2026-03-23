import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartPage extends StatefulWidget {
  const CartPage(
      {super.key, required String service, required String serviceName});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  /// 🔥 GROUP ITEMS BY SERVICE
  Map<String, List<CartItem>> groupByService(List<CartItem> items) {
    final Map<String, List<CartItem>> data = {};

    for (var item in items) {
      if (!data.containsKey(item.service)) {
        data[item.service] = [];
      }
      data[item.service]!.add(item);
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final items = Cart.allItems;
    final cartData = groupByService(items);

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),

      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: cartData.entries.map((entry) {
                String service = entry.key;
                List<CartItem> serviceItems = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 SERVICE TITLE
                    Text(
                      service,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// 🔹 ITEMS LIST
                    ...serviceItems.map((item) {
                      return Card(
                        child: ListTile(
                          leading: item.image != null
                              ? Image.asset(
                                  item.image!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.shopping_bag),

                          title: Text(item.name),

                          subtitle: Text(
                            "Category: ${item.category}",
                          ),

                          /// 🔥 PRICE + QUANTITY
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("₹${item.price}"),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /// ➖
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Cart.removeById(item.id, item.service);
                                      });
                                    },
                                    child: const Icon(Icons.remove_circle),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(item.quantity.toString()),
                                  ),

                                  /// ➕
                                  GestureDetector(
                                    onTap: () {
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
                                    child: const Icon(Icons.add_circle),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    /// 🔹 SERVICE TOTAL
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Subtotal: ₹${Cart.getTotal(service)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// 🔹 BOOK BUTTON
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(serviceName: service, products: null,),
                          ),
                        );
                      },
                      child: Text("Book $service"),
                    ),

                    const Divider(thickness: 2),
                  ],
                );
              }).toList(),
            ),

      /// 🔥 TOTAL BAR
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${Cart.getTotalItems()} items",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Total: ₹${Cart.getGrandTotal()}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
