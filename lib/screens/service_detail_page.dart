import 'package:flutter/material.dart';
import 'package:callme/models/service_product_details.dart';
import 'package:callme/models/cart.dart';
import 'booking_page.dart';
import 'package:callme/models/luandary_detail_page.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceName;

  const ServiceDetailPage({super.key, required this.serviceName});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late String selectedCategory;

  final Color primaryColor = const Color(0xFFAE91BA);

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  /// 🔹 CART INFO
  int get totalItems {
    int count = 0;
    final items = Cart.getItems(widget.serviceName);
    for (var item in items) {
      count += Cart.getQuantity(item.id, widget.serviceName);
    }
    return count;
  }

  int get totalAmount => Cart.getTotal(widget.serviceName);

  /// 🔹 ADD HANDLER (MAIN LOGIC)
  void handleAdd(product) {
    /// 🧺 Laundry → open detail page
    if (widget.serviceName.toLowerCase().contains("laundry")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LaundryDetailPage(
            product: product,
            serviceName: widget.serviceName,
            category: selectedCategory,
          ),
        ),
      );
      return;
    }

    /// 🔹 Normal flow
    setState(() {
      Cart.add(
        CartItem(
          id: product.id,
          name: product.name,
          price: product.calculatedFinalPrice,
          service: widget.serviceName,
          category: selectedCategory,
        ),
        service: widget.serviceName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = serviceProducts[widget.serviceName]!.keys.toList();

    final products = serviceProducts[widget.serviceName]![selectedCategory]!;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// 🔹 APP BAR
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: primaryColor,
        actions: [
          if (totalItems > 0)
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
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      totalItems.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),

      /// 🔹 BODY
      body: Row(
        children: [
          /// 🔹 LEFT CATEGORY
          Container(
            width: screenWidth * 0.22,
            color: Colors.grey.shade100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                final categoryProducts =
                    serviceProducts[widget.serviceName]![category]!;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                  color: Colors.black12, blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              AssetImage(categoryProducts.first.imagePath),
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

          /// 🔹 RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 250,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final qty = Cart.getQuantity(product.id, widget.serviceName);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// IMAGE + DISCOUNT
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.asset(
                              product.imagePath,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (product.discount != null && product.discount! > 0)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${product.discount}% OFF",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 9),
                                ),
                              ),
                            ),
                        ],
                      ),

                      /// CONTENT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// TEXT BLOCK
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (product.slogan != null)
                                    Text(
                                      product.slogan!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),
                                  if (product.rating != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.orange),
                                        const SizedBox(width: 2),
                                        Text(
                                          product.rating.toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              /// PRICE + BUTTON
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "₹${product.calculatedFinalPrice}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (product.originalPrice >
                                            product.calculatedFinalPrice)
                                          Text(
                                            "₹${product.originalPrice}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  /// BUTTON
                                  qty == 0
                                      ? SizedBox(
                                          height: 28,
                                          child: ElevatedButton(
                                            onPressed: () => handleAdd(product),
                                            child: const Text(
                                              "ADD",
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: primaryColor),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    Cart.removeById(product.id,
                                                        widget.serviceName);
                                                  });
                                                },
                                                child: Icon(Icons.remove,
                                                    size: 16,
                                                    color: primaryColor),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(qty.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => handleAdd(product),
                                                child: Icon(Icons.add,
                                                    size: 16,
                                                    color: primaryColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      /// 🔹 BOTTOM BAR
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
                    Text("$totalItems items",
                        style: const TextStyle(color: Colors.white)),
                    Text("₹$totalAmount View Cart →",
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
    );
  }
}
