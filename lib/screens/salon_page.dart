import 'package:flutter/material.dart';
import 'package:callme/data/salon_data.dart';
import 'package:callme/models/salon_service_card.dart';
import 'package:callme/widgets/salon_category_menu.dart';

class SalonPage extends StatefulWidget {
  const SalonPage({super.key});

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  late String selectedCategory;
  bool homeVisit = false; // ✅ Default (no popup)

  @override
  void initState() {
    super.initState();

    /// Set default category
    if (salonCategories.isNotEmpty) {
      selectedCategory = salonCategories.first;
    } else {
      selectedCategory = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    /// FILTER SERVICES
    List<SalonService> filtered = salonServices
        .where((service) => service.category == selectedCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          homeVisit
              ? "Salon Services (Home Visit)"
              : "Salon Services (Salon Appointment)",
        ),

        /// 🔹 Optional toggle button (instead of popup)
        actions: [
          IconButton(
            icon: Icon(
              homeVisit ? Icons.home : Icons.store,
            ),
            onPressed: () {
              setState(() {
                homeVisit = !homeVisit;
              });
            },
          )
        ],
      ),
      body: Row(
        children: [
          /// LEFT CATEGORY MENU
          SalonCategoryMenu(
            categories: salonCategories,
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
          ),

          /// RIGHT SERVICE LIST
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text("No services available"),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return SalonServiceCard(
                        service: filtered[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
