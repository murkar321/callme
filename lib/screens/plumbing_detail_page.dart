import 'package:flutter/material.dart';
import '../models/service_product_details.dart';
import '../models/cart.dart';
import '../widgets/plumbing_service_card.dart';
import 'booking_page.dart';

class PlumbingDetailPage extends StatefulWidget {
  final String serviceName;

  const PlumbingDetailPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<PlumbingDetailPage> createState() => _PlumbingDetailPageState();
}

class _PlumbingDetailPageState extends State<PlumbingDetailPage> {
  final Color primaryColor = const Color(0xFFAE91BA);

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  /// TOTAL ITEMS
  int get totalItems {
    int count = 0;
    final items = Cart.getItems(widget.serviceName);

    for (var item in items) {
      count += Cart.getQuantity(item.id, widget.serviceName);
    }
    return count;
  }

  /// TOTAL AMOUNT
  int get totalAmount => Cart.getTotal(widget.serviceName);

  @override
  Widget build(BuildContext context) {
    final categories = serviceProducts[widget.serviceName]!.keys.toList();
    final products =
        serviceProducts[widget.serviceName]![selectedCategory]!;

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// APPBAR
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.serviceName),
        centerTitle: true,
        elevation: 0,
      ),

      /// BODY
      body: Row(
        children: [
          /// LEFT CATEGORY PANEL
          Container(
            width: width * 0.22,
            color: Colors.grey.shade100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                final firstProduct =
                    serviceProducts[widget.serviceName]![category]!.first;

                return GestureDetector(
                  onTap: () {
                    setState(() => selectedCategory = category);
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage(firstProduct.imagePath),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                isSelected ? primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT SERVICES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return PlumbingServiceCard(
                  product: product,
                  serviceName: widget.serviceName,
                  primaryColor: primaryColor,
                  onAdd: () {
                    setState(() {
                      Cart.add(
                        CartItem(
                          id: product.id,
                          name: product.name,
                          price: product.calculatedFinalPrice,
                          service: widget.serviceName,
                          category: selectedCategory,
                          image: product.imagePath,
                        ),
                        service: widget.serviceName,
                      );
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to cart")),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// BOTTOM VIEW CART BAR
      bottomNavigationBar: totalItems == 0
          ? null
          : InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      serviceName: widget.serviceName,
                      products: null,
                      cart: [],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$totalItems items",
                      style:
                          const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "₹$totalAmount View Cart →",
                      style:
                          const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}