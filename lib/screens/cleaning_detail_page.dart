import 'package:flutter/material.dart';
import '../data/cleaning_data.dart';
import '../models/cart.dart';
import 'booking_page.dart';

class CleaningDetailPage extends StatefulWidget {
  final String serviceName;

  const CleaningDetailPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<CleaningDetailPage> createState() => _CleaningDetailPageState();
}

class _CleaningDetailPageState extends State<CleaningDetailPage> {

  late String selectedCategory;

  final Color primaryColor = const Color(0xFFAE91BA);

  @override
  void initState() {
    super.initState();

    /// first category
    selectedCategory = cleaningServices.keys.first;
  }

  /// total items
  int get totalItems {
    int count = 0;

    final items = Cart.getItems(widget.serviceName);

    for (var item in items) {
      count += Cart.getQuantity(item.id, widget.serviceName);
    }

    return count;
  }

  /// total amount
  int get totalAmount => Cart.getTotal(widget.serviceName);

  @override
  Widget build(BuildContext context) {

    final categories = cleaningServices.keys.toList();
    final products = cleaningServices[selectedCategory]!;

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// APPBAR
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: primaryColor,
        elevation: 0,

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
                        builder: (_) => BookingPage(
                          serviceName: widget.serviceName,
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

      /// BODY
      body: Row(
        children: [

          /// LEFT CATEGORY PANEL
          Container(
            width: width * 0.22,
            color: Colors.white,

            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {

                final category = categories[index];
                final isSelected = category == selectedCategory;

                final firstProduct =
                    cleaningServices[category]!.first;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },

                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(6),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage(firstProduct.image),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? primaryColor
                                : Colors.grey,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding:
                  const EdgeInsets.fromLTRB(10, 10, 10, 100),

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),

              itemCount: products.length,

              itemBuilder: (context, index) {

                final product = products[index];

                /// unique id
                final id =
                    "${widget.serviceName}_${selectedCategory}_$index";

                final qty =
                    Cart.getQuantity(id, widget.serviceName);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6)
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      /// IMAGE
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(
                                top: Radius.circular(16)),
                        child: Image.asset(
                          product.image,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      /// DETAILS
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(8),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              /// NAME
                              Text(
                                product.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              /// TIME
                              Text(
                                product.time,
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const Spacer(),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                children: [

                                  /// PRICE
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [

                                      Text(
                                        "₹${product.price}",
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration
                                                  .lineThrough,
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),

                                      Text(
                                        "₹${product.finalPrice}",
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  /// ADD REMOVE
                                  qty == 0
                                      ? ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              Cart.add(
                                                CartItem(
                                                  id: id,
                                                  name:
                                                      product.name,
                                                  price:
                                                      product.finalPrice,
                                                  service:
                                                      widget.serviceName,
                                                  category:
                                                      selectedCategory,
                                                  image:
                                                      product.image,
                                                ),
                                                service:
                                                    widget.serviceName,
                                              );
                                            });
                                          },

                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                                primaryColor,
                                          ),

                                          child:
                                              const Text(
                                                  "ADD"),
                                        )
                                      : Row(
                                          children: [

                                            IconButton(
                                              icon:
                                                  const Icon(
                                                      Icons.remove),
                                              onPressed:
                                                  () {
                                                setState(
                                                    () {
                                                  Cart.removeById(
                                                      id,
                                                      widget.serviceName);
                                                });
                                              },
                                            ),

                                            Text(
                                                qty.toString()),

                                            IconButton(
                                              icon:
                                                  const Icon(
                                                      Icons.add),
                                              onPressed:
                                                  () {
                                                setState(
                                                    () {
                                                  Cart.add(
                                                    CartItem(
                                                      id: id,
                                                      name:
                                                          product.name,
                                                      price:
                                                          product.finalPrice,
                                                      service:
                                                          widget.serviceName,
                                                      category:
                                                          selectedCategory,
                                                      image:
                                                          product.image,
                                                    ),
                                                    service:
                                                        widget.serviceName,
                                                  );
                                                });
                                              },
                                            )
                                          ],
                                        )
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),

      /// BOTTOM CART
      bottomNavigationBar: totalItems == 0
          ? null
          : InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      serviceName:
                          widget.serviceName,
                      products: null,
                    ),
                  ),
                );
              },

              child: Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      "$totalItems items",
                      style: const TextStyle(
                          color: Colors.white),
                    ),

                    Text(
                      "₹$totalAmount View Cart →",
                      style: const TextStyle(
                          color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}