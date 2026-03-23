import 'package:flutter/material.dart';
import 'package:callme/models/service_product_details.dart';
import 'booking_page.dart';
import 'package:callme/models/cart.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceName;

  const ServiceDetailPage({super.key, required this.serviceName});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late String selectedCategory;

  final Color primaryColor = const Color.fromARGB(255, 174, 145, 186);

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  /// ✅ TOTAL ITEMS
  int get totalItems {
    int count = 0;
    final items = Cart.getItems(widget.serviceName);
    for (var item in items) {
      count += Cart.getQuantity(item.id, widget.serviceName);
    }
    return count;
  }

  /// ✅ TOTAL AMOUNT
  int get totalAmount => Cart.getTotal(widget.serviceName);

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
                        builder: (_) =>
                            BookingPage(serviceName: widget.serviceName, products: null,),
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
          /// 🔹 LEFT CATEGORY PANEL
          Container(
            width: screenWidth * 0.22,
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
                    margin: const EdgeInsets.all(6),
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
                          radius: 20,
                          backgroundImage:
                              AssetImage(categoryProducts.first.imagePath),
                        ),
                        const SizedBox(height: 4),
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
                childAspectRatio: 0.58,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                /// ✅ FIXED
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
                      /// 🔹 IMAGE
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.asset(
                          product.imagePath,
                          height: 85,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      /// 🔹 CONTENT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("₹${product.calculatedFinalPrice}"),

                                  /// ✅ FIXED ADD/REMOVE
                                  qty == 0
                                      ? ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              Cart.add(
                                                CartItem(
                                                  id: product.id,
                                                  name: product.name,
                                                  price: product
                                                      .calculatedFinalPrice,
                                                  service: widget.serviceName,
                                                  category: selectedCategory,
                                                ),
                                                service: widget.serviceName,
                                              );
                                            });
                                          },
                                          child: const Text("ADD"),
                                        )
                                      : Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                setState(() {
                                                  Cart.removeById(product.id,
                                                      widget.serviceName);
                                                });
                                              },
                                            ),
                                            Text(qty.toString()),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  Cart.add(
                                                    CartItem(
                                                      id: product.id,
                                                      name: product.name,
                                                      price: product
                                                          .calculatedFinalPrice,
                                                      service:
                                                          widget.serviceName,
                                                      category:
                                                          selectedCategory,
                                                    ),
                                                    service: widget.serviceName,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
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
                    builder: (_) =>
                        BookingPage(serviceName: widget.serviceName, products: null,),
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
