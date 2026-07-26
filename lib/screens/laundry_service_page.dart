import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/widgets/laundary_card.dart';
import '../data/laundary_data.dart';
import '../data/service_product.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedCategory = _laundryData.keys.first;
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

  @override
  Widget build(BuildContext context) {
    final cartCount = Cart.totalItems('Laundry');

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
                      top: -6,
                      right: -6,
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
          // ── Left: category rail ──────────────────────────────────
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

          // ── Right: adaptive product grid ─────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Wider screens (tablets/foldables) get 3 columns and a
                // shorter card; phones get 2 columns and a taller card so
                // text never gets squeezed into overflow.
                final crossAxisCount = width > 700 ? 3 : 2;
                final aspectRatio = width > 700 ? 0.74 : 0.60;

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  itemCount: _laundryData[_selectedCategory]!.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (_, index) {
                    final product = _laundryData[_selectedCategory]![index];
                    return LaundryCard(
                      product: product,
                      category: _selectedCategory,
                      serviceName: 'Laundry',
                      onCartChanged: () => setState(() {}),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Scaffold already reserves space for bottomNavigationBar in body,
      // so no manual bottom padding is needed on the grid — that double
      // padding was the source of the overflow/extra gap before.
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