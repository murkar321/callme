import 'package:flutter/material.dart';
import 'package:callme/models/service_products.dart';
import 'booking_page.dart';
import 'cart.dart';
import 'ProductDetailPage.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceName;

  const ServiceDetailPage({super.key, required this.serviceName});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late String selectedCategory;
  final Color primaryColor = const Color(0xFF7B1FA2);

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  double get totalAmount {
    double total = 0;
    for (var item in Cart.items) {
      total += item.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final categories = serviceProducts[widget.serviceName]!.keys.toList();
    final products = serviceProducts[widget.serviceName]![selectedCategory]!;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: primaryColor,
        actions: [
          Stack(
            children: [
              // 🛒 Cart icon in AppBar
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  if (Cart.items.isEmpty) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: widget.serviceName,
                        product: Cart.items.first,
                      ),
                    ),
                  );
                },
              ),
              if (Cart.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      Cart.items.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              /// 🟪 LEFT CATEGORY PANEL
              Container(
                width: 92,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == selectedCategory;
                    final categoryProducts =
                        serviceProducts[widget.serviceName]![category]!;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  AssetImage(categoryProducts.first.imagePath),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? primaryColor : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// 🟦 RIGHT PRODUCT GRID
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    int crossAxisCount = 2;
                    double aspectRatio = 0.70;

                    if (width >= 900) {
                      crossAxisCount = 4;
                      aspectRatio = 0.80;
                    } else if (width >= 600) {
                      crossAxisCount = 3;
                      aspectRatio = 0.75;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🖼 IMAGE (tap to view details)
                              InkWell(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(
                                        product: product,
                                        serviceName: widget.serviceName,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                  child: Image.asset(
                                    product.imagePath,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                          Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ),

                              /// 📄 DETAILS
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "₹${product.price}",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              Cart.items.add(product);
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: primaryColor),
                                            ),
                                            child: Text(
                                              "ADD",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
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
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          /// 🟢 BOTTOM VIEW CART BAR
          if (Cart.items.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: widget.serviceName, // ✅ Fixed
                        product: Cart.items.first,       // ✅ Fixed
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${Cart.items.length} items",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${totalAmount.toStringAsFixed(0)}  View Cart →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
}
