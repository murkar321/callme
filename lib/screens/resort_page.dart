import 'package:flutter/material.dart';
import 'package:callme/widgets/resort_card.dart';
import '../data/resorts_data.dart';

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

    List<Resort> filteredResorts =
        getResortsByCity(selectedCity)
            .where((resort) =>
                resort.name
                    .toLowerCase()
                    .contains(searchText.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resorts"),
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Resort...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
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

                /// LEFT CITY PANEL
                Container(
                  width: 120,
                  color: Colors.grey.shade200,

                  child: ListView.builder(
                    itemCount: cities.length,
                    itemBuilder: (context, index) {

                      final city = cities[index];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCity = city;
                          });
                        },

                        child: Container(
                          margin:
                              const EdgeInsets.all(8),

                          padding:
                              const EdgeInsets.all(10),

                          decoration: BoxDecoration(
                            color:
                                selectedCity == city
                                    ? Colors.blue
                                    : Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(12),

                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .grey.shade300,
                                blurRadius: 3,
                              )
                            ],
                          ),

                          child: Center(
                            child: Text(
                              city,
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    selectedCity ==
                                            city
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// RIGHT RESORT LIST
                Expanded(
                  child: filteredResorts.isEmpty
                      ? const Center(
                          child: Text(
                            "No Resorts Found",
                            style: TextStyle(
                                fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(10),

                          itemCount:
                              filteredResorts.length,

                          itemBuilder:
                              (context, index) {

                            return ResortCard(
                              resort:
                                  filteredResorts[
                                      index],
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