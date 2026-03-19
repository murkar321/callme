import 'package:flutter/material.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/screens/resort_detail.dart';
import '../models/service_product.dart';

class ResortListPage extends StatefulWidget {
  const ResortListPage({super.key});

  @override
  State<ResortListPage> createState() => _ResortListPageState();
}

class _ResortListPageState extends State<ResortListPage> {
  final Color primaryColor = const Color(0xffAE91BA);

  String selectedLocation = 'Virar';

  /// 🔹 SAME DATA
  final Map<String, List<ServiceProduct>> resorts = {
    'Virar': [
      ServiceProduct(
        name: 'Rajhans Water Park',
        price: 700,
        finalPrice: 600,
        discount: 10,
        rating: 3.5,
        imagePath: 'assets/rajhans.jfif',
        time: 'Full Day',
        description: 'Enjoy water rides, swimming & relaxing stay.',
        includes: [
          'Water Park Access',
          'Lockers',
          'A/C & Non A/C Rooms',
          'Bar Facility',
        ],
      ),
      ServiceProduct(
        name: 'Sagar Resort',
        price: 700,
        finalPrice: 600,
        discount: 10,
        rating: 3.8,
        imagePath: 'assets/sagar.jfif',
        time: 'Full Day',
        description: 'Peaceful and relaxing environment.',
        includes: [
          'Lockers',
          'A/C & Non A/C Rooms',
          'Bar Facility',
          'Garden Area',
        ],
      ),
    ],
    'Lonavala': [
      ServiceProduct(
        name: 'Hill View Resort',
        price: 900,
        finalPrice: 800,
        discount: 12,
        rating: 4.2,
        imagePath: 'assets/hillview.jfif',
        time: 'Full Day',
        description: 'Beautiful hill views and relaxing stay.',
        includes: [
          'Swimming Pool',
          'A/C & Non A/C Rooms',
          'Restaurant',
          'Hill View',
        ],
      ),
      ServiceProduct(
        name: 'Green Valley Resort',
        price: 950,
        finalPrice: 850,
        discount: 10,
        rating: 4.3,
        imagePath: 'assets/green valley.jfif',
        time: 'Full Day',
        description: 'Green and peaceful atmosphere.',
        includes: [
          'Swimming Pool',
          'Garden View',
          'Restaurant',
          'Parking',
        ],
      ),
    ],
    'Goa': [
      ServiceProduct(
        name: 'Beach Side Resort',
        price: 1000,
        finalPrice: 900,
        discount: 15,
        rating: 4.5,
        imagePath: 'assets/beachside.jfif',
        time: 'Full Day',
        description: 'Beachfront stay with sea view.',
        includes: [
          'Sea View Rooms',
          'A/C & Non A/C Rooms',
          'Bar Facility',
          'Beach Access',
        ],
      ),
      ServiceProduct(
        name: 'Ocean Paradise Resort',
        price: 1400,
        finalPrice: 1200,
        discount: 15,
        rating: 4.8,
        imagePath: 'assets/ocean.jfif',
        time: 'Full Day',
        description: 'Luxury stay with premium facilities.',
        includes: [
          'Sea View Rooms',
          'Swimming Pool',
          'Bar Facility',
          'Luxury Rooms',
        ],
      ),
    ],
    'Thane': [
      ServiceProduct(
        name: 'Lake View Resort',
        price: 800,
        finalPrice: 700,
        discount: 10,
        rating: 3.9,
        imagePath: 'assets/lakeview.jfif',
        time: 'Full Day',
        description: 'Lake view and peaceful stay.',
        includes: [
          'Lake View',
          'A/C & Non A/C Rooms',
          'Restaurant',
          'Garden Area',
        ],
      ),
      ServiceProduct(
        name: 'Paradise Resort',
        price: 850,
        finalPrice: 750,
        discount: 12,
        rating: 4.0,
        imagePath: 'assets/paradise.jfif',
        time: 'Full Day',
        description: 'Great for parties and outings.',
        includes: [
          'Swimming Pool',
          'A/C Rooms',
          'Restaurant',
          'Party Area',
        ],
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final list = resorts[selectedLocation]!;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// 🔹 APPBAR
      appBar: AppBar(
        title: const Text("Resorts"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          )
        ],
      ),

      body: Row(
        children: [
          /// 🔹 LEFT SIDEBAR
          Container(
            width: 90,
            color: Colors.white,
            child: ListView(
              children: resorts.keys.map((location) {
                final isSelected = location == selectedLocation;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLocation = location;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : null,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: const Icon(Icons.location_on, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          location,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          /// 🔹 RIGHT SIDE CONTENT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                /// TITLE
                Text(
                  selectedLocation,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                /// LIST
                ...list.map((resort) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        /// IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            resort.imagePath,
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(resort.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.orange),
                                  Text(" ${resort.safeRating}"),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text("₹${resort.finalPrice}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Text("₹${resort.price}",
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text("${resort.discount}% OFF",
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resort.includes!.take(2).join(", "),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        /// BUTTON
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ResortDetailPage(service: resort),
                              ),
                            );
                          },
                          child: const Text("Book"),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
