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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subTextColor = onSurface.withOpacity(0.65);
    final shadowOpacity = isDark ? 0.30 : 0.05;
    final imagePlaceholder = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,

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
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HERO IMAGE ────────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  color: imagePlaceholder,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image,
                      size: 60,
                      color: subTextColor,
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
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Title over image
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            // ── CONTENT ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Rating + Time row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(shadowOpacity),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, color: subTextColor, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Price card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(shadowOpacity),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '₹$finalPrice',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (discount > 0)
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 18,
                              color: subTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About
                  if (description.isNotEmpty)
                    _section(
                      title: 'About',
                      cardColor: cardColor,
                      onSurface: onSurface,
                      shadowOpacity: shadowOpacity,
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: subTextColor,
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (includes.isNotEmpty)
                    _listSection('Includes', includes, cardColor, onSurface,
                        subTextColor, shadowOpacity),
                  if (process.isNotEmpty)
                    _listSection('Process', process, cardColor, onSurface,
                        subTextColor, shadowOpacity),
                  if (steps.isNotEmpty)
                    _listSection('Steps', steps, cardColor, onSurface,
                        subTextColor, shadowOpacity),

                  if (tools.isNotEmpty)
                    _section(
                      title: 'Tools Required',
                      cardColor: cardColor,
                      onSurface: onSurface,
                      shadowOpacity: shadowOpacity,
                      child: Text(tools,
                          style: TextStyle(fontSize: 14, color: subTextColor)),
                    ),

                  if (warranty.isNotEmpty)
                    _section(
                      title: 'Warranty / Support',
                      cardColor: cardColor,
                      onSurface: onSurface,
                      shadowOpacity: shadowOpacity,
                      child: Text(warranty,
                          style: TextStyle(fontSize: 14, color: subTextColor)),
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
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _handleAction(context),
              child: Text(
                isWater ? 'Book Now' : 'Add to Cart',
                style: const TextStyle(
                  fontSize: 16,
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
  Widget _section({
    required String title,
    required Widget child,
    required Color cardColor,
    required Color onSurface,
    required double shadowOpacity,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: onSurface)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ── LIST SECTION WIDGET ───────────────────────────────────────────────────
  Widget _listSection(
    String title,
    List<String> items,
    Color cardColor,
    Color onSurface,
    Color subTextColor,
    double shadowOpacity,
  ) {
    return _section(
      title: title,
      cardColor: cardColor,
      onSurface: onSurface,
      shadowOpacity: shadowOpacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: onSurface)),
                Expanded(
                  child: Text(e,
                      style: TextStyle(
                          fontSize: 14.5, height: 1.4, color: subTextColor)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}