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

  List<String> get categories => waterServices.keys.toList();

  void refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = Cart.getTotalItems("Water");
    final totalPrice = Cart.totalPrice("Water");

    final selectedCategory = categories[selectedIndex];
    final selectedServices = waterServices[selectedCategory]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Water Services"),
        backgroundColor: const Color(0xFFD8B8DD),
        centerTitle: true,
      ),

      body: Stack(
        children: [
          Row(
            children: [
              /// =========================
              /// LEFT CATEGORY MENU (UI IMPROVED ONLY)
              /// =========================
              Container(
                width: 105,
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    final firstImage =
                        waterServices[category]!.first.imagePath;

                    final isSelected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF3EAF4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            /// ICON CIRCLE
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(firstImage),
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// TEXT
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// =========================
              /// RIGHT SERVICE LIST (ADAPTIVE ONLY)
              /// =========================
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 120, // safe for cart bar
                    left: 10,
                    right: 10,
                    top: 10,
                  ),
                  itemCount: selectedServices.length,
                  itemBuilder: (context, index) {
                    return WaterServiceCard(
                      product: selectedServices[index],
                      onUpdate: refreshPage,
                    );
                  },
                ),
              ),
            ],
          ),

          /// =========================
          /// BOTTOM CART BAR (SAFE UI ONLY)
          /// =========================
          if (totalItems > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// LEFT INFO
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$totalItems items",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            "₹$totalPrice",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      /// BUTTON
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                serviceName: "Water",
                                service: "Water",
                                cart: Cart.getItems("Water"),
                              ),
                            ),
                          ).then((_) => refreshPage());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "View Cart",
                          style: TextStyle(color: Colors.blue),
                        ),
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