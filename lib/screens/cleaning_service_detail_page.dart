import 'package:flutter/material.dart';
import '../models/cleaning_service.dart';
import 'booking_page.dart';

class CleaningServiceDetailPage extends StatefulWidget {
  final CleaningService product;
  final String serviceName;

  const CleaningServiceDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
  });

  @override
  State<CleaningServiceDetailPage> createState() =>
      _CleaningServiceDetailPageState();
}

class _CleaningServiceDetailPageState
    extends State<CleaningServiceDetailPage> {
  bool isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFAE91BA);
    final product = widget.product;
    final serviceName = widget.serviceName;

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      /// APPBAR
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(product.name),
      ),

      /// BODY
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 IMAGE WITH DISCOUNT
                  Stack(
                    children: [
                      Image.asset(
                        product.image,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${product.discount}% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),

                  /// 🔹 DETAILS
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// NAME
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// RATING + TIME
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            const Text("5.0"),
                            const SizedBox(width: 15),
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(product.time),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// PRICE
                        Row(
                          children: [
                            Text(
                              "₹${product.finalPrice}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "₹${product.price}",
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        /// DESCRIPTION
                        const Text(
                          "Service Description",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          product.description,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🔹 INCLUDES
                        if (product.includes.isNotEmpty)
                          _buildSection(
                            "Includes",
                            product.includes,
                            Icons.check_circle,
                            Colors.green,
                          ),

                        /// 🔹 EXCLUDES
                        if (product.excludes.isNotEmpty)
                          _buildSection(
                            "Excludes",
                            product.excludes,
                            Icons.cancel,
                            Colors.red,
                          ),

                        /// 🔹 STEPS
                        if (product.steps.isNotEmpty)
                          _buildSection(
                            "Service Steps",
                            product.steps,
                            Icons.list,
                            primaryColor,
                          ),

                        /// 🔹 TOOLS
                        if (product.tools.isNotEmpty)
                          _buildTextSection(
                            "Tools Used",
                            product.tools,
                          ),

                        /// 🔹 WARRANTY
                        if (product.warranty.isNotEmpty)
                          _buildTextSection(
                            "Warranty",
                            product.warranty,
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          /// 🔹 BOOK BUTTON (FIXED FOR MOBILE)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                )
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isNavigating
                      ? null
                      : () async {
                          setState(() {
                            isNavigating = true;
                          });

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingPage(
                                serviceName: serviceName,
                                products: product,
                                cart: [],
                              ),
                            ),
                          );

                          if (mounted) {
                            setState(() {
                              isNavigating = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isNavigating
                        ? "Opening..."
                        : "Book Now • ₹${product.finalPrice}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 🔹 LIST SECTION
  Widget _buildSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(e)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 🔹 TEXT SECTION
  Widget _buildTextSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(value),
        const SizedBox(height: 16),
      ],
    );
  }
}