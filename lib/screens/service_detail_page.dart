import 'package:flutter/material.dart';
import 'package:callme/models/service_product.dart';
import 'package:callme/models/service_product_details.dart';
import 'booking_page.dart';
import 'package:callme/models/cart.dart';

class ServiceDetailPage extends StatefulWidget {
  final String serviceName;

  const ServiceDetailPage({super.key, required this.serviceName});

  ServiceProduct get firstProduct =>
      serviceProducts[serviceName]!.values.first.first;

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late String selectedCategory;

  final Color primaryColor = const Color.fromARGB(255, 174, 145, 186);

  bool isLaundryGuideShown = false; // ✅ NEW FLAG

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  int get totalItems {
    int count = 0;
    Cart.quantities.forEach((_, qty) {
      count += qty;
    });
    return count;
  }

  double get totalAmount {
    double total = 0;
    Cart.quantities.forEach((product, qty) {
      total += product.calculatedFinalPrice * qty;
    });
    return total;
  }

  void showLaundryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_laundry_service, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    "Laundry Guide",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLaundryRow(Icons.checkroom, "Cotton", "₹50 / item"),
              _buildLaundryRow(Icons.auto_awesome, "Silk", "₹120 / item"),
              _buildLaundryRow(Icons.ac_unit, "Wool", "₹100 / item"),
              _buildLaundryRow(Icons.work, "Denim", "₹80 / item"),
              _buildLaundryRow(Icons.star, "Delicate", "₹150 / item"),
              const SizedBox(height: 16),
              const Text(
                "Prices may vary based on fabric condition & service type.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLaundryRow(IconData icon, String fabric, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fabric,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = serviceProducts[widget.serviceName]!.keys.toList();
    final products = serviceProducts[widget.serviceName]![selectedCategory]!;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// APP BAR
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
                          cartItems: Cart.quantities,
                          product: widget.firstProduct,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),

      /// BODY
      body: Row(
        children: [
          /// LEFT CATEGORY PANEL
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

          /// RIGHT PRODUCTS GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
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
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// IMAGE
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.asset(
                          product.imagePath,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      /// CONTENT
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.discount != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${product.discount}% OFF",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (product.slogan != null)
                                Text(
                                  product.slogan!,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "₹${product.calculatedFinalPrice}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (product.discount != null)
                                        Text(
                                          "₹${product.price}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),

                                  /// ✅ UPDATED ADD BUTTON
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Show popup BEFORE adding item
                                      if (widget.serviceName == "Laundry" &&
                                          !isLaundryGuideShown) {
                                        isLaundryGuideShown = true;
                                        showLaundryBottomSheet();
                                      }

                                      setState(() {
                                        Cart.quantities[product] =
                                            (Cart.quantities[product] ?? 0) + 1;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                    ),
                                    child: const Text("ADD"),
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

      /// ✅ VIEW CART BUTTON
      bottomNavigationBar: totalItems == 0
          ? null
          : InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(
                      serviceName: widget.serviceName,
                      cartItems: Cart.quantities,
                      product: widget.firstProduct,
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "₹${totalAmount.toStringAsFixed(0)} View Cart →",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
