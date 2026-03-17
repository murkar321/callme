import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/data/salon_data.dart';
import 'package:callme/models/salon_service_card.dart';
import 'package:callme/widgets/salon_category_menu.dart';
import 'package:callme/models/cart.dart';


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

    selectedCategory =
        salonCategories.isNotEmpty ? salonCategories.first : "";
  }

  @override
  Widget build(BuildContext context) {

    List<SalonService> filtered = salonServices
        .where((service) => service.category == selectedCategory)
        .toList();

    return Scaffold(

      /// BODY
      body: Row(
        children: [

          /// LEFT MENU
          SalonCategoryMenu(
            categories: salonCategories,
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
          ),

          /// RIGHT GRID
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No services available"))
                : LayoutBuilder(
                    builder: (context, constraints) {


                      return GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // keep stable for mobile
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          return SalonServiceCard(
                            service: filtered[index],
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      /// ✅ BOTTOM CART BAR
      bottomNavigationBar: Cart.items.isNotEmpty
          ? Container(
              color: const Color.fromARGB(255, 70, 187, 88),
              padding: const EdgeInsets.all(12),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      "${Cart.items.length} item(s)",
                      style: const TextStyle(color: Colors.white),
                    ),

                    /// ✅ FIXED BUTTON
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartPage(),
                          ),
                        );
                      },
                      child: const Text("View Cart"),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}