import 'package:flutter/material.dart';
import '../data/contract_data.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import 'civil_book_page.dart';
import '../widgets/contract_card.dart';

class CivilServicesPage extends StatefulWidget {
  const CivilServicesPage({super.key});

  @override
  State<CivilServicesPage> createState() => _CivilServicesPageState();
}

class _CivilServicesPageState extends State<CivilServicesPage> {
  /// Refresh UI
  void refresh() => setState(() {});

  /// Add Service to Cart
  void addToCart(ServiceProduct service) {
    Cart.add(
      CartItem(
        id: "civil_${service.id}",
        name: service.name,
        price: service.price,
        service: "Civil Contract Services",
        category: service.category ?? "Unknown",
        image: service.imagePath.isNotEmpty ? service.imagePath : "assets/civil.png",
      ),
      service: "Civil Contract Services",
    );

    refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${service.name} added to booking"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = Cart.getTotalItems("Civil Contract Services");
    int totalPrice = Cart.getTotal("Civil Contract Services");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Civil Contract Services"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: civilContractData.entries.map((entry) {
              String category = entry.key;
              List<ServiceProduct> services = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...services.map(
                    (service) => CivilServiceCard(
                      service: service,
                      onAddCart: () => addToCart(service),
                    ),
                  ).toList(),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          ),

          // Mini Cart
          if (totalItems > 0)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text("$totalItems items", style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const Spacer(),
                    Text("₹$totalPrice", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () {
                        // Navigate to CivilBookPage dynamically
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CivilBookPage()),
                        ).then((_) => refresh());
                      },
                      child: const Text("View Cart"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}