import 'package:flutter/material.dart';
import '../data/cleaning_data.dart';
import '../models/cart.dart';
import '../widgets/cleaning_service_card.dart';
import 'booking_page.dart';

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

    /// first category auto selected
    selectedCategory =
        cleaningServices.keys.first;
  }

  /// total items
  int get totalItems {
    int count = 0;

    final items =
        Cart.getItems(widget.serviceName);

    for (var item in items) {
      count += Cart.getQuantity(
        item.id,
        widget.serviceName,
      );
    }

    return count;
  }

  /// total amount
  int get totalAmount =>
      Cart.getTotal(widget.serviceName);

  @override
  Widget build(BuildContext context) {

    final width =
        MediaQuery.of(context).size.width;

    final categories =
        cleaningServices.keys.toList();

    final products =
        cleaningServices[selectedCategory]!;

    return Scaffold(
      backgroundColor:
          const Color(0xffF5F6FA),

      /// APPBAR
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: primaryColor,
        elevation: 0,

        actions: [

          /// CART ICON
          if (totalItems > 0)
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
                            BookingPage(
                          serviceName:
                              widget.serviceName,
                          products: null,
                        ),
                      ),
                    );
                  },
                ),

                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor:
                        Colors.red,
                    child: Text(
                      totalItems.toString(),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            )
        ],
      ),

      /// BODY
      body: Row(
        children: [

          /// LEFT CATEGORY PANEL
          Container(
            width: width * 0.22,
            color: Colors.white,

            child: ListView.builder(
              itemCount:
                  categories.length,
              itemBuilder:
                  (context, index) {

                final category =
                    categories[index];

                final isSelected =
                    category ==
                        selectedCategory;

                final firstProduct =
                    cleaningServices[
                        category]!
                        .first;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategory =
                          category;
                    });
                  },

                  child: Container(
                    margin:
                        const EdgeInsets
                            .all(6),
                    padding:
                        const EdgeInsets
                            .all(6),

                    decoration:
                        BoxDecoration(
                      color: isSelected
                          ? primaryColor
                              .withOpacity(
                                  0.15)
                          : Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage(
                            firstProduct
                                .image,
                          ),
                        ),

                        const SizedBox(
                            height: 5),

                        Text(
                          category,
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected
                                    ? FontWeight
                                        .bold
                                    : FontWeight
                                        .normal,
                            color:
                                isSelected
                                    ? primaryColor
                                    : Colors
                                        .grey,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT SERVICES GRID
          Expanded(
            child: GridView.builder(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                          10, 10, 10, 100),

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),

              itemCount: products.length,

              itemBuilder:
                  (context, index) {

                final product =
                    products[index];

                final id =
                    "${widget.serviceName}_${selectedCategory}_$index";

                final qty =
                    Cart.getQuantity(
                  id,
                  widget.serviceName,
                );

                return CleaningServiceCard(
                  product: product,
                  serviceName:
                      widget.serviceName,
                  category:
                      selectedCategory,
                  id: id,
                  qty: qty,
                  primaryColor:
                      primaryColor,

                  onAdd: () {
                    setState(() {
                      Cart.add(
                        CartItem(
                          id: id,
                          name:
                              product.name,
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
                  },

                  onRemove: () {
                    setState(() {
                      Cart.removeById(
                        id,
                        widget.serviceName,
                      );
                    });
                  },
                );
              },
            ),
          )
        ],
      ),

      /// BOTTOM CART BAR
      bottomNavigationBar:
          totalItems == 0
              ? null
              : InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingPage(
                          serviceName:
                              widget
                                  .serviceName,
                          products:
                              null,
                        ),
                      ),
                    );
                  },

                  child: Container(
                    margin:
                        const EdgeInsets
                            .all(12),

                    padding:
                        const EdgeInsets
                            .all(14),

                    decoration:
                        BoxDecoration(
                      color:
                          primaryColor,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  16),
                    ),

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [

                        Text(
                          "$totalItems items",
                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white,
                          ),
                        ),

                        Text(
                          "₹$totalAmount View Cart →",
                          style:
                              const TextStyle(
                            color:
                                Colors
                                    .white,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
    );
  }
}