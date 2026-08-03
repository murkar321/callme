import 'package:flutter/material.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/bookings/booking_page.dart';
import 'package:callme/data/laundry_fabric_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAUNDRY DETAIL PAGE – Android-safe, fully adaptive, theme-aware
// ─────────────────────────────────────────────────────────────────────────────

class LaundryDetailPage extends StatefulWidget {
  final ServiceProduct product;
  final String category;
  final String serviceName;

  const LaundryDetailPage({
    super.key,
    required this.product,
    required this.category,
    required this.serviceName,
  });

  @override
  State<LaundryDetailPage> createState() => _LaundryDetailPageState();
}

class _LaundryDetailPageState extends State<LaundryDetailPage> {
  // Brand accent — stays constant across light/dark, only surfaces around it change.
  static const _theme = Color(0xFFAE91BA);

  void _openFabricSheet() {
    showLaundryFabricSheet(
      context,
      product: widget.product,
      category: widget.category,
      themeColor: _theme,
      onAdded: () => setState(() {}),
    );
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          service: 'Laundry',
          serviceName: 'Laundry',
          cart: Cart.getItems('Laundry'),
          providerId: '',
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _bookNow() {
    final cartItems = Cart.getItems('Laundry');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          serviceName: widget.serviceName,
          product: cartItems.isEmpty ? widget.product : null,
          cart: cartItems.isEmpty ? null : cartItems,
          products: const [],
          providerId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartCount = Cart.totalItems('Laundry');
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryText = isDark ? Colors.white54 : Colors.grey.shade500;
    final shadowColor = Colors.black.withOpacity(isDark ? 0.35 : 0.05);

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: _theme,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(widget.product.imagePath, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(widget.category,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.product.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: cartCount > 0 ? _goToCart : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: 26),
                          if (cartCount > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(
                                    minWidth: 18, minHeight: 18),
                                child: Text('$cartCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 100 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoCard(
                        cardBg: cardBg,
                        shadowColor: shadowColor,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service Price',
                                      style: TextStyle(color: secondaryText)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${widget.product.calculatedFinalPrice}',
                                    style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: _theme),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.product.discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.green.withOpacity(0.4)
                                        : Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  '${widget.product.discount}% OFF',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.green.shade300
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.product.description != null) ...[
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: 'Description',
                          cardBg: cardBg,
                          shadowColor: shadowColor,
                          titleColor: primaryText,
                          child: Text(widget.product.description!,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.65,
                                  color: primaryText)),
                        ),
                      ],
                      if (widget.product.safeIncludes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: "What's Included",
                          cardBg: cardBg,
                          shadowColor: shadowColor,
                          titleColor: primaryText,
                          child: Column(
                            children: widget.product.safeIncludes.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          color: Colors.green, size: 15),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(item,
                                          style: TextStyle(
                                              fontSize: 15,
                                              height: 1.5,
                                              color: primaryText)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (widget.product.tools != null) ...[
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: 'Tools Used',
                          cardBg: cardBg,
                          shadowColor: shadowColor,
                          titleColor: primaryText,
                          child: Text(widget.product.tools!,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.65,
                                  color: primaryText)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom action bar — SafeArea handles nav bar insets ─────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.09),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Starting from',
                              style:
                                  TextStyle(color: secondaryText, fontSize: 12)),
                          const SizedBox(height: 3),
                          Text(
                            '₹${widget.product.calculatedFinalPrice}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryText),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _openFabricSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('ADD',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _bookNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _theme,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('BOOK',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
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

  Widget _infoCard({
    required Widget child,
    required Color cardBg,
    required Color shadowColor,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _sectionCard({
    required String title,
    required Widget child,
    required Color cardBg,
    required Color shadowColor,
    required Color titleColor,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}