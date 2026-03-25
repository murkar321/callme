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

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = salonCategories.first;
  }

  /// TOTAL ITEMS
  int get totalItems {
    int count = 0;
    final items = Cart.getItems("Salon");

    for (var item in items) {
      count += item.quantity;
    }

    return count;
  }

  /// TOTAL AMOUNT
  int get totalAmount => Cart.getTotal("Salon");

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    /// responsive category width
    double categoryWidth = 90;

    if (width < 600) {
      categoryWidth = 85;
    } else if (width < 1000) {
      categoryWidth = 95;
    } else {
      categoryWidth = 110;
    }

    /// responsive grid columns
    int gridCount = 2;

    if (width < 600) {
      gridCount = 1;
    } else if (width < 900) {
      gridCount = 2;
    } else if (width < 1200) {
      gridCount = 3;
    } else {
      gridCount = 4;
    }

    final items = salonServices
        .where((s) => s.category == selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// =========================
      /// APPBAR
      /// =========================

      appBar: AppBar(
        title: const Text("Salon Services"),
        backgroundColor: primaryColor,

        actions: [

          if (totalItems > 0)
            Stack(
              children: [

                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartPage(
                          serviceName: "Salon",
                          service: '',
                        ),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
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

      /// =========================
      /// BODY
      /// =========================

      body: Row(
        children: [

          /// =========================
          /// LEFT CATEGORY PANEL
          /// =========================

          Container(
            width: categoryWidth,
            color: Colors.white,

            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: salonCategories.length,

              itemBuilder: (context, index) {

                final category = salonCategories[index];
                final isSelected = category == selectedCategory;

                final firstItem = salonServices
                    .where((s) => s.category == category)
                    .toList();

                final image = firstItem.isNotEmpty
                    ? firstItem.first.image
                    : "assets/salon.png";

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },

                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(6),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.shade200,
                      ),
                    ),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(image),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          category,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade700,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// =========================
          /// RIGHT SERVICES PANEL
          /// =========================

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),

              itemCount: items.length,

              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: gridCount,

                childAspectRatio: width < 600
                    ? 3.2
                    : width < 1000
                        ? 3
                        : 2.8,

                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),

              itemBuilder: (context, index) {

                return SalonServiceCard(
                  service: items[index],
                );
              },
            ),
          ),
        ],
      ),

      /// =========================
      /// BOTTOM CART BAR
      /// =========================

      bottomNavigationBar: totalItems == 0
          ? null
          : SafeArea(
              child: InkWell(
                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(
                        serviceName: "Salon",
                        service: '',
                      ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },

                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "$totalItems items",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),

                      Text(
                        "₹$totalAmount View Cart →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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