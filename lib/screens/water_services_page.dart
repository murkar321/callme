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
    List<ServiceProduct> services = waterServices[categories[selectedIndex]]!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// APP BAR (UNCHANGED)
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
                        service: null,
                      ),
                    ),
                  );
                },
              ),
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

      /// BODY
      body: Row(
        children: [
          /// LEFT CATEGORY (UNCHANGED LOGIC)
          Container(
            width: 90,
            color: Colors.grey.shade200,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected ? Colors.white : Colors.transparent,
                    child: Column(
                      children: [
                        const CircleAvatar(
                          backgroundImage:
                              AssetImage("assets/water services.png"),
                          radius: 25,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          categories[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.purple : Colors.grey,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT GRID (ONLY UI FIXED)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
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

      /// CART BAR (UNCHANGED LOGIC)
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
                      service: null,
                    ),
                  ),
                );
              },
              child: Container(
                height: 60,
                margin: const EdgeInsets.all(10),
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
