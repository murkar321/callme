import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import '../data/service_product.dart';
import '../models/cart.dart';
import '../widgets/civil_card.dart';
import '../widgets/renovation_bottom_sheet.dart';
import '../models/civil_detail_page.dart';
import '../models/cart_page.dart';

class CivilServicesPage extends StatefulWidget {
  const CivilServicesPage({super.key});

  @override
  State<CivilServicesPage> createState() => _CivilServicesPageState();
}

class _CivilServicesPageState extends State<CivilServicesPage> {
  int selectedIndex = 0;

  void refresh() => setState(() {});

  /// Extract numeric price from a price string like "₹500/sqft"
  int extractPrice(String price) {
    final numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;
    return int.tryParse(numbers) ?? 0;
  }

  /// Convert SubService → ServiceProduct
  ServiceProduct convert(SubService sub, String category) {
    return ServiceProduct(
      id: sub.id,
      name: sub.name,
      price: extractPrice(sub.price),
      imagePath: sub.image,
      category: category,
      rating: sub.rating,
      discount: sub.discount,
      service: "Civil Contract Services",
    );
  }

  /// Add item to cart
  void addToCart(ServiceProduct service) {
    Cart.add(
      CartItem(
        id: "civil_${service.id}",
        name: service.name,
        price: service.price,
        service: "Civil Contract Services",
        category: service.category ?? "",
        image: service.imagePath,
      ),
      service: "Civil Contract Services",
    );

    refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${service.name} added to cart"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle booking tap: Renovation → bottom sheet, Others → add to cart
  void handleBooking(ServiceProduct service) {
    if (service.category == "Renovation") {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => RenovationBottomSheet(
          packageId: service.id,
          packageName: service.name,
        ),
      );
    } else {
      addToCart(service);
    }
  }

  /// Open detail page
  void openDetails(SubService sub, String mainId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CivilServiceDetailPage(
          service: sub,
          mainServiceId: mainId,
        ),
      ),
    ).then((_) => refresh());
  }

  /// Navigate to cart
  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartPage(
          serviceName: "Civil Contract Services",
          providerId: '',
          service: '',
        ),
      ),
    ).then((_) => refresh());
  }

  @override
  Widget build(BuildContext context) {
    final categories = civilServices;
    final selectedService = categories[selectedIndex];
    final subServices = selectedService.subServices;

    final totalItems = Cart.getTotalItems("Civil Contract Services");
    final totalPrice = Cart.getTotal("Civil Contract Services");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Civil Contract Services"),
        centerTitle: true,
        actions: [
          /// CART ICON in AppBar with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: totalItems > 0 ? openCart : null,
              ),
              if (totalItems > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      totalItems > 9 ? "9+" : "$totalItems",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            /// ── CHOOSE A SERVICE HEADER ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose a Service",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Select a category from the left to browse services",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            /// ── MAIN CONTENT ─────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  /// LEFT CATEGORY PANEL
                  Container(
                    width: 95,
                    color: Colors.grey.shade100,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: AssetImage(category.image),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  child: Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
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
                      padding: EdgeInsets.fromLTRB(
                        10,
                        10,
                        10,
                        totalItems > 0 ? 90 : 10,
                      ),
                      itemCount: subServices.length,
                      itemBuilder: (context, index) {
                        final sub = subServices[index];
                        final service = convert(sub, selectedService.name);

                        return CivilServiceCard(
                          service: service,
                          displayPrice: sub.price,
                          onAddCart: () => handleBooking(service),
                          onTap: () => openDetails(sub, selectedService.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// ── VIEW CART BAR ─────────────────────────────────────────
            if (totalItems > 0)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.black,
                child: Row(
                  children: [
                    /// Item count + price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$totalItems item${totalItems > 1 ? 's' : ''} added",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "₹$totalPrice",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    /// VIEW CART button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: openCart,
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text(
                        "View Cart",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}