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

  /// TYPE CHECK
  bool get isCleaning => data is CleaningService;
  bool get isWater => serviceName == "Water";

  /// COLOR
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

  /// SAFE DATA GETTERS
  String get image =>
      isCleaning ? data.image : data.imagePath;

  int get price =>
      isCleaning ? data.price : data.originalPrice;

  int get finalPrice =>
      isCleaning ? data.finalPrice : data.calculatedFinalPrice;

  int get discount =>
      isCleaning ? data.discount : (data.discount ?? 0);

  double get rating =>
      isCleaning ? 4.5 : data.safeRating;

  String get time =>
      isCleaning ? data.time : data.serviceTime;

  String get description =>
      isCleaning ? data.description : (data.description ?? "");

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
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(data.name),
        backgroundColor: color,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 IMAGE
            Stack(
              children: [
                Image.asset(
                  image,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                /// DISCOUNT BADGE
                if (discount > 0)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$discount% OFF",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ⭐ RATING + TIME
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange),
                      Text(rating.toString()),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16),
                      Text(time),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// 💰 PRICE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          "₹$finalPrice",
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        if (discount > 0)
                          Text(
                            "₹$price",
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// 📄 DESCRIPTION
                  _section("About", description),

                  /// 📦 INCLUDES
                  if (includes.isNotEmpty)
                    _listSection("Includes", includes),

                  /// ❌ EXCLUDES
                  if (excludes.isNotEmpty)
                    _listSection("Excludes", excludes),

                  /// 🔄 PROCESS (ServiceProduct)
                  if (process.isNotEmpty)
                    _listSection("Process", process),

                  /// 🪜 STEPS
                  if (steps.isNotEmpty)
                    _listSection("Steps", steps),

                  /// 🧰 TOOLS
                  if (tools.isNotEmpty)
                    _section("Tools Required", tools),

                  /// 🛡 WARRANTY (Cleaning)
                  if (warranty.isNotEmpty)
                    _section("Warranty / Support", warranty),
                ],
              ),
            ),
          ],
        ),
      ),

      /// 🔻 CTA
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleAction(context),
            child: Text(
              isWater ? "Book Now" : "Add to Cart",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 ACTION
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

      Cart.addProduct(product, "Cleaning");
    } else {
      Cart.addProduct(data, serviceName);
    }

    if (isWater) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPage(
            products: Cart.getItems("Water"),
            serviceName: "Water",
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CartPage(
            service: serviceName,
            serviceName: serviceName,
            cart: Cart.getItems(serviceName),
          ),
        ),
      );
    }
  }

  /// UI HELPERS
  Widget _section(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _listSection(String title, List<String> items) {
    return _section(
      title,
      items.map((e) => "• $e").join("\n"),
    );
  }
}