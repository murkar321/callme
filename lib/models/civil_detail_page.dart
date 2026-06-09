import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import 'civil_services_page.dart'; // for kCivilServiceKey

class CivilServiceDetailPage extends StatefulWidget {
  final SubService service;
  final String mainServiceId;

  const CivilServiceDetailPage({
    super.key,
    required this.service,
    required this.mainServiceId,
  });

  @override
  State<CivilServiceDetailPage> createState() =>
      _CivilServiceDetailPageState();
}

class _CivilServiceDetailPageState extends State<CivilServiceDetailPage> {
  bool _addedToCart = false;

  bool get isRenovation => widget.mainServiceId == "renovation";

  int _extractPrice(String price) {
    final numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;
    return int.tryParse(numbers) ?? 0;
  }

  void handlePrimaryAction() {
    if (isRenovation) {
      Navigator.pop(context);
    } else {
      Cart.add(
        CartItem(
          id: widget.service.id,        // no prefix — same as services page
          name: widget.service.name,
          price: _extractPrice(widget.service.price),
          service: kCivilServiceKey,    // ← consistent key
          category: widget.mainServiceId,
          image: widget.service.image,
        ),
        service: kCivilServiceKey,      // ← consistent key
      );
      setState(() => _addedToCart = true);
    }
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          serviceName: "Civil Contract Services",
          service: kCivilServiceKey,    // ← consistent key
          providerId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.08)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 55,
            child: isRenovation
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: handlePrimaryAction,
                    child: const Text(
                      "Customize & Book",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  )
                : _addedToCart
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: openCart,
                        icon: const Icon(Icons.shopping_cart, size: 20),
                        label: const Text(
                          "View Cart",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: handlePrimaryAction,
                        child: const Text(
                          "Book Now",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
          ),
        ),
      ),

      body: CustomScrollView(
        slivers: [
          /// HERO IMAGE
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.service.image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.service.rating.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (widget.service.discount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${widget.service.discount}% OFF",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PRICE CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee,
                            color: Colors.green, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.service.price,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Best Price",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// WHAT'S INCLUDED
                  const Text(
                    "What's Included",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (widget.service.features != null)
                    ...widget.service.features!.map(
                      (feature) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.04),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.green, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(feature,
                                  style: const TextStyle(fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  /// RENOVATION NOTE
                  if (isRenovation)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customization Available",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text("• Select required services"),
                          Text("• Modify work scope"),
                          Text("• Final quotation shared after inspection"),
                        ],
                      ),
                    ),

                  /// ADDED TO CART confirmation
                  if (!isRenovation && _addedToCart)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Service added to your cart! Tap 'View Cart' to proceed.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// BOOK INFO NOTE (before booking)
                  if (!isRenovation && !_addedToCart)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Tap 'Book Now' to add this service to your cart.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}