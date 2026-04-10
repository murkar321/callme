import 'package:callme/models/cart_page.dart';
import 'package:callme/screens/water_service_card.dart';
import 'package:flutter/material.dart';
import '../data/water_data.dart';
import '../models/cart.dart';


class WaterServicesPage extends StatefulWidget {
  const WaterServicesPage({super.key});

  @override
  State<WaterServicesPage> createState() =>
      _WaterServicesPageState();
}

class _WaterServicesPageState
    extends State<WaterServicesPage> {

  void refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final totalItems =
        Cart.getTotalItems("Water");

    final totalPrice =
        Cart.totalPrice("Water");

    return Scaffold(
      backgroundColor:
          Colors.grey.shade100,

      appBar: AppBar(
        title:
            const Text("Water Services"),
        backgroundColor:
            Colors.blue,
        centerTitle: true,
      ),

      body: Stack(
        children: [

          /// SERVICES LIST
          ListView(
            padding:
                const EdgeInsets.only(
              bottom: 100,
            ),
            children:
                waterServices.entries
                    .map((entry) {

              final category =
                  entry.key;

              final services =
                  entry.value;

              final firstImage =
                  services
                      .first
                      .imagePath;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  /// CATEGORY HEADER
                  Padding(
                    padding:
                        const EdgeInsets
                            .all(12),
                    child: Row(
                      children: [

                        /// CIRCLE IMAGE
                        CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              AssetImage(
                            firstImage,
                          ),
                        ),

                        const SizedBox(
                            width: 10),

                        /// CATEGORY NAME
                        Text(
                          category,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// SERVICES
                  ...services.map(
                    (service) =>
                        WaterServiceCard(
                      product: service,
                      onUpdate:
                          refreshPage,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          /// VIEW CART BAR
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

                      /// ITEMS & PRICE
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
                              fontSize:
                                  16,
                            ),
                          ),

                          Text(
                            "₹$totalPrice",
                            style:
                                const TextStyle(
                              color: Colors
                                  .white,
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),

                      /// VIEW CART BUTTON
                      ElevatedButton(
                        onPressed: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CartPage(
                                serviceName:
                                    "Water",
                                service:
                                    "Water",
                                cart: Cart
                                    .getItems(
                                        "Water"),
                              ),
                            ),
                          ).then(
                            (_) =>
                                refreshPage(),
                          );
                        },
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.white,
                        ),
                        child:
                            const Text(
                          "View Cart",
                          style:
                              TextStyle(
                            color: Colors
                                .blue,
                          ),
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