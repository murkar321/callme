import 'package:flutter/material.dart';

import '../data/resorts_data.dart';
import '../widgets/resort_card.dart';

class ResortPage extends StatefulWidget {

  const ResortPage({
    super.key, required List<dynamic> resorts,
  });

  @override
  State<ResortPage> createState() =>
      _ResortPageState();
}

class _ResortPageState
    extends State<ResortPage> {

  /// ================= SEARCH CONTROLLER =================
  final TextEditingController
      searchController =
      TextEditingController();

  /// ================= LOCATION FILTERS =================
  final List<String> locations = [

    "All",

    "Arnala",
    "Rajodi",
    "Navapur",
    "Agashi",
    "Manvel Pada",
    "Virar East",
    "Virar West",
  ];

  String selectedLocation = "All";

  @override
  void dispose() {

    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// ================= FILTERED RESORTS =================
    final List<Resort> filteredResorts =

        resortList.where((resort) {

      final searchText =
          searchController.text
              .trim()
              .toLowerCase();

      /// SEARCH FILTER
      final matchesSearch =

          resort.name
              .toLowerCase()
              .contains(searchText)

          ||

          resort.location
              .toLowerCase()
              .contains(searchText);

      /// LOCATION FILTER
      final matchesLocation =

          selectedLocation == "All"

              ? true

              : resort.location
                  .toLowerCase()
                  .contains(
                    selectedLocation
                        .toLowerCase(),
                  );

      return matchesSearch &&
          matchesLocation;

    }).toList();

    return Scaffold(

      backgroundColor:
          Colors.grey.shade100,

      appBar: AppBar(

        elevation: 0,

        centerTitle: true,

        backgroundColor: Colors.blue,

        title: const Text(
          "Virar Resorts",

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(

        child: Column(
          children: [

            /// ================= SEARCH BAR =================
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                12,
              ),

              child: Container(

                height: 56,

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),

                      blurRadius: 10,

                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),

                child: TextField(

                  controller:
                      searchController,

                  onChanged: (_) {
                    setState(() {});
                  },

                  decoration:
                      InputDecoration(

                    hintText:
                        "Search resorts or location",

                    hintStyle: TextStyle(
                      color:
                          Colors.grey.shade500,
                    ),

                    prefixIcon: const Icon(
                      Icons.search,
                    ),

                    border:
                        InputBorder.none,

                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            /// ================= LOCATION CHIPS =================
            SizedBox(

              height: 50,

              child: ListView.separated(

                scrollDirection:
                    Axis.horizontal,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                ),

                itemCount:
                    locations.length,

                separatorBuilder:
                    (context, index) {

                  return const SizedBox(
                    width: 10,
                  );
                },

                itemBuilder:
                    (context, index) {

                  final location =
                      locations[index];

                  final isSelected =
                      selectedLocation ==
                          location;

                  return GestureDetector(

                    onTap: () {

                      setState(() {

                        selectedLocation =
                            location;
                      });
                    },

                    child:
                        AnimatedContainer(

                      duration:
                          const Duration(
                        milliseconds: 250,
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),

                      decoration:
                          BoxDecoration(

                        color: isSelected
                            ? Colors.blue
                            : Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),

                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey
                                  .shade300,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                                    0.03),

                            blurRadius: 6,

                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),

                      child: Center(
                        child: Text(
                          location,

                          style: TextStyle(

                            color: isSelected
                                ? Colors.white
                                : Colors.black87,

                            fontWeight:
                                FontWeight.w600,

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

            /// ================= RESORT LIST =================
            Expanded(

              child:
                  filteredResorts.isEmpty

                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [

                              Icon(
                                Icons
                                    .holiday_village,

                                size: 75,

                                color: Colors
                                    .grey.shade400,
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              Text(
                                "No Resorts Found",

                                style: TextStyle(
                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  color: Colors
                                      .grey.shade700,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                "Try another search or location",

                                style: TextStyle(
                                  color: Colors
                                      .grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )

                      : ListView.separated(

                          physics:
                              const BouncingScrollPhysics(),

                          padding:
                              const EdgeInsets.only(
                            bottom: 20,
                            top: 4,
                          ),

                          itemCount:
                              filteredResorts
                                  .length,

                          separatorBuilder:
                              (context, index) {

                            return const SizedBox(
                              height: 2,
                            );
                          },

                          itemBuilder:
                              (context, index) {

                            final resort =
                                filteredResorts[
                                    index];

                            return ResortCard(
                              resort: resort,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}