import 'package:flutter/material.dart';

import '../data/plumbing_data.dart';
import '../widgets/universal_card.dart';
import '../data/cleaning_data.dart';
import '../data/water_data.dart';
import '../data/service_product.dart';

import '../models/cart.dart';
import '../models/cart_page.dart';

import 'universal_detail_page.dart';

class UniversalServicesPage extends StatefulWidget {
  final String serviceName;

  const UniversalServicesPage({super.key, required this.serviceName});

  @override
  State<UniversalServicesPage> createState() =>
      _UniversalServicesPageState();
}

class _UniversalServicesPageState extends State<UniversalServicesPage> {
  int selectedIndex = 0;
  String search = "";

  void refresh() => setState(() {});

  /// 🔥 DATA ENGINE (ALL SERVICES FIXED)
  Map<String, List<dynamic>> getData() {
    Map<String, List<dynamic>> data = {};

    /// 🟢 CLEANING
    if (widget.serviceName == "Cleaning") {
      cleaningServices.forEach((category, list) {
        final filtered = list.where((item) {
          return search.isEmpty ||
              item.name.toLowerCase().contains(search.toLowerCase());
        }).toList();

        if (filtered.isNotEmpty) data[category] = filtered;
      });
    }

    /// 🔵 WATER
    else if (widget.serviceName == "Water") {
      waterServices.forEach((category, list) {
        final typedList = list.cast<ServiceProduct>();

        final filtered = typedList.where((item) {
          return search.isEmpty ||
              item.name.toLowerCase().contains(search.toLowerCase());
        }).toList();

        if (filtered.isNotEmpty) data[category] = filtered;
      });
    }

    /// 🟣 PLUMBING
    else if (widget.serviceName == "Plumbing") {
      final plumbing = serviceProducts["Plumbing"] ?? {};

      plumbing.forEach((category, list) {
        final typedList = list.cast<ServiceProduct>();

        final filtered = typedList.where((item) {
          return search.isEmpty ||
              item.name.toLowerCase().contains(search.toLowerCase());
        }).toList();

        if (filtered.isNotEmpty) data[category] = filtered;
      });
    }

    return data;
  }

  Color getColor() {
    switch (widget.serviceName) {
      case "Water":
        return Colors.blue;
      case "Cleaning":
        return Colors.teal;
      case "Plumbing":
        return const Color(0xFFAE91BA);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = getData();
    final categories = data.keys.toList();

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.serviceName)),
        body: const Center(child: Text("No services found")),
      );
    }

    if (selectedIndex >= categories.length) selectedIndex = 0;

    final selectedCategory = categories[selectedIndex];
    final items = data[selectedCategory]!;

    final color = getColor();

    final totalItems = Cart.getTotalItems(widget.serviceName);
    final totalPrice = Cart.getTotal(widget.serviceName);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: color,
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() {
                  search = v;
                  selectedIndex = 0;
                });
              },
            ),
          ),

          Expanded(
            child: Row(
              children: [

                /// 📂 LEFT PANEL
                SizedBox(
                  width: 95,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final category = categories[i];
                      final selected = i == selectedIndex;

                      final firstItem = data[category]!.first;

                      String image = "";

                      if (widget.serviceName == "Cleaning") {
                        image = firstItem.image;
                      } else {
                        image = firstItem.imagePath ??
                            "assets/images/default.png";
                      }

                      return InkWell(
                        onTap: () => setState(() => selectedIndex = i),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: selected ? color.withOpacity(0.1) : null,
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: AssetImage(image),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
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

                /// 📄 RIGHT PANEL
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];

                      String image;
                      String title;
                      String desc;
                      int price;
                      double? rating;

                      /// 🟢 CLEANING
                      if (widget.serviceName == "Cleaning") {
                        image = item.image;
                        title = item.name;
                        desc = item.description;
                        price = item.finalPrice;
                      }

                      /// 🔵 WATER + 🟣 PLUMBING
                      else {
                        image = item.imagePath ??
                            "assets/images/default.png";
                        title = item.name;
                        desc = item.description ?? "";
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

                        /// ONLY WATER HAS QUANTITY
                        actionType: widget.serviceName == "Water"
                            ? ServiceActionType.quantity
                            : ServiceActionType.normal,

                        quantity: widget.serviceName == "Water"
                            ? Cart.getQuantity(item.id, "Water")
                            : 0,

                        onView: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UniversalDetailPage(
                                data: item,
                                serviceName: widget.serviceName,
                              ),
                            ),
                          );
                        },

                        /// 🔥 FIXED ADD LOGIC
                        onPrimaryAction: () {

                          /// 🟢 CLEANING → CONVERT
                          if (widget.serviceName == "Cleaning") {
                            final product = ServiceProduct(
                              id: "${item.name}_cleaning",
                              service: "Cleaning",
                              name: item.name,
                              price: item.price,
                              imagePath: item.image,
                              description: item.description,
                              finalPrice: item.finalPrice,
                            );

                            Cart.addProduct(product, "Cleaning");
                          }

                          /// 🔵 WATER + 🟣 PLUMBING
                          else {
                            Cart.addProduct(item, widget.serviceName);
                          }

                          refresh();

                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${item.name} added")),
                          );
                        },

                        onIncrease: () {
                          Cart.addProduct(item, "Water");
                          refresh();
                        },

                        onDecrease: () {
                          Cart.removeById(item.id, "Water");
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

      /// 🛒 CART BAR
      bottomNavigationBar: totalItems > 0
          ? Container(
              padding: const EdgeInsets.all(12),
              color: color,
              child: Row(
                children: [
                  Text(
                    "$totalItems items • ₹$totalPrice",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartPage(
                            service: widget.serviceName,
                            serviceName: widget.serviceName,
                            cart: Cart.getItems(widget.serviceName),
                          ),
                        ),
                      );
                    },
                    child: const Text("View Cart"),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}