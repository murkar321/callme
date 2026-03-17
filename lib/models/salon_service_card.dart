import 'package:callme/data/salon_data.dart';
import 'package:flutter/material.dart';


class SalonServiceCard extends StatefulWidget {
  const SalonServiceCard({super.key, required SalonService service});

  @override
  State<SalonServiceCard> createState() => _SalonServiceCardState();
}

class _SalonServiceCardState extends State<SalonServiceCard> {
  String selectedCategory = salonCategories[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Services"),
      ),

      body: Row(
        children: [

          /// 🔴 LEFT SIDE CATEGORY LIST (UNCHANGED)
          Container(
            width: 110,
            color: Colors.grey.shade100,
            child: ListView.builder(
              itemCount: salonCategories.length,
              itemBuilder: (context, index) {
                final category = salonCategories[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: selectedCategory == category
                          ? Colors.white
                          : Colors.grey.shade100,
                      border: Border(
                        left: BorderSide(
                          color: selectedCategory == category
                              ? Colors.pink
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: selectedCategory == category
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔵 RIGHT SIDE GRID SERVICES
          Expanded(
            child: ListView(
              children: [
                _buildCategorySection(selectedCategory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 CATEGORY SECTION WITH GRID
  Widget _buildCategorySection(String category) {
    final filteredServices = salonServices
        .where((service) => service.category == category)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// CATEGORY TITLE
          Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// 🔥 GRID VIEW (MAIN FIX)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // ✅ 2 COLUMN GRID
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemBuilder: (context, index) {
              final service = filteredServices[index];
              return _buildServiceCard(service);
            },
          ),
        ],
      ),
    );
  }

  /// 🟢 SERVICE CARD (UNCHANGED DESIGN + BUTTONS)
  Widget _buildServiceCard(SalonService service) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              service.image,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 8),

          /// NAME
          Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          /// TIME
          Text(
            service.time,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 4),

          /// PRICE + ORIGINAL PRICE
          Row(
            children: [
              Text(
                "₹${service.finalPrice}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "₹${service.price}",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// DISCOUNT
          Text(
            "${service.discount}% OFF",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),

          const Spacer(),

          /// 🔥 BUTTONS (AS YOU REQUIRED)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// VIEW DETAILS
              TextButton(
                onPressed: () {
                  // Navigate to details page
                },
                child: const Text("View Details"),
              ),

              /// BOOK NOW
              ElevatedButton(
                onPressed: () {
                  // Booking logic
                },
                child: const Text("Book Now"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}