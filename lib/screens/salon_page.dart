import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../models/salon_service_card.dart';
import '../widgets/salon_category_menu.dart';

class SalonPage extends StatefulWidget {
  const SalonPage({super.key});

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = salonCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    final items =
        salonServices.where((s) => s.category == selectedCategory).toList();

    final cartItems = Cart.getItems("Salon");

    return Scaffold(
      body: Row(
        children: [
          /// LEFT MENU
          SalonCategoryMenu(
            categories: salonCategories,
            selectedCategory: selectedCategory,
            onCategorySelected: (c) {
              setState(() => selectedCategory = c);
            },
          ),

          /// RIGHT LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return SalonServiceCard(service: items[index]);
              },
            ),
          ),
        ],
      ),

      /// 🟢 CART BAR
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartPage(
                          serviceName: "Salon",
                          service: '',
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${cartItems.length} items",
                          style: const TextStyle(color: Colors.white)),
                      Text(
                        "₹${Cart.getTotal("Salon")} View Cart →",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
