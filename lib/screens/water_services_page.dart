import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';

import '../screens/water_service_card.dart';
import '../data/water_data.dart';
import '../models/cart.dart';

class WaterServicesPage extends StatefulWidget {
  const WaterServicesPage({super.key});

  @override
  State<WaterServicesPage> createState() =>
      _WaterServicesPageState();
}

class _WaterServicesPageState extends State<WaterServicesPage> {
  int selectedIndex = 0;

  late List<String> categories;

  @override
  void initState() {
    super.initState();
    categories = waterServices.keys.toList();
  }

  int get totalItems => Cart.getTotalItems("Water");
  int get totalPrice => Cart.totalPrice("Water");

  @override
  Widget build(BuildContext context) {
    final services =
        waterServices[categories[selectedIndex]]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color.fromARGB(255, 222, 189, 228),
        title: const Text(
          "Water Services",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      /// BODY
      body: Row(
        children: [
          /// LEFT CATEGORY MENU
          Container(
            width: 100,
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final selected =
                    selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.purple.shade50
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? Colors.purple
                            : Colors.grey.shade300,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    Colors.grey.shade200,
                                blurRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              AssetImage(
                            "assets/water services.png",
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          categories[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: selected
                                ? Colors.purple
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT SERVICE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 14,
                  ),
                  height: 340,
                  child: WaterServiceCard(
                    product: services[index],
                    onUpdate: () {
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      /// BOTTOM VIEW CART BAR
      bottomNavigationBar: totalItems == 0
          ? null
          : Container(
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(
                    255,
                    222,
                    189,
                    228,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(
                        serviceName: "Water",
                        service: "Water",
                        cart: Cart.getItems(
                          "Water",
                        ),
                      ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                child: Text(
                  "$totalItems items   |   ₹$totalPrice   |   View Cart →",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
    );
  }
}