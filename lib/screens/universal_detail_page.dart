import 'package:callme/bookings/booking_page.dart';
import 'package:callme/data/service_product.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/cart_page.dart';
import '../data/cleaning_data.dart';

class UniversalDetailPage extends StatelessWidget {

  final dynamic data;
  final String serviceName;

  const UniversalDetailPage({
    super.key,
    required this.data,
    required this.serviceName,
  });

  /// ================= TYPE CHECK =================
  bool get isCleaning => data is CleaningService;

  bool get isWater => serviceName == "Water";

  /// ================= COLOR =================
  Color get color {

    switch (serviceName) {

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

  /// ================= SAFE GETTERS =================
  String get image =>
      isCleaning ? data.image : data.imagePath;

  int get price =>
      isCleaning ? data.price : data.originalPrice;

  int get finalPrice =>
      isCleaning
          ? data.finalPrice
          : data.calculatedFinalPrice;

  int get discount =>
      isCleaning
          ? data.discount
          : (data.discount ?? 0);

  double get rating =>
      isCleaning ? 4.5 : data.safeRating;

  String get time =>
      isCleaning ? data.time : data.serviceTime;

  String get description =>
      isCleaning
          ? data.description
          : (data.description ?? "");

  List<String> get includes =>
      isCleaning ? data.includes : data.safeIncludes;

  List<String> get excludes =>
      isCleaning ? data.excludes : data.safeExcludes;

  List<String> get steps =>
      isCleaning ? data.steps : data.safeSteps;

  List<String> get process =>
      isCleaning ? [] : data.safeProcess;

  String get tools =>
      isCleaning ? data.tools : (data.tools ?? "");

  String get warranty =>
      isCleaning ? data.warranty : "";

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F5F7),

      /// ================= APP BAR =================
      appBar: AppBar(

        elevation: 0,

        centerTitle: true,

        backgroundColor: color,

        title: Text(
          data.name,

          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(

        padding: const EdgeInsets.only(bottom: 110),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// ================= IMAGE =================
            Stack(
              children: [

                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey.shade200,

                  child: Image.asset(
                    image,

                    fit: BoxFit.cover,

                    errorBuilder:
                        (_, __, ___) {

                      return Icon(
                        Icons.image,
                        size: 70,
                        color: Colors.grey.shade400,
                      );
                    },
                  ),
                ),

                /// DARK OVERLAY
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.bottomCenter,

                        end: Alignment.topCenter,

                        colors: [
                          Colors.black
                              .withOpacity(0.6),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// DISCOUNT
                if (discount > 0)

                  Positioned(
                    top: 16,
                    right: 16,

                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius:
                            BorderRadius.circular(30),
                      ),

                      child: Text(
                        "$discount% OFF",

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                /// TITLE
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 20,

                  child: Text(
                    data.name,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            /// ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  /// ================= RATING + TIME =================
                  Container(

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),

                          blurRadius: 8,
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 22,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          rating.toString(),

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Icon(
                          Icons.access_time,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          time,

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// ================= PRICE =================
                  Container(

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),

                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        Text(
                          "₹$finalPrice",

                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 12),

                        if (discount > 0)

                          Text(
                            "₹$price",

                            style: TextStyle(
                              fontSize: 22,
                              color:
                                  Colors.grey.shade500,

                              decoration:
                                  TextDecoration
                                      .lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ABOUT
                  _section(
                    title: "About",
                    child: Text(
                      description,

                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),

                  /// INCLUDES
                  if (includes.isNotEmpty)

                    _listSection(
                      "Includes",
                      includes,
                    ),

                  /// EXCLUDES
                  if (excludes.isNotEmpty)

                    _listSection(
                      "Excludes",
                      excludes,
                    ),

                  /// PROCESS
                  if (process.isNotEmpty)

                    _listSection(
                      "Process",
                      process,
                    ),

                  /// STEPS
                  if (steps.isNotEmpty)

                    _listSection(
                      "Steps",
                      steps,
                    ),

                  /// TOOLS
                  if (tools.isNotEmpty)

                    _section(
                      title: "Tools Required",

                      child: Text(
                        tools,

                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),

                  /// WARRANTY
                  if (warranty.isNotEmpty)

                    _section(
                      title: "Warranty / Support",

                      child: Text(
                        warranty,

                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// ================= FIXED BOTTOM BUTTON =================
      bottomNavigationBar: SafeArea(

        child: Container(

          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08),

                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],

            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),

          child: SizedBox(

            height: 56,

            child: ElevatedButton(

              style: ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor: color,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
              ),

              onPressed: () =>
                  _handleAction(context),

              child: Text(

                isWater
                    ? "Book Now"
                    : "Add to Cart",

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= ACTION =================
  void _handleAction(BuildContext context) {

    if (isCleaning) {

      final product = ServiceProduct(

        id: "${data.name}_cleaning",

        service: "Cleaning",

        name: data.name,

        price: data.price,

        imagePath: data.image,

        description: data.description,

        finalPrice: data.finalPrice,
      );

      Cart.addProduct(
        product,
        "Cleaning",
      );
    }

    else {

      Cart.addProduct(
        data,
        serviceName,
      );
    }

    /// WATER
    if (isWater) {

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => BookingPage(
            products:
                Cart.getItems("Water"),

            serviceName: "Water", providerId: '',
          ),
        ),
      );
    }

    /// OTHERS
    else {

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => CartPage(
            service: serviceName,

            serviceName: serviceName,

            cart:
                Cart.getItems(serviceName), providerId: '',
          ),
        ),
      );
    }
  }

  /// ================= SECTION =================
  Widget _section({
    required String title,
    required Widget child,
  }) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),

            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  /// ================= LIST SECTION =================
  Widget _listSection(
    String title,
    List<String> items,
  ) {

    return _section(

      title: title,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: items.map((e) {

          return Padding(
            padding:
                const EdgeInsets.only(bottom: 10),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  "• ",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                Expanded(
                  child: Text(
                    e,

                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}