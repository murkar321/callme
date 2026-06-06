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

  const UniversalServicesPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<UniversalServicesPage> createState() =>
      _UniversalServicesPageState();
}

class _UniversalServicesPageState
    extends State<UniversalServicesPage> {

  int selectedIndex = 0;
  String search = "";

  void refresh() => setState(() {});

  Map<String, List<dynamic>> getData() {

    Map<String, List<dynamic>> data = {};

    if (widget.serviceName == "Cleaning") {

      cleaningServices.forEach((category, list) {

        final filtered = list.where((item) {

          return search.isEmpty ||
              item.name
                  .toLowerCase()
                  .contains(search.toLowerCase());

        }).toList();

        if (filtered.isNotEmpty) {
          data[category] = filtered;
        }
      });
    }

    else if (widget.serviceName == "Water") {

      waterServices.forEach((category, list) {

        final typedList = list.cast<ServiceProduct>();

        final filtered = typedList.where((item) {

          return search.isEmpty ||
              item.name
                  .toLowerCase()
                  .contains(search.toLowerCase());

        }).toList();

        if (filtered.isNotEmpty) {
          data[category] = filtered;
        }
      });
    }

    else if (widget.serviceName == "Plumbing") {

      final plumbing = serviceProducts["Plumbing"] ?? {};

      plumbing.forEach((category, list) {

        final typedList = list.cast<ServiceProduct>();

        final filtered = typedList.where((item) {

          return search.isEmpty ||
              item.name
                  .toLowerCase()
                  .contains(search.toLowerCase());

        }).toList();

        if (filtered.isNotEmpty) {
          data[category] = filtered;
        }
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
        appBar: AppBar(
          title: Text(widget.serviceName),
        ),
        body: const Center(
          child: Text("No services found"),
        ),
      );
    }

    if (selectedIndex >= categories.length) {
      selectedIndex = 0;
    }

    final selectedCategory = categories[selectedIndex];

    final items = data[selectedCategory]!;

    final color = getColor();

    final totalItems =
        Cart.getTotalItems(widget.serviceName);

    final totalPrice =
        Cart.getTotal(widget.serviceName);

    return Scaffold(

      backgroundColor: const Color(0xFFF8F5F8),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: color,
        title: Text(
          widget.serviceName,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          /// 🛒 CART BADGE — top-right of AppBar
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
                            cart: Cart.getItems(
                              widget.serviceName,
                            ), providerId: '',
                          ),
                        ),
                      ).then((_) => refresh());
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  if (totalItems > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: AnimatedScale(
                        scale: totalItems > 0 ? 1.0 : 0.0,
                        duration:
                            const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            totalItems > 99
                                ? "99+"
                                : "$totalItems",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
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

                /// LEFT PANEL
                Container(
                  width: 95,
                  color: Colors.white.withOpacity(0.4),
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (_, i) {

                      final category = categories[i];

                      final selected =
                          i == selectedIndex;

                      final firstItem =
                          data[category]!.first;

                      String image = "";

                      if (widget.serviceName ==
                          "Cleaning") {

                        image = firstItem.image;
                      }

                      else {

                        image =
                            firstItem.imagePath ??
                                "assets/images/default.png";
                      }

                      return InkWell(

                        onTap: () {

                          setState(() {
                            selectedIndex = i;
                          });
                        },

                        child: Container(

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),

                          color: selected
                              ? color.withOpacity(0.08)
                              : Colors.transparent,

                          child: Column(
                            children: [

                              CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    AssetImage(image),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                category,
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// RIGHT PANEL
                Expanded(
                  child: ListView.builder(

                    padding:
                        EdgeInsets.fromLTRB(
                      6,
                      8,
                      6,
                      // Add extra bottom padding when cart bar is visible
                      totalItems > 0 ? 110 : 20,
                    ),

                    itemCount: items.length,

                    itemBuilder: (_, i) {

                      final item = items[i];

                      String image;
                      String title;
                      String desc;
                      int price;
                      double? rating;

                      if (widget.serviceName ==
                          "Cleaning") {

                        image = item.image;
                        title = item.name;
                        desc = item.description;
                        price = item.finalPrice;
                      }

                      else {

                        image =
                            item.imagePath ??
                                "assets/images/default.png";

                        title = item.name;

                        desc =
                            item.description ?? "";

                        price =
                            item.calculatedFinalPrice;

                        rating = item.safeRating;
                      }

                      return UniversalServiceCard(

                        image: image,
                        title: title,
                        description: desc,
                        price: price,
                        rating: rating,
                        primaryColor: color,

                        actionType:
                            widget.serviceName ==
                                    "Water"
                                ? ServiceActionType
                                    .quantity
                                : ServiceActionType
                                    .normal,

                        quantity:
                            widget.serviceName ==
                                    "Water"
                                ? Cart.getQuantity(
                                    item.id,
                                    "Water",
                                  )
                                : 0,

                        onView: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UniversalDetailPage(
                                data: item,
                                serviceName:
                                    widget.serviceName,
                              ),
                            ),
                          );
                        },

                        onPrimaryAction: () {

                          if (widget.serviceName ==
                              "Cleaning") {

                            final product =
                                ServiceProduct(
                              id:
                                  "${item.name}_cleaning",

                              service: "Cleaning",

                              name: item.name,

                              price: item.price,

                              imagePath:
                                  item.image,

                              description:
                                  item.description,

                              finalPrice:
                                  item.finalPrice,
                            );

                            Cart.addProduct(
                              product,
                              "Cleaning",
                            );
                          }

                          else {

                            Cart.addProduct(
                              item,
                              widget.serviceName,
                            );
                          }

                          refresh();
                        },

                        onIncrease: () {

                          Cart.addProduct(
                            item,
                            "Water",
                          );

                          refresh();
                        },

                        onDecrease: () {

                          Cart.removeById(
                            item.id,
                            "Water",
                          );

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

      /// 🔥 FIXED CART BAR — disappears instantly when cart is empty
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: Text(
                        "$totalItems item${totalItems == 1 ? '' : 's'} • ₹$totalPrice",
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      height: 42,
                      child: ElevatedButton(

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white,
                          foregroundColor: color,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(30),
                          ),
                        ),

                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service:
                                    widget.serviceName,

                                serviceName:
                                    widget.serviceName,

                                cart: Cart.getItems(
                                  widget.serviceName,
                                ), providerId: '',
                              ),
                            ),
                          ).then((_) => refresh());
                        },

                        child:
                            const Text("View Cart"),
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