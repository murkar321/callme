import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../widgets/resort_card.dart';

class ResortPage extends StatefulWidget {
  const ResortPage({super.key, required List<dynamic> resorts});

  @override
  State<ResortPage> createState() => _ResortPageState();
}

class _ResortPageState extends State<ResortPage> {
  String selectedCity = cities.first;
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    List<String> filteredCities = cities
        .where((city) => city.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    List<Resort> filteredResorts = getResortsByCity(selectedCity);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Resorts"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// 🔍 SEARCH CITY
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search City...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          Expanded(
            child: Row(
              children: [
                /// 🏙️ LEFT CITY PANEL
                Container(
                  width: 110,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = filteredCities[index];
                      bool isSelected = selectedCity == city;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCity = city;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Column(
                            children: [
                              /// 🔵 CIRCLE CITY
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// CITY NAME
                              Text(
                                city,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected ? Colors.blue : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// 🏨 RIGHT RESORT LIST
                Expanded(
                  child: filteredResorts.isEmpty
                      ? const Center(
                          child: Text(
                            "No Resorts Available",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredResorts.length,
                          itemBuilder: (context, index) {
                            return ResortCard(
                              resort: filteredResorts[index],
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
