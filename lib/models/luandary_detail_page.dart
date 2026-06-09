import 'package:flutter/material.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/bookings/booking_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAUNDRY DETAIL PAGE
// • ADD button → fabric-selection popup → adds to cart
// • BOOK NOW button → goes to BookingPage with cart
// • No prices in fabric popup (same as service page)
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
  static const _theme = Color(0xFFAE91BA);

  // Fabric options — no price, just selection + qty
  static const List<String> _fabrics = [
    'Cotton', 'Silk', 'Wool', 'Denim', 'Polyester', 'Curtains', 'Shoes',
  ];

  // ── Fabric popup ────────────────────────────────────────────────────────────
  void _showFabricPopup() {
    final Map<String, int> qty = {for (final f in _fabrics) f: 0};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final totalPieces = qty.values.fold(0, (s, q) => s + q);

          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose Fabric & Qty',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Add multiple fabrics in one order',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Fabric rows
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _fabrics.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final name = _fabrics[i];
                      final q = qty[name]!;
                      final active = q > 0;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? _theme.withOpacity(0.07)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active
                                ? _theme.withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: 1.3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _QtyControl(
                              qty: q,
                              color: _theme,
                              onDecrement: q > 0
                                  ? () =>
                                      setModal(() => qty[name] = q - 1)
                                  : null,
                              onIncrement: () =>
                                  setModal(() => qty[name] = q + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Piece count
                if (totalPieces > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$totalPieces piece${totalPieces == 1 ? '' : 's'} selected',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // ADD TO CART
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: totalPieces == 0
                        ? null
                        : () {
                            for (final name in _fabrics) {
                              final q = qty[name]!;
                              if (q > 0) {
                                for (int i = 0; i < q; i++) {
                                  Cart.addLaundry(
                                    id: '${widget.product.id}_${name.toLowerCase()}',
                                    name: '${widget.product.name} ($name)',
                                    price:
                                        widget.product.calculatedFinalPrice,
                                    category: widget.category,
                                    image: widget.product.imagePath,
                                  );
                                }
                              }
                            }
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _theme,
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      totalPieces == 0
                          ? 'ADD TO CART'
                          : 'ADD $totalPieces ITEM${totalPieces == 1 ? '' : 'S'} TO CART',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // VIEW CART
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _goToCart();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _theme, width: 1.4),
                      foregroundColor: _theme,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('VIEW CART',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
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
          products: [],
          providerId: '',
        ),
      ),
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cartCount = Cart.totalItems('Laundry');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // App bar with hero image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: _theme,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(widget.product.imagePath,
                          fit: BoxFit.cover),
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
                              child: Text(
                                widget.category,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Cart icon in app bar
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
                              top: -6, right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price card
                      _infoCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Service Price',
                                      style: TextStyle(
                                          color: Colors.grey.shade500)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${widget.product.calculatedFinalPrice}',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: _theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.product.discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.green.shade200),
                                ),
                                child: Text(
                                  '${widget.product.discount}% OFF',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (widget.product.description != null) ...[
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: 'Description',
                          child: Text(
                            widget.product.description!,
                            style: const TextStyle(
                                fontSize: 15, height: 1.65),
                          ),
                        ),
                      ],

                      if (widget.product.safeIncludes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionCard(
                          title: "What's Included",
                          child: Column(
                            children:
                                widget.product.safeIncludes.map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          color: Colors.green, size: 15),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(item,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              height: 1.5)),
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
                          child: Text(widget.product.tools!,
                              style: const TextStyle(
                                  fontSize: 15, height: 1.65)),
                        ),
                      ],

                      // Space for bottom bar
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom bar ──────────────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starting from',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(
                          '₹${widget.product.calculatedFinalPrice}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ADD button → fabric popup → cart
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showFabricPopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(0, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // BOOK NOW → booking page
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _bookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme,
                        minimumSize: const Size(0, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'BOOK',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _infoCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// QTY CONTROL  (shared between popup and any future reuse)
// ─────────────────────────────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final int qty;
  final Color color;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _QtyControl({
    required this.qty,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove,
          color: color,
          enabled: onDecrement != null,
          onTap: onDecrement ?? () {},
        ),
        SizedBox(
          width: 34,
          child: Text('$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        _Btn(
            icon: Icons.add,
            color: color,
            enabled: true,
            onTap: onIncrement),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 15,
            color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}
