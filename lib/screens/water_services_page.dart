import 'package:flutter/material.dart';
import '../screens/booking_page.dart';
import '../screens/water_service_card.dart';
import '../data/water_data.dart';
import '../models/service_product.dart';
import '../models/cart.dart';

class WaterServicesPage extends StatefulWidget {
  const WaterServicesPage({super.key});

  @override
  State<WaterServicesPage> createState() => _WaterServicesPageState();
}

class _WaterServicesPageState extends State<WaterServicesPage> {
  int selectedIndex = 0;

  List<String> categories = waterServices.keys.toList();

  int get totalWaterItems => Cart.getTotalItems("Water");
  int get totalWaterPrice => Cart.totalPrice("Water");

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    /// 🔥 RESPONSIVE
    final isTablet = screenWidth > 600;
    final leftWidth = isTablet ? 110.0 : screenWidth * 0.22;
    final crossAxisCount = isTablet ? 3 : 2;

    List<ServiceProduct> services = waterServices[categories[selectedIndex]]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔹 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.purple.shade200,
        title: const Text("Water Services"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        products: Cart.getItems("Water"),
                        serviceName: "Water",
                        service: null, cart: [],
                      ),
                    ),
                  );
                },
              ),

              /// 🔴 CART BADGE
              if (totalWaterItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      totalWaterItems.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 10)
        ],
      ),

      /// 🔹 BODY
      body: Row(
        children: [
          /// 🔹 LEFT CATEGORY PANEL
          Container(
            width: leftWidth,
            color: Colors.grey.shade200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              AssetImage("assets/water services.png"),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            categories[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.purple : Colors.grey,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),

              /// 🔥 FINAL FIX (NO OVERFLOW)
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: isTablet ? 230 : 220,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),

              itemCount: services.length,

              itemBuilder: (context, index) {
                return WaterServiceCard(
                  product: services[index],
                  onUpdate: () => setState(() {}),
                );
              },
            ),
          ),
        ],
      ),

      /// 🔹 BOTTOM CART BAR
      bottomNavigationBar: totalWaterItems == 0
          ? null
          : GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      products: Cart.getItems("Water"),
                      serviceName: "Water",
                      service: null, cart: [],
                    ),
                  ),
                );
              },
              child: Container(
                height: 60,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 210, 166, 218),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "$totalWaterItems items   ₹$totalWaterPrice   View Cart →",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
