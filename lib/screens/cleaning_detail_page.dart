import 'package:flutter/material.dart';
import 'package:callme/models/cart_page.dart';
import '../data/cleaning_data.dart';
import '../models/cart.dart';
import '../models/cleaning_service.dart';
import '../widgets/cleaning_service_card.dart';

class CleaningDetailPage extends StatefulWidget {
  final String serviceName;

  const CleaningDetailPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<CleaningDetailPage> createState() =>
      _CleaningDetailPageState();
}

class _CleaningDetailPageState
    extends State<CleaningDetailPage> {
  final Color primaryColor =
      const Color(0xFFAE91BA);

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory =
        cleaningServices.keys.first;
  }

  int get totalItems =>
      Cart.getTotalItems("Cleaning");

  int get totalAmount =>
      Cart.getTotal("Cleaning");

  /// ✅ CLEANING ONLY SAFE ADD
  void handleAddToCart(
      CleaningService product) {
    final alreadyExists =
        Cart.cleaningItems.any(
      (item) => item.id == product.name,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "${product.name} already added",
          ),
        ),
      );
      return;
    }

    setState(() {
      Cart.addCleaning(product);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "${product.name} added to cart",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        cleaningServices.keys.toList();

    final List<CleaningService>
        products =
        cleaningServices[
                selectedCategory] ??
            [];

    final screenWidth =
        MediaQuery.of(context)
            .size
            .width;

    return Scaffold(
      backgroundColor:
          const Color(0xffF6F7FB),
      appBar: AppBar(
        backgroundColor:
            primaryColor,
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.serviceName,
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CartPage(
                        service:
                            "Cleaning",
                        serviceName:
                            widget
                                .serviceName,
                        cart: Cart
                            .cleaningItems,
                      ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
              if (totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor:
                        Colors.red,
                    child: Text(
                      totalItems
                          .toString(),
                      style:
                          const TextStyle(
                        color: Colors
                            .white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: Row(
        children: [
          /// ✅ LEFT CATEGORY PANEL
          Container(
            width:
                screenWidth * 0.25,
            color: Colors.white,
            child: ListView.builder(
              itemCount:
                  categories.length,
              itemBuilder:
                  (context, index) {
                final category =
                    categories[index];

                final isSelected =
                    selectedCategory ==
                        category;

                final firstProduct =
                    cleaningServices[
                            category]!
                        .first;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory =
                          category;
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 55,
                          width: 55,
                          decoration:
                              BoxDecoration(
                            shape: BoxShape
                                .circle,
                            border:
                                Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors
                                      .grey
                                      .shade300,
                              width: 2,
                            ),
                            image:
                                DecorationImage(
                              image:
                                  AssetImage(
                                firstProduct
                                    .image,
                              ),
                              fit: BoxFit
                                  .cover,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          category,
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color: isSelected
                                ? primaryColor
                                : Colors
                                    .black87,
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight
                                        .bold
                                    : FontWeight
                                        .normal,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// ✅ RIGHT PRODUCT PANEL
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                12,
                12,
                12,
                100,
              ),
              itemCount:
                  products.length,
              itemBuilder:
                  (context, index) {
                final product =
                    products[index];

                return CleaningServiceCard(
                  service: product,
                  serviceName: widget
                      .serviceName,
                  category:
                      selectedCategory,
                  index: index,
                  onAdd: () =>
                      handleAddToCart(
                          product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}