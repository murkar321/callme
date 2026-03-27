import 'package:flutter/material.dart';
import '../data/cleaning_data.dart';
import '../models/cart.dart';
import '../widgets/cleaning_service_card.dart';
import 'booking_page.dart';

class CleaningDetailPage extends StatefulWidget {
  final String serviceName;

  const CleaningDetailPage({
    super.key,
    required this.serviceName,
  });

  @override
  State<CleaningDetailPage> createState() => _CleaningDetailPageState();
}

class _CleaningDetailPageState extends State<CleaningDetailPage> {
  final Color primaryColor = const Color(0xFFAE91BA);
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = cleaningServices.keys.first;
  }

  /// TOTAL ITEMS
  int get totalItems {
    int count = 0;

    final items = Cart.getItems(widget.serviceName);

    for (var item in items) {
      count += Cart.getQuantity(
        item.id,
        widget.serviceName,
      );
    }

    return count;
  }

  /// TOTAL AMOUNT
  int get totalAmount => Cart.getTotal(widget.serviceName);

  @override
  Widget build(BuildContext context) {
    final categories = cleaningServices.keys.toList();

    final products = cleaningServices[selectedCategory]!;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// APPBAR
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          widget.serviceName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          /// CART ICON
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: widget.serviceName,
                        products: null,
                      ),
                    ),
                  );
                },
              ),
              if (totalItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
            ],
          )
        ],
      ),

      /// BODY
      body: Row(
        children: [
          /// LEFT CATEGORY PANEL
          Container(
            width: 95,
            color: Colors.grey.shade100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                final isSelected = selectedCategory == category;

                final firstProduct = cleaningServices[category]!.first;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                          radius: 22,
                          backgroundImage: AssetImage(firstProduct.image),
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
                            color: isSelected ? primaryColor : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// RIGHT SERVICES LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                final id = "${widget.serviceName}_${selectedCategory}_$index";

                return CleaningServiceCard(
                  product: product,
                  serviceName: widget.serviceName,
                  primaryColor: primaryColor,
                  onAdd: () {
                    setState(() {
                      Cart.add(
                        CartItem(
                          id: id,
                          name: product.name,
                          price: product.finalPrice,
                          service: widget.serviceName,
                          category: selectedCategory,
                          image: product.image,
                        ),
                        service: widget.serviceName,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// BOTTOM CART BAR
      bottomNavigationBar: totalItems == 0
          ? null
          : SafeArea(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        serviceName: widget.serviceName,
                        products: null,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$totalItems items",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₹$totalAmount View Cart →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
