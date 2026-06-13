import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import '../widgets/hotel_card.dart';

class HotelServicePage extends StatefulWidget {
  const HotelServicePage({super.key});

  @override
  State<HotelServicePage> createState() => _HotelServicePageState();
}

class _HotelServicePageState extends State<HotelServicePage> {
  final TextEditingController searchController = TextEditingController();
  String selectedCity = "All";

  List<String> get cities {
    final list = hotels.map((e) => e.city).toSet().toList();
    list.sort();
    return ["All", ...list];
  }

  List<HotelData> get filtered {
    final searchText = searchController.text.trim().toLowerCase();
    return hotels.where((hotel) {
      final matchCity = selectedCity == "All" || hotel.city == selectedCity;
      final matchSearch =
          hotel.name.toLowerCase().contains(searchText) ||
          hotel.city.toLowerCase().contains(searchText);
      return matchCity && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.red,
        title: const Text(
          "Hotels",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search hotels or city...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            /// ── CITY FILTER CHIPS ──
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = selectedCity == city;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCity = city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              isSelected ? Colors.red : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          city,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// ── HOTEL LIST ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel,
                              size: 75, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Text(
                            "No hotels available",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Try another search or city",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20, top: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        return HotelCard(hotel: filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}