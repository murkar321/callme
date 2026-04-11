import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import '../data/cleaning_data.dart';
import '../models/cart.dart';
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
      Cart.getTotalItems(
          widget.serviceName);

  int get totalAmount =>
      Cart.getTotal(
          widget.serviceName);

  @override
  Widget build(BuildContext context) {
    final categories =
        cleaningServices.keys.toList();

    final products =
        cleaningServices[
            selectedCategory]!;

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
                    Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CartPage(
                        service: widget
                            .serviceName,
                        serviceName: '',
                        cart: [],
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
                            height: 6),
                        Text(
                          category,
                          style:
                              TextStyle(
                            color: isSelected
                                ? primaryColor
                                : Colors
                                    .black87,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                  onAdd: () {
                    setState(() {
                      Cart.add(
                        CartItem(
                          id:
                              "${widget.serviceName}_${selectedCategory}_${product.name}",
                          name: product
                              .name,
                          price: product
                              .finalPrice,
                          service: widget
                              .serviceName,
                          category:
                              selectedCategory,
                          image: product
                              .image,
                        ),
                        service: widget
                            .serviceName,
                      );
                    });

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                            "${product.name} added to cart"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}