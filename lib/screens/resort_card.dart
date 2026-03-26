import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';

class ResortCard extends StatefulWidget {
  final ServiceProduct resort;
  final VoidCallback onTap;

  const ResortCard({
    super.key,
    required this.resort,
    required this.onTap,
  });

  @override
  State<ResortCard> createState() => _ResortCardState();
}

class _ResortCardState extends State<ResortCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<Color?> _colorAnimation;

  bool showCartPopup = false;

  /// 🔥 CREATE CART ITEM
  CartItem get cartItem => CartItem(
        id: widget.resort.id,
        name: widget.resort.name,
        price: widget.resort.finalPrice ?? widget.resort.price,
        service: "Resorts",
        category: "Resort",
        image: widget.resort.imagePath,
      );

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _colorAnimation = ColorTween(begin: Colors.teal, end: Colors.green)
        .animate(_blinkController);

    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _blinkController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  /// 🔥 ADD
  void _addItem() {
    Cart.add(cartItem, service: '');
    _blinkController.forward();

    setState(() => showCartPopup = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.resort.name} added"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 🔥 REMOVE
  void _removeItem() {
    Cart.remove(cartItem);
    setState(() {});
  }

  /// 🔥 NAVIGATE CART
  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const CartPage(
                service: '',
                serviceName: '',
              )),
    ).then((_) {
      setState(() => showCartPopup = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    int qty = Cart.getQuantity(widget.resort.id, "Resorts");

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔷 IMAGE
              GestureDetector(
                onTap: widget.onTap,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      Image.asset(
                        widget.resort.imagePath,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                      /// 🔥 DISCOUNT
                      if (widget.resort.discount != null &&
                          widget.resort.discount! > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.resort.discount}% OFF',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),

                      /// ⭐ RATING
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Colors.orange),
                              Text(
                                " ${widget.resort.rating}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔷 DETAILS
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME
                    Text(
                      widget.resort.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),

                    const SizedBox(height: 4),

                    /// PRICE
                    Row(
                      children: [
                        Text(
                          '₹${widget.resort.finalPrice ?? widget.resort.price}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.teal),
                        ),
                        const SizedBox(width: 6),
                        if (widget.resort.price != widget.resort.finalPrice)
                          Text(
                            '₹${widget.resort.price}',
                            style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: Colors.grey),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    /// 🔥 ADD / QTY BUTTON
                    qty == 0
                        ? SizedBox(
                            height: 32,
                            child: AnimatedBuilder(
                              animation: _colorAnimation,
                              builder: (_, __) => ElevatedButton(
                                onPressed: _addItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _colorAnimation.value ?? Colors.teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Add",
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          )
                        : Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    _removeItem();
                                  },
                                ),
                                Text(qty.toString()),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    _addItem();
                                  },
                                ),
                              ],
                            ),
                          ),

                    const SizedBox(height: 6),

                    /// VIEW BUTTON
                    SizedBox(
                      height: 28,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onTap,
                        child:
                            const Text("View", style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// 🔥 CART POPUP
        if (showCartPopup && Cart.totalItems("Resorts") > 0)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _goToCart,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 5)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${Cart.totalItems("Resorts")} items • ₹${Cart.totalPrice("Resorts")}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _goToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text("Book Now"),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
