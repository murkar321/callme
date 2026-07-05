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

  // ── TYPE CHECK ────────────────────────────────────────────────────────────
  bool get isCleaning => data is CleaningService;
  bool get isWater => serviceName == 'Water';

  // ── THEME COLOR ───────────────────────────────────────────────────────────
  Color get color {
    switch (serviceName) {
      case 'Water':    return Colors.blue;
      case 'Cleaning': return Colors.teal;
      case 'Plumbing': return const Color(0xFFAE91BA);
      default:         return Colors.grey;
    }
  }

  // ── SAFE GETTERS — all routed through CleaningService or ServiceProduct ───

  /// Image asset path
  String get image =>
      isCleaning ? (data as CleaningService).image
                 : ((data as ServiceProduct).imagePath);

  /// Original (pre-discount) price
  int get price =>
      isCleaning ? (data as CleaningService).price
                 : (data as ServiceProduct).originalPrice;

  /// Final price after discount
  int get finalPrice =>
      isCleaning ? (data as CleaningService).finalPrice
                 : (data as ServiceProduct).calculatedFinalPrice;

  /// Discount percentage (0 = no discount)
  int get discount =>
      isCleaning ? (data as CleaningService).discount
                 : ((data as ServiceProduct).discount ?? 0);

  /// Star rating
  double get rating =>
      isCleaning ? 4.5
                 : (data as ServiceProduct).safeRating;

  /// Service duration string
  String get time =>
      isCleaning ? (data as CleaningService).time
                 : (data as ServiceProduct).serviceTime;

  /// Description text
  String get description =>
      isCleaning ? (data as CleaningService).description
                 : ((data as ServiceProduct).description ?? '');

  /// What's included
  List<String> get includes =>
      isCleaning ? (data as CleaningService).includes
                 : (data as ServiceProduct).safeIncludes;



  /// Step-by-step list
  List<String> get steps =>
      isCleaning ? (data as CleaningService).steps
                 : (data as ServiceProduct).safeSteps;

  /// Process list (ServiceProduct only)
  List<String> get process =>
      isCleaning ? [] : (data as ServiceProduct).safeProcess;

  /// Tools required
  String get tools =>
      isCleaning ? (data as CleaningService).tools
                 : ((data as ServiceProduct).tools ?? '');

  /// Warranty / support info (CleaningService only)
  String get warranty =>
      isCleaning ? (data as CleaningService).warranty : '';

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      // ── APP BAR ───────────────────────────────────────────────────────────
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

      // ── BODY ──────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HERO IMAGE ────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image,
                      size: 70,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

                // Dark gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Discount badge
                if (discount > 0)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Title over image
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

            // ── CONTENT ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Rating + Time row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.access_time,
                            color: Colors.grey.shade700, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Price card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '₹$finalPrice',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (discount > 0)
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // About
                  if (description.isNotEmpty)
                    _section(
                      title: 'About',
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (includes.isNotEmpty) _listSection('Includes', includes),
                  if (process.isNotEmpty)  _listSection('Process',  process),
                  if (steps.isNotEmpty)    _listSection('Steps',    steps),

                  if (tools.isNotEmpty)
                    _section(
                      title: 'Tools Required',
                      child: Text(tools,
                          style: const TextStyle(fontSize: 15)),
                    ),

                  if (warranty.isNotEmpty)
                    _section(
                      title: 'Warranty / Support',
                      child: Text(warranty,
                          style: const TextStyle(fontSize: 15)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── FIXED BOTTOM BUTTON ───────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () => _handleAction(context),
              child: Text(
                isWater ? 'Book Now' : 'Add to Cart',
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

  // ── ACTION HANDLER ────────────────────────────────────────────────────────
  void _handleAction(BuildContext context) {
    if (isCleaning) {
      // ── FIX: cast to CleaningService before reading its fields ────────────
      final c = data as CleaningService;
      final product = ServiceProduct(
        id: '${c.name}_cleaning',
        service: 'Cleaning',
        name: c.name,
        price: c.price,
        imagePath: c.image,          // CleaningService uses `image` not `imagePath`
        description: c.description,
        finalPrice: c.finalPrice,
      );
      Cart.addProduct(product, 'Cleaning');
    } else {
      Cart.addProduct(data as ServiceProduct, serviceName);
    }

    if (isWater) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPage(
            products: Cart.getItems('Water'),
            serviceName: 'Water',
            providerId: '',
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
            providerId: '',
          ),
        ),
      );
    }
  }

  // ── SECTION WIDGET ────────────────────────────────────────────────────────
  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── LIST SECTION WIDGET ───────────────────────────────────────────────────
  Widget _listSection(String title, List<String> items) {
    return _section(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(e,
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}