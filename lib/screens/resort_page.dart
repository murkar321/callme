import 'package:flutter/material.dart';

import '../data/resorts_data.dart';
import '../widgets/resort_card.dart';

class ResortPage extends StatefulWidget {
  const ResortPage({
    super.key,
    required List<dynamic> resorts,
  });

  @override
  State<ResortPage> createState() => _ResortPageState();
}

class _ResortPageState extends State<ResortPage> {
  /// ================= SEARCH CONTROLLER =================
  final TextEditingController searchController = TextEditingController();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ THEME FIX: all backgrounds/text/borders below now branch on isDark
    // instead of using hardcoded Colors.white / Colors.grey.shade100.
    final Color scaffoldBg =
        isDark ? const Color(0xFF121016) : Colors.grey.shade100;
    final Color cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText =
        isDark ? Colors.white54 : Colors.grey.shade600;
    final Color chipUnselectedBg =
        isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color chipUnselectedBorder =
        isDark ? Colors.white24 : Colors.grey.shade300;
    final Color shadowColor =
        Colors.black.withOpacity(isDark ? 0.35 : 0.05);

    /// ================= FILTERED RESORTS =================
    final List<Resort> filteredResorts = resorts.where((resort) {
      final searchText = searchController.text.trim().toLowerCase();

      /// SEARCH FILTER
      final matchesSearch = resort.name.toLowerCase().contains(searchText) ||
          resort.location.toLowerCase().contains(searchText);

      /// LOCATION FILTER
      final matchesLocation = selectedLocation == "All"
          ? true
          : resort.location
              .toLowerCase()
              .contains(selectedLocation.toLowerCase());

      return matchesSearch && matchesLocation;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    hintText: "Search resorts or location",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    prefixIcon: Icon(Icons.search, color: secondaryText),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            /// ================= LOCATION CHIPS =================
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: locations.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = selectedLocation == location;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLocation = location;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : chipUnselectedBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              isSelected ? Colors.blue : chipUnselectedBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: isSelected ? Colors.white : primaryText,
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

            /// ================= RESORT LIST =================
            Expanded(
              child: filteredResorts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.holiday_village,
                            size: 75,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "${filteredResorts.length} Resorts not available",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Try another search or location",
                            style: TextStyle(color: secondaryText),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20, top: 4),
                      itemCount: filteredResorts.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 2);
                      },
                      itemBuilder: (context, index) {
                        final resort = filteredResorts[index];
                        return ResortCard(resort: resort);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}