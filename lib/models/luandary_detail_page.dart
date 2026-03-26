import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';

class LaundryDetailPage extends StatefulWidget {
  final dynamic product;
  final String serviceName;
  final String category;

  const LaundryDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
    required this.category,
  });

  @override
  State<LaundryDetailPage> createState() => _LaundryDetailPageState();
}

class _LaundryDetailPageState extends State<LaundryDetailPage> {
  int qty = 1;
  String selectedFabric = "Cotton";

  final Color primaryColor = const Color(0xFFAE91BA);

  late List<Map<String, dynamic>> fabrics;

  @override
  void initState() {
    super.initState();

    fabrics = [
      {
        "name": "Cotton",
        "price": widget.product.calculatedFinalPrice,
        "icon": Icons.checkroom,
      },
      {
        "name": "Silk",
        "price": widget.product.calculatedFinalPrice + 70,
        "icon": Icons.auto_awesome,
      },
      {
        "name": "Wool",
        "price": widget.product.calculatedFinalPrice + 50,
        "icon": Icons.ac_unit,
      },
      {
        "name": "Denim",
        "price": widget.product.calculatedFinalPrice + 30,
        "icon": Icons.work,
      },
      {
        "name": "Delicate",
        "price": widget.product.calculatedFinalPrice + 100,
        "icon": Icons.star,
      },
    ];
  }

  int get selectedPrice =>
      fabrics.firstWhere((f) => f["name"] == selectedFabric)["price"];

  int get total => selectedPrice * qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54, // overlay effect

      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            /// 🔹 BOTTOM POPUP
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // prevent closing
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      /// 🔹 HEADER
                      Row(
                        children: [
                          const Icon(Icons.local_laundry_service),
                          const SizedBox(width: 8),
                          const Text(
                            "Laundry Guide",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 SCROLL AREA (NO OVERFLOW)
                      Expanded(
                        child: ListView(
                          children: [
                            /// FABRIC LIST
                            ...fabrics.map((f) {
                              final isSelected = selectedFabric == f["name"];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFabric = f["name"];
                                  });
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      /// ICON
                                      Icon(
                                        f["icon"],
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.grey,
                                      ),

                                      const SizedBox(width: 10),

                                      /// NAME
                                      Expanded(
                                        child: Text(
                                          f["name"],
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      /// PRICE
                                      Text("₹${f["price"]}"),

                                      const SizedBox(width: 8),

                                      /// RADIO
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 10),

                            /// QTY
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Quantity"),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (qty > 1) {
                                          setState(() => qty--);
                                        }
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text(qty.toString()),
                                    IconButton(
                                      onPressed: () {
                                        setState(() => qty++);
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              "Prices may vary based on fabric condition & service type.",
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      /// 🔹 BOTTOM ACTION
                      SafeArea(
                        child: Column(
                          children: [
                            /// TOTAL
                            Text(
                              "Total: ₹$total",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.all(14),
                                ),
                                onPressed: () {
                                  /// ADD TO CART
                                  for (int i = 0; i < qty; i++) {
                                    Cart.add(
                                      CartItem(
                                        id: widget.product.id,
                                        name:
                                            "${widget.product.name} ($selectedFabric)",
                                        price: selectedPrice,
                                        service: widget.serviceName,
                                        category: widget.category,
                                      ),
                                      service: widget.serviceName,
                                    );
                                  }

                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingPage(
                                        serviceName: widget.serviceName,
                                        products: null, price: null,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Add & Continue",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
