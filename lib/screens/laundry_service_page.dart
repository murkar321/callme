import 'package:callme/models/luandary_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import '../data/laundary_data.dart';
import '../data/service_product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LAUNDRY SERVICE PAGE  – Android-safe, adaptive layout
// ─────────────────────────────────────────────────────────────────────────────

class LaundryServicePage extends StatefulWidget {
  const LaundryServicePage({super.key});

  @override
  State<LaundryServicePage> createState() => _LaundryServicePageState();
}

class _LaundryServicePageState extends State<LaundryServicePage> {
  static const _theme = Color(0xFFAE91BA);

  final Map<String, List<ServiceProduct>> _laundryData =
      serviceProducts['Laundry']!;

  late String _selectedCategory;

  static const List<String> _fabrics = [
    'Cotton', 'Silk', 'Wool', 'Denim', 'Polyester',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _laundryData.keys.first;
  }

  // ── Fabric popup ────────────────────────────────────────────────────────────
  void _showFabricPopup(ServiceProduct product) {
    final Map<String, int> qty = {for (final f in _fabrics) f: 0};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // useSafeArea keeps popup above Android nav bar automatically
      useSafeArea: false,
      builder: (ctx) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            final totalPieces = qty.values.fold(0, (sum, q) => sum + q);
            final mq = MediaQuery.of(ctx);
            // Use viewInsets for keyboard + viewPadding for nav bar
            final bottomPad = mq.viewPadding.bottom;

            return Container(
              // Max 60% of screen; shrink on small screens
              constraints: BoxConstraints(
                maxHeight: mq.size.height * 0.60,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Select fabric & quantity',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500)),
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
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),

                  // Fabric list — scrollable
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 18),
                      itemCount: _fabrics.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final name = _fabrics[i];
                        final q = qty[name]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ),
                              _QtyControl(
                                qty: q,
                                color: _theme,
                                onDecrement: q > 0
                                    ? () => setModal(() => qty[name] = q - 1)
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

                  const Divider(height: 1),

                  // Footer — padded above Android nav bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 10, 18, bottomPad + 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (totalPieces > 0) ...[
                          Text(
                            '$totalPieces piece${totalPieces == 1 ? '' : 's'} selected',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: totalPieces == 0
                                ? null
                                : () {
                                    for (final name in _fabrics) {
                                      final q = qty[name]!;
                                      if (q > 0) {
                                        for (int i = 0; i < q; i++) {
                                          Cart.addLaundry(
                                            id: '${product.id}_${name.toLowerCase()}',
                                            name: '${product.name} ($name)',
                                            price: product.calculatedFinalPrice,
                                            category: _selectedCategory,
                                            image: product.imagePath,
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
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              totalPieces == 0
                                  ? 'SELECT AT LEAST ONE'
                                  : 'ADD $totalPieces ITEM${totalPieces == 1 ? '' : 'S'} TO CART',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cartCount = Cart.totalItems('Laundry');
    // Bottom padding: safe area (nav bar) + cart bar height if visible
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Laundry',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _theme,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      top: -6, right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          cartCount > 99 ? '99+' : '$cartCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Row(
        children: [
          // ── Left: category rail ───────────────────────────────────────
          Container(
            width: 88,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: _laundryData.keys.map((cat) {
                final selected = cat == _selectedCategory;
                final img = _laundryData[cat]!.first.imagePath;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              selected ? _theme : Colors.grey.shade200,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(img),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          cat,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selected ? _theme : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Right: product grid ───────────────────────────────────────
          Expanded(
            child: GridView.builder(
              // Extra bottom padding = cart bar height (68) + nav bar inset
              padding: EdgeInsets.fromLTRB(
                  10, 10, 10, cartCount > 0 ? 68 + bottomPad + 10 : 10),
              itemCount: _laundryData[_selectedCategory]!.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 230,
              ),
              itemBuilder: (_, index) {
                final product = _laundryData[_selectedCategory]![index];
                return _LaundryCard(
                  product: product,
                  category: _selectedCategory,
                  onAdd: () => _showFabricPopup(product),
                  onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LaundryDetailPage(
                        product: product,
                        category: _selectedCategory,
                        serviceName: 'Laundry',
                      ),
                    ),
                  ).then((_) => setState(() {})),
                );
              },
            ),
          ),
        ],
      ),

      // ── Bottom cart bar — sits above Android nav bar via SafeArea ─────
      bottomNavigationBar: cartCount > 0
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _theme,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$cartCount item${cartCount == 1 ? '' : 's'} in cart',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _goToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _theme,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text('View Cart',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE PRODUCT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LaundryCard extends StatelessWidget {
  final ServiceProduct product;
  final String category;
  final VoidCallback onAdd;
  final VoidCallback onView;

  const _LaundryCard({
    required this.product,
    required this.category,
    required this.onAdd,
    required this.onView,
  });

  static const _theme = Color(0xFFAE91BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 5 / 3,
                  child: Image.asset(product.imagePath, fit: BoxFit.cover),
                ),
              ),
              if (product.badge != null && product.badge!.isNotEmpty)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(product.badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(children: [
                  Text('₹${product.calculatedFinalPrice}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  if (product.discount != null && product.discount! > 0)
                    Text('${product.discount}% OFF',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.star, size: 12, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text(product.safeRating.toString(),
                      style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(product.serviceTime,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _theme,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('ADD',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: onView,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                              color: Colors.grey.shade300, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('VIEW',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QTY CONTROL
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
        _Btn(icon: Icons.add, color: color, enabled: true, onTap: onIncrement),
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