import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/models/luandary_detail_page.dart';
import '../data/laundary_data.dart';
import '../data/service_product.dart';
import '../widgets/laundary_card.dart';

class LaundryServicePage extends StatefulWidget {
  const LaundryServicePage({super.key});

  @override
  State<LaundryServicePage> createState() =>
      _LaundryServicePageState();
}

class _LaundryServicePageState
    extends State<LaundryServicePage> {

  final Map<String, List<ServiceProduct>> laundryData =
      serviceProducts['Laundry']!;

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = laundryData.keys.first;
  }

  // ─── Fabric options ────────────────────────────────────────────
  final List<Map<String, dynamic>> fabricOptions = const [
    {"name": "Cotton",   "price": 50},
    {"name": "Silk",     "price": 70},
    {"name": "Wool",     "price": 80},
    {"name": "Denim",    "price": 60},
    {"name": "Curtains", "price": 90},
    {"name": "Shoes",    "price": 100},
  ];

  // ─── Multi-select fabric popup ─────────────────────────────────
  void showFabricPopup(ServiceProduct product) {

    // Track qty per fabric: name → qty (0 = not selected)
    final Map<String, int> fabricQty = {
      for (var f in fabricOptions) f["name"] as String: 0,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            // Total extra cost from selected fabrics
            int fabricTotal = 0;
            int totalPieces = 0;
            for (var f in fabricOptions) {
              final name  = f["name"]  as String;
              final price = f["price"] as int;
              final qty   = fabricQty[name]!;
              fabricTotal += price * qty;
              totalPieces += qty;
            }

            final basePrice = product.calculatedFinalPrice;

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [

                  // Handle
                  Container(
                    width: 50, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Fabric & Qty",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Fabric list with +/- controls
                  Expanded(
                    child: ListView(
                      children: fabricOptions.map((f) {
                        final name  = f["name"]  as String;
                        final price = f["price"] as int;
                        final qty   = fabricQty[name]!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Row(
                            children: [

                              // Fabric name + price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "₹$price / piece",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Qty control
                              Row(
                                children: [
                                  _qtyButton(
                                    icon: Icons.remove,
                                    onTap: qty > 0
                                        ? () => setModalState(() =>
                                            fabricQty[name] = qty - 1)
                                        : null,
                                  ),
                                  Container(
                                    width: 36,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$qty",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _qtyButton(
                                    icon: Icons.add,
                                    onTap: () => setModalState(() =>
                                        fabricQty[name] = qty + 1),
                                  ),
                                ],
                              ),

                              // Sub-total for this fabric
                              SizedBox(
                                width: 60,
                                child: Text(
                                  qty > 0
                                      ? "₹${price * qty}"
                                      : "",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFAE91BA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(),

                  // Total row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$totalPieces piece${totalPieces == 1 ? '' : 's'} selected",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "Total ₹${basePrice + fabricTotal}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ADD TO CART button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: totalPieces == 0
                          ? null
                          : () {
                              // Add one cart entry per selected fabric
                              fabricOptions.forEach((f) {
                                final name  = f["name"]  as String;
                                final price = f["price"] as int;
                                final qty   = fabricQty[name]!;
                                if (qty > 0) {
                                  for (int i = 0; i < qty; i++) {
                                    Cart.addLaundry(
                                      id: "${product.id}_${name.toLowerCase()}",
                                      name: "${product.name} ($name)",
                                      price: basePrice + price,
                                      category: selectedCategory,
                                      image: product.imagePath,
                                    );
                                  }
                                }
                              });
                              Navigator.pop(context);
                              setState(() {});
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAE91BA),
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        totalPieces == 0
                            ? "SELECT AT LEAST ONE"
                            : "ADD $totalPieces ITEM${totalPieces == 1 ? '' : 'S'} TO CART",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // VIEW CART button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartPage(
                              service: "Laundry",
                              serviceName: "Laundry",
                              cart: Cart.getItems("Laundry"),
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("VIEW CART"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Small +/- icon button helper
  Widget _qtyButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFFAE91BA).withOpacity(0.15)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? const Color(0xFFAE91BA)
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final int cartCount  = Cart.totalItems("Laundry");
    final int totalPrice = Cart.getTotal("Laundry");
    const Color themeColor = Color(0xFFAE91BA);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "Laundry",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: themeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          /// 🛒 CART BADGE
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: cartCount > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartPage(
                            service: "Laundry",
                            serviceName: "Laundry",
                            cart: Cart.getItems("Laundry"),
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            cartCount > 99 ? "99+" : "$cartCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

          /// LEFT CATEGORY PANEL
          Container(
            width: 90,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: laundryData.keys.map((category) {
                final isSelected = selectedCategory == category;
                final image = laundryData[category]!.first.imagePath;

                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected
                              ? themeColor
                              : Colors.grey.shade200,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(image),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? themeColor
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          /// RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                cartCount > 0 ? 90 : 10,
              ),
              itemCount: laundryData[selectedCategory]!.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 240,
              ),
              itemBuilder: (context, index) {
                final product =
                    laundryData[selectedCategory]![index];
                return LaundryCard(
                  product: product,
                  category: selectedCategory,
                  onAdd: () => showFabricPopup(product),
                  onView: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaundryDetailPage(
                          product: product,
                          category: selectedCategory,
                          serviceName: "Laundry",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// 🔥 BOTTOM CART BAR — disappears instantly when cart is empty
      bottomNavigationBar: cartCount > 0
          ? SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: themeColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$cartCount item${cartCount == 1 ? '' : 's'} • ₹$totalPrice",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service: "Laundry",
                                serviceName: "Laundry",
                                cart: Cart.getItems("Laundry"),
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        child: const Text("View Cart"),
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
