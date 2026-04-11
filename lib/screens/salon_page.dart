import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../models/salon_service_card.dart';

class SalonPage extends StatefulWidget {
  const SalonPage({super.key});

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  final Color primaryColor = const Color(0xFFAE91BA);

  int selectedIndex = 0;

  void refresh() => setState(() {});

  /// TOTAL ITEMS (ONLY SALON)
  int get totalItems {
    final items = Cart.getItems("Salon");
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// TOTAL PRICE (ONLY SALON)
  int get totalAmount => Cart.getTotal("Salon");

  @override
  Widget build(BuildContext context) {
    final categories = salonCategories;
    final selectedCategory = categories[selectedIndex];

    final services = salonServices
        .where((s) => s.category == selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// ================= APPBAR =================
      appBar: AppBar(
        title: const Text("Salon Services"),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          if (totalItems > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartPage(
                          service: "Salon",
                          serviceName: "Salon", cart: [],
                        ),
                      ),
                    );
                    refresh();
                  },
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
              ],
            )
        ],
      ),

      /// ================= BODY =================
      body: SafeArea(
        child: Row(
          children: [

            /// LEFT CATEGORY
            Container(
              width: 95,
              color: Colors.grey.shade100,
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedIndex == index;

                  final firstItem = salonServices
                      .where((s) => s.category == category)
                      .toList();

                  final image = firstItem.isNotEmpty
                      ? firstItem.first.image
                      : "assets/salon.png";

                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedIndex = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? primaryColor : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(image),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color:
                                  isSelected ? primaryColor : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// RIGHT SERVICES
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  totalItems > 0 ? 90 : 12,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return SalonServiceCard(
                    service: services[index],
                    onUpdate: refresh,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// ================= BOTTOM CART =================
      bottomNavigationBar: totalItems == 0
          ? null
          : SafeArea(
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(
                        service: "Salon",
                        serviceName: "Salon", cart: [],
                      ),
                    ),
                  );
                  refresh();
                },
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$totalItems items",
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        "₹$totalAmount  View Cart →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}