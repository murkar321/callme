import 'package:callme/models/service_product_details.dart';
import 'package:callme/screens/ServiceViewDetailPage.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';


class ServiceDetailPage extends StatefulWidget {
  final String serviceName;

  const ServiceDetailPage({super.key, required this.serviceName});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final Color primaryColor = const Color(0xFFAE91BA);
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = serviceProducts[widget.serviceName]!.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final categories = serviceProducts[widget.serviceName]!.keys.toList();
    final products =
        serviceProducts[widget.serviceName]![selectedCategory]!;

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.serviceName),
        centerTitle: true,
      ),

      body: Row(
        children: [
          /// LEFT CATEGORY
          Container(
            width: width * 0.22,
            color: Colors.grey.shade100,
            child: ListView.builder(
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
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [const BoxShadow(color: Colors.black12)]
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
              padding: const EdgeInsets.all(10),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                                top: Radius.circular(18)),
                            child: Image.asset(
                              product.imagePath,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          /// DISCOUNT BADGE
                          if (product.discount! > 0)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${product.discount}% OFF",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),

                      /// CONTENT
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),

                            Text(
                              product.slogan ?? "",
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 6),

                            /// RATING + TIME
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Text("${product.rating}"),
                                const SizedBox(width: 10),
                                const Icon(Icons.access_time,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(product.time ?? ""),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// PRICE
                            Row(
                              children: [
                                Text(
                                  "₹${product.calculatedFinalPrice}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "₹${product.price}",
                                  style: const TextStyle(
                                    decoration:
                                        TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            /// BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ServiceViewDetailPage(
                                            product: product,
                                            serviceName:
                                                widget.serviceName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text("View"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor),
                                    onPressed: () {
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

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("Added to cart")),
                                      );
                                    },
                                    child: const Text("Add"),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}