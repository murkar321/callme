import 'package:flutter/material.dart';
import '../models/service_product_details.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../widgets/plumbing_service_card.dart';

class PlumbingServicesPage extends StatefulWidget {
  const PlumbingServicesPage({super.key, required String serviceName});

  @override
  State<PlumbingServicesPage> createState() =>
      _PlumbingServicesPageState();
}

class _PlumbingServicesPageState
    extends State<PlumbingServicesPage> {
  int selectedIndex = 0;

  List<String> get categories =>
      serviceProducts["Plumbing"]!.keys.toList();

  void refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalItems =
        Cart.getTotalItems("Plumbing");

    final totalPrice =
        Cart.totalPrice("Plumbing");

    final selectedCategory =
        categories[selectedIndex];

    final selectedServices =
        serviceProducts["Plumbing"]![
            selectedCategory]!;

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Plumbing Services",
        ),
        backgroundColor:
            const Color(0xFFD8B8DD),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              /// LEFT MENU
              Container(
                width: 110,
                color: Colors.white,
                child: ListView.builder(
                  itemCount:
                      categories.length,
                  itemBuilder:
                      (context, index) {
                    final category =
                        categories[index];

                    final firstImage =
                        serviceProducts[
                                "Plumbing"]![
                            category]!
                            .first
                            .imagePath;

                    final isSelected =
                        selectedIndex ==
                            index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex =
                              index;
                        });
                      },
                      child: Container(
                        margin:
                            const EdgeInsets
                                .all(8),
                        padding:
                            const EdgeInsets
                                .all(8),
                        decoration:
                            BoxDecoration(
                          color: isSelected
                              ? const Color(
                                  0xFFF7EAF7)
                              : Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      18),
                          border:
                              Border.all(
                            color: isSelected
                                ? const Color.fromARGB(255, 94, 175, 236)
                                : Colors
                                    .grey
                                    .shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  AssetImage(
                                firstImage,
                              ),
                            ),
                            const SizedBox(
                                height: 8),
                            Text(
                              category,
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                fontSize:
                                    13,
                                color: isSelected
                                    ? const Color.fromARGB(255, 26, 128, 196)
                                    : Colors
                                        .black,
                                fontWeight:
                                    isSelected
                                        ? FontWeight
                                            .bold
                                        : FontWeight
                                            .normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// RIGHT LIST
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 100,
                    left: 10,
                    right: 10,
                    top: 10,
                  ),
                  itemCount:
                      selectedServices
                          .length,
                  itemBuilder:
                      (context, index) {
                    final product =
                        selectedServices[
                            index];

                    return PlumbingServiceCard(
                      product: product,
                      serviceName:
                          "Plumbing",
                      primaryColor:
                          const Color(
                              0xFFD8B8DD),
                      onAdd: () {
                        Cart.add(
                          CartItem(
                            id: product.id,
                            name:
                                product.name,
                            price: product
                                .calculatedFinalPrice,
                            service:
                                "Plumbing",
                            category:
                                selectedCategory,
                            image: product
                                .imagePath,
                          ),
                          service:
                              "Plumbing",
                        );

                        refreshPage();
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          /// BOTTOM CART BAR
          if (totalItems > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets
                        .all(12),
                decoration:
                    const BoxDecoration(
                  color: Colors.blue,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(
                            20),
                    topRight:
                        Radius.circular(
                            20),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            "$totalItems items",
                            style:
                                const TextStyle(
                              color: Colors
                                  .white,
                            ),
                          ),
                          Text(
                            "₹$totalPrice",
                            style:
                                const TextStyle(
                              color: Colors
                                  .white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CartPage(
                                serviceName:
                                    "Plumbing",
                                service:
                                    "Plumbing",
                                cart: Cart
                                    .getItems(
                                        "Plumbing"),
                              ),
                            ),
                          ).then(
                            (_) =>
                                refreshPage(),
                          );
                        },
                        child:
                            const Text(
                          "View Cart",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}