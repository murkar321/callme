import 'package:callme/screens/booking_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';

class LaundryDetailPage extends StatefulWidget {
  final dynamic product;
  final String serviceName;
  final String category;

  const LaundryDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
    required this.category,
  });

  @override
  State<LaundryDetailPage> createState() => _LaundryDetailPageState();
}

class _LaundryDetailPageState extends State<LaundryDetailPage> {
  int qty = 1;
  String selectedFabric = "Cotton";

  final Color primaryColor = const Color(0xFFAE91BA);

  late Map<String, int> fabricPrices;

  @override
  void initState() {
    super.initState();

    /// You can later move this to backend
    fabricPrices = {
      "Cotton": widget.product.calculatedFinalPrice,
      "Silk": widget.product.calculatedFinalPrice + 70,
      "Wool": widget.product.calculatedFinalPrice + 50,
      "Denim": widget.product.calculatedFinalPrice + 30,
      "Delicate": widget.product.calculatedFinalPrice + 100,
    };
  }

  int get totalPrice => fabricPrices[selectedFabric]! * qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.product.imagePath,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            /// 🔹 NAME
            Text(widget.product.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            /// 🔹 DESCRIPTION
            if (widget.product.description != null)
              Text(widget.product.description!),

            const SizedBox(height: 16),

            /// 🔹 FABRIC
            const Text("Select Fabric",
                style: TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 10),

            ...fabricPrices.entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFabric = entry.key;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedFabric == entry.key
                          ? primaryColor
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text("₹${entry.value} / item"),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),

            /// 🔹 QTY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantity",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (qty > 1) setState(() => qty--);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text(qty.toString()),
                    IconButton(
                      onPressed: () {
                        setState(() => qty++);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                )
              ],
            ),

            const Spacer(),

            /// 🔹 TOTAL + BUTTON
            Text("Total: ₹$totalPrice",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {
                  /// ADD TO CART
                  for (int i = 0; i < qty; i++) {
                    Cart.add(
                      CartItem(
                        id: widget.product.id,
                        name: "${widget.product.name} ($selectedFabric)",
                        price: fabricPrices[selectedFabric]!,
                        service: widget.serviceName,
                        category: widget.category,
                      ),
                      service: widget.serviceName,
                    );
                  }

                  /// NAVIGATE
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
                child: const Text("Add & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
