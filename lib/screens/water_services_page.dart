import 'package:flutter/material.dart';
import '../data/water_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../screens/water_service_card.dart';

class WaterServicesPage extends StatefulWidget {
  const WaterServicesPage({super.key});

  @override
  State<WaterServicesPage> createState() =>
      _WaterServicesPageState();
}

class _WaterServicesPageState
    extends State<WaterServicesPage> {
  int selectedIndex = 0;

  List<String> get categories =>
      waterServices.keys.toList();

  void refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalItems =
        Cart.getTotalItems("Water");

    final totalPrice =
        Cart.totalPrice("Water");

    final selectedCategory =
        categories[selectedIndex];

    final selectedServices =
        waterServices[selectedCategory]!;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Water Services",
        ),
        backgroundColor:
            const Color(0xFFD8B8DD),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              /// =========================
              /// LEFT MENU (SAME AS PLUMBING)
              /// =========================
              Container(
                width: 110,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category =
                        categories[index];

                    final firstImage =
                        waterServices[category]!
                            .first
                            .imagePath;

                    final isSelected =
                        selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.all(8),
                        padding:
                            const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(
                                  0xFFF7EAF7)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color.fromARGB(
                                    255, 94, 175, 236)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  AssetImage(firstImage),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category,
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? const Color.fromARGB(
                                        255, 26, 128, 196)
                                    : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// =========================
              /// RIGHT LIST (SAME STRUCTURE)
              /// =========================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                    left: 10,
                    right: 10,
                    top: 10,
                  ),
                  itemCount:
                      selectedServices.length,
                  itemBuilder: (context, index) {
                    return WaterServiceCard(
                      product:
                          selectedServices[index],
                      onUpdate: refreshPage,
                    );
                  },
                ),
              ),
            ],
          ),

          /// =========================
          /// BOTTOM CART BAR (MATCHED)
          /// =========================
          if (totalItems > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    const BoxDecoration(
                  color: Colors.blue,
                  borderRadius:
                      BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            "$totalItems items",
                            style:
                                const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "₹$totalPrice",
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CartPage(
                                serviceName: "Water",
                                service: "Water",
                                cart: Cart.getItems(
                                    "Water"),
                              ),
                            ),
                          ).then(
                            (_) => refreshPage(),
                          );
                        },
                        child:
                            const Text("View Cart"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}