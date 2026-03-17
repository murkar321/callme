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
  bool? homeVisit;

  @override
  void initState() {
    super.initState();

    /// Ensure categories exist
    if (salonCategories.isNotEmpty) {
      selectedCategory = salonCategories.first;
    } else {
      selectedCategory = "";
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBookingTypeDialog();
    });
  }

  /// POPUP FOR SERVICE TYPE
  void showBookingTypeDialog() {

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Center(
            child: Text("Choose Service Type"),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text("Salon Appointment"),

                  onPressed: () {
                    setState(() {
                      homeVisit = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text("Home Visit"),

                  onPressed: () {
                    setState(() {
                      homeVisit = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
          homeVisit == true
              ? "Salon Services (Home Visit)"
              : "Salon Services (Salon Appointment)",
        ),
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