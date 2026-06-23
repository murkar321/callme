import 'package:flutter/material.dart';

import '../data/plumbing_data.dart';
import '../widgets/universal_card.dart';
import '../data/cleaning_data.dart';
import '../data/water_data.dart';
import '../data/service_product.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import 'universal_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNIVERSAL SERVICES PAGE  – Android-safe, adaptive layout
// ─────────────────────────────────────────────────────────────────────────────

class UniversalServicesPage extends StatefulWidget {
  final String serviceName;

  const UniversalServicesPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<UniversalServicesPage> createState() => _UniversalServicesPageState();
}

class _UniversalServicesPageState extends State<UniversalServicesPage> {
  int selectedIndex = 0;
  String search = '';

  void refresh() => setState(() {});

  Map<String, List<dynamic>> getData() {
    final Map<String, List<dynamic>> data = {};

    if (widget.serviceName == 'Cleaning') {
      cleaningServices.forEach((category, list) {
        final filtered = list
            .where((item) =>
                search.isEmpty ||
                item.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        if (filtered.isNotEmpty) data[category] = filtered;
      });
    } else if (widget.serviceName == 'Water') {
      waterServices.forEach((category, list) {
        final typedList = list.cast<ServiceProduct>();
        final filtered = typedList
            .where((item) =>
                search.isEmpty ||
                item.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        if (filtered.isNotEmpty) data[category] = filtered;
      });
    } else if (widget.serviceName == 'Plumbing') {
      final plumbing = serviceProducts['Plumbing'] ?? {};
      plumbing.forEach((category, list) {
        final typedList = list.cast<ServiceProduct>();
        final filtered = typedList
            .where((item) =>
                search.isEmpty ||
                item.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        if (filtered.isNotEmpty) data[category] = filtered;
      });
    }

    return data;
  }

  Color getColor() {
    switch (widget.serviceName) {
      case 'Water':
        return Colors.blue;
      case 'Cleaning':
        return Colors.teal;
      case 'Plumbing':
        return const Color(0xFFAE91BA);
      default:
        return Colors.grey;
    }
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final data = getData();
    final categories = data.keys.toList();

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.serviceName)),
        body: const Center(child: Text('No services found')),
      );
    }

    if (selectedIndex >= categories.length) selectedIndex = 0;

    final selectedCategory = categories[selectedIndex];
    final items = data[selectedCategory]!;
    final color = getColor();
    final totalItems = Cart.getTotalItems(widget.serviceName);
    final totalPrice = Cart.getTotal(widget.serviceName);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: color,
        title: Text(widget.serviceName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: totalItems > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartPage(
                            service: widget.serviceName,
                            serviceName: widget.serviceName,
                            cart: Cart.getItems(widget.serviceName),
                            providerId: '',
                          ),
                        ),
                      ).then((_) => refresh());
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 26),
                  if (totalItems > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          totalItems > 99 ? '99+' : '$totalItems',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() {
                search = v;
                selectedIndex = 0;
              }),
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // ── Left: category rail ──────────────────────────────────
                Container(
                  width: 90,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final category = categories[i];
                      final selected = i == selectedIndex;
                      final firstItem = data[category]!.first;
                      final image = widget.serviceName == 'Cleaning'
                          ? firstItem.image
                          : (firstItem.imagePath ?? 'assets/images/default.png');

                      return GestureDetector(
                        onTap: () => setState(() => selectedIndex = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor:
                                    selected ? color : Colors.grey.shade200,
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: AssetImage(image),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? color : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Right: items list ────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        4, 6, 4, totalItems > 0 ? 68 + bottomPad + 10 : 10),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];

                      final String image;
                      final String title;
                      final String desc;
                      final int price;
                      final double? rating;

                      if (widget.serviceName == 'Cleaning') {
                        image = item.image;
                        title = item.name;
                        desc = item.description;
                        price = item.finalPrice;
                        rating = null;
                      } else {
                        image = item.imagePath ?? 'assets/images/default.png';
                        title = item.name;
                        desc = item.description ?? '';
                        price = item.calculatedFinalPrice;
                        rating = item.safeRating;
                      }

                      return UniversalServiceCard(
                        image: image,
                        title: title,
                        description: desc,
                        price: price,
                        rating: rating,
                        primaryColor: color,
                        actionType: widget.serviceName == 'Water'
                            ? ServiceActionType.quantity
                            : ServiceActionType.normal,
                        quantity: widget.serviceName == 'Water'
                            ? Cart.getQuantity(item.id, 'Water')
                            : 0,
                        onView: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UniversalDetailPage(
                              data: item,
                              serviceName: widget.serviceName,
                            ),
                          ),
                        ).then((_) => refresh()),
                        onPrimaryAction: () {
                          if (widget.serviceName == 'Cleaning') {
                            Cart.addProduct(
                              ServiceProduct(
                                id: '${item.name}_cleaning',
                                service: 'Cleaning',
                                name: item.name,
                                price: item.price,
                                imagePath: item.image,
                                description: item.description,
                                finalPrice: item.finalPrice,
                              ),
                              'Cleaning',
                            );
                          } else {
                            Cart.addProduct(item, widget.serviceName);
                          }
                          refresh();
                        },
                        onIncrease: () {
                          Cart.addProduct(item, 'Water');
                          refresh();
                        },
                        onDecrease: () {
                          Cart.removeById(item.id, 'Water');
                          refresh();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom cart bar — SafeArea handles the nav bar ─────────────────
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$totalItems item${totalItems == 1 ? '' : 's'} • ₹$totalPrice',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service: widget.serviceName,
                                serviceName: widget.serviceName,
                                cart: Cart.getItems(widget.serviceName),
                                providerId: '',
                              ),
                            ),
                          ).then((_) => refresh());
                        },
                        child: const Text('View Cart',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}