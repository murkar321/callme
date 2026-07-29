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
// UNIVERSAL SERVICES PAGE  – Android-safe, adaptive layout, theme-aware
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

  /// Converts a CleaningService into a ServiceProduct so Cart can handle it
  /// uniformly (needs an `id` and `imagePath` which CleaningService lacks).
  ServiceProduct _cleaningToProduct(CleaningService c) {
    return ServiceProduct(
      id: '${c.name}_cleaning',
      service: 'Cleaning',
      name: c.name,
      price: c.price,
      imagePath: c.image,         // CleaningService stores image path in `image`
      description: c.description,
      finalPrice: c.finalPrice,
    );
  }

  Map<String, List<dynamic>> getData() {
    final Map<String, List<dynamic>> result = {};

    if (widget.serviceName == 'Cleaning') {
      cleaningServices.forEach((category, list) {
        final filtered = list
            .where((item) =>
                search.isEmpty ||
                item.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        if (filtered.isNotEmpty) result[category] = filtered;
      });
    } else if (widget.serviceName == 'Water') {
      waterServices.forEach((category, list) {
        final typedList = list.cast<ServiceProduct>();
        final filtered = typedList
            .where((item) =>
                search.isEmpty ||
                item.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        if (filtered.isNotEmpty) result[category] = filtered;
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
        if (filtered.isNotEmpty) result[category] = filtered;
      });
    }

    return result;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subTextColor = onSurface.withOpacity(0.6);

    final data = getData();
    final categories = data.keys.toList();

    if (categories.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(title: Text(widget.serviceName)),
        body: Center(
          child: Text('No services found',
              style: TextStyle(color: subTextColor)),
        ),
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
      backgroundColor: scaffoldBg,
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
                      color: Colors.white, size: 24),
                  if (totalItems > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
            child: TextField(
              style: TextStyle(color: onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: subTextColor),
                prefixIcon: Icon(Icons.search, color: subTextColor),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  width: 82,
                  color: surfaceColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final category = categories[i];
                      final selected = i == selectedIndex;
                      final firstItem = data[category]!.first;

                      // ── FIX: CleaningService.image vs ServiceProduct.imagePath ──
                      final String image;
                      if (widget.serviceName == 'Cleaning') {
                        image = (firstItem as CleaningService).image;
                      } else {
                        image = (firstItem as ServiceProduct).imagePath;
                      }

                      return GestureDetector(
                        onTap: () => setState(() => selectedIndex = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: selected
                                    ? color
                                    : (isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey.shade200),
                                child: CircleAvatar(
                                  radius: 21,
                                  backgroundImage: AssetImage(image),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? color : subTextColor,
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
                        4, 5, 4, totalItems > 0 ? 62 + bottomPad + 8 : 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];

                      // ── FIX: extract fields safely per type ──────────────
                      final String image;
                      final String title;
                      final String desc;
                      final int price;
                      final double? rating;
                      final String itemId;

                      if (widget.serviceName == 'Cleaning') {
                        final c = item as CleaningService;
                        image  = c.image;
                        title  = c.name;
                        desc   = c.description;
                        price  = c.finalPrice;
                        rating = null;
                        itemId = '${c.name}_cleaning';
                      } else {
                        final p = item as ServiceProduct;
                        image  = p.imagePath;
                        title  = p.name;
                        desc   = p.description ?? '';
                        price  = p.calculatedFinalPrice;
                        rating = p.safeRating;
                        itemId = p.id;
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
                            ? Cart.getQuantity(itemId, 'Water')
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
                            // ── FIX: wrap CleaningService in ServiceProduct ──
                            Cart.addProduct(
                              _cleaningToProduct(item as CleaningService),
                              'Cleaning',
                            );
                          } else {
                            Cart.addProduct(item as ServiceProduct,
                                widget.serviceName);
                          }
                          refresh();
                        },
                        onIncrease: () {
                          Cart.addProduct(item as ServiceProduct, 'Water');
                          refresh();
                        },
                        onDecrease: () {
                          Cart.removeById(itemId, 'Water');
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

      // ── Bottom cart bar ─────────────────────────────────────────────────
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
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
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
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