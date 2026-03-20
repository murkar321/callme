import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/service_product.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required String serviceName});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartData = Cart.serviceItems;

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),

      body: cartData.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: cartData.entries.map((entry) {
                String service = entry.key;
                List<ServiceProduct> items = entry.value;

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
                    ...items.map((item) {
                      int qty = Cart.getQuantity(item);

                      return Card(
                        child: ListTile(
                          leading: Image.asset(
                            item.imagePath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),

                          title: Text(item.name),

                          subtitle: Text(
                            "${item.serviceTime} • ${item.discountLabel}",
                          ),

                          /// 🔥 PRICE + QUANTITY CONTROLS
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("₹${item.calculatedFinalPrice}"),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /// ➖
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Cart.remove(item);
                                      });
                                    },
                                    child: const Icon(Icons.remove_circle),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(qty.toString()),
                                  ),

                                  /// ➕
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Cart.add(item, service: '');
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

                    /// 🔹 BOOK BUTTON (SERVICE-WISE)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingPage(
                              serviceName: '',
                            ),
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

      /// 🔥 BOTTOM TOTAL BAR (ALL SERVICES)
      bottomNavigationBar: cartData.isEmpty
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
