import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'hotel_detail_page.dart';
import '../models/hotel_card.dart';

class HotelServicePage extends StatefulWidget {
  const HotelServicePage({super.key});

  @override
  State<HotelServicePage> createState() => _HotelServicePageState();
}

class _HotelServicePageState extends State<HotelServicePage> {
  int selectedCategoryIndex = 0;
  int selectedCityIndex = 0;
  String search = "";

  final List<Map<String, Object>> categories = [
    {"name": "Junior Suite", "icon": Icons.hotel},
    {"name": "Executive Suite", "icon": Icons.apartment},
    {"name": "Family Suite", "icon": Icons.family_restroom},
    {"name": "Deluxe Suite", "icon": Icons.star},
    {"name": "Mini Suite", "icon": Icons.king_bed},
  ];

  List<String> get cities {
    final list = hotels.map((e) => e.city).toSet().toList();
    list.sort();
    return ["All", ...list];
  }

  List<HotelRoom> get filtered {
    final category = categories[selectedCategoryIndex]["name"];
    final city = cities[selectedCityIndex];

    return hotels.where((hotel) {
      final matchCategory = hotel.category == category;
      final matchCity = city == "All" || hotel.city == city;
      final matchSearch =
          hotel.hotelName.toLowerCase().contains(search.toLowerCase()) ||
              hotel.city.toLowerCase().contains(search.toLowerCase());

      return matchCategory && matchCity && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Hotels"),
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (val) => setState(() => search = val),
              decoration: InputDecoration(
                hintText: "Search hotels...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🌆 CITY FILTER
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final isSelected = selectedCityIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => selectedCityIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      cities[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 5),

          /// 🔥 MAIN
          Expanded(
            child: Row(
              children: [
                /// LEFT PANEL
                Container(
                  width: 90,
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedCategoryIndex == index;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedCategoryIndex = index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    isSelected ? Colors.blue : Colors.white,
                                child: Icon(
                                  categories[index]["icon"] as IconData,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                categories[index]["name"] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// RIGHT GRID (FIXED)
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("No hotels found"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 3 : 2,

                            /// 🔥 MAIN FIX (NO OVERFLOW)
                            mainAxisExtent: 240,

                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final hotel = filtered[index];

                            return HotelCard(
                              hotel: hotel,
                              onView: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HotelDetailPage(hotel: hotel),
                                  ),
                                );
                              },
                              onBook: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HotelDetailPage(hotel: hotel),
                                  ),
                                );
                              },
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
