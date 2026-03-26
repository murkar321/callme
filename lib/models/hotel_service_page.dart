import 'package:callme/models/hotel_card.dart';
import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import '../models/cart.dart';
import 'hotel_detail_page.dart';
import 'cart_page.dart';

class HotelServicePage extends StatefulWidget {
  const HotelServicePage({super.key});

  @override
  State<HotelServicePage> createState() => _HotelServicePageState();
}

class _HotelServicePageState extends State<HotelServicePage> {
  int selectedCategoryIndex = 0;
  int selectedCityIndex = 0;
  String search = "";

  /// ✅ CATEGORY LIST
  final List<Map<String, Object>> categories = [
    {"name": "Junior Suite", "icon": Icons.hotel},
    {"name": "Executive Suite", "icon": Icons.apartment},
    {"name": "Family Suite", "icon": Icons.family_restroom},
    {"name": "Deluxe Suite", "icon": Icons.star},
    {"name": "Mini Suite", "icon": Icons.king_bed},
  ];

  /// ✅ DYNAMIC CITY LIST
  List<String> get cities {
    final list = hotels.map((e) => e.city).toSet().toList();
    list.sort();
    return ["All"] + list;
  }

  /// ✅ FILTER LOGIC (CATEGORY + CITY + SEARCH)
  List<HotelRoom> get filtered {
    final String category =
        categories[selectedCategoryIndex]["name"] as String;

    final String city = cities[selectedCityIndex];

    return hotels.where((hotel) {
      final matchCategory = hotel.category == category;

      final matchCity =
          city == "All" || hotel.city == city;

      final matchSearch =
          hotel.hotelName.toLowerCase().contains(search) ||
              hotel.city.toLowerCase().contains(search);

      return matchCategory && matchCity && matchSearch;
    }).toList();
  }

  /// ✅ ADD TO CART
  void addToCart(HotelRoom hotel) {
    Cart.addItem(
      id: hotel.id,
      name: hotel.hotelName,
      price: hotel.price,
      service: "Hotel",
      category: hotel.category,
      image: hotel.image,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// ================= APP BAR =================
      appBar: AppBar(
        title: const Text("Hotels"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CartPage(service: "Hotel", serviceName: '', cart: [],),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),

              /// CART BADGE
              if (Cart.getTotalItems("Hotel") > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      Cart.getTotalItems("Hotel").toString(),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),

      /// ================= BODY =================
      body: Column(
        children: [
          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search hotels...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🌆 CITY FILTER (HORIZONTAL)
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final isSelected =
                    selectedCityIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCityIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      cities[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.blue,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 5),

          /// 🔥 MAIN CONTENT
          Expanded(
            child: Row(
              children: [
                /// ================= LEFT CATEGORY PANEL =================
                Container(
                  width: 90,
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final isSelected =
                          selectedCategoryIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryIndex = index;
                          });
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 10),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                padding:
                                    const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.grey.shade300,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  categories[index]["icon"]
                                      as IconData,
                                  size: 22,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// TEXT FIX (NO OVERFLOW)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 4),
                                child: Text(
                                  categories[index]["name"]
                                      as String,
                                  textAlign:
                                      TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow
                                      .ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// ================= RIGHT GRID =================
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text("No hotels found"),
                        )
                      : GridView.builder(
                          padding:
                              const EdgeInsets.all(10),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final hotel = filtered[index];

                            return HotelCard(
                              hotel: hotel,

                              /// VIEW DETAILS
                              onView: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HotelDetailPage(
                                            hotel: hotel),
                                  ),
                                );
                              },

                              /// ADD TO CART
                              onAddCart: () =>
                                  addToCart(hotel),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}