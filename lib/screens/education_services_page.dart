import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../widgets/education_card.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class EducationServicesPage extends StatefulWidget {
  const EducationServicesPage({super.key});

  @override
  State<EducationServicesPage> createState() =>
      _EducationServicesPageState();
}

class _EducationServicesPageState
    extends State<EducationServicesPage> {

  int selectedIndex = 0;
  String search = "";

  void refresh() => setState(() {});

  /// 🔥 GROUP + SEARCH FILTER (SMART)
  Map<String, List<EducationService>> groupByCategory() {
    final Map<String, List<EducationService>> map = {};

    for (var service in educationServices) {
      final matchSearch =
          service.name.toLowerCase().contains(search.toLowerCase()) ||
          service.category.toLowerCase().contains(search.toLowerCase());

      if (search.isNotEmpty && !matchSearch) continue;

      map.putIfAbsent(service.category, () => []);
      map[service.category]!.add(service);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByCategory();
    final categories = groupedData.keys.toList()..sort();

    /// 🛑 EMPTY STATE
    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Education Services")),
        body: const Center(child: Text("No services found")),
      );
    }

    /// ⚠️ SAFE INDEX FIX
    if (selectedIndex >= categories.length) {
      selectedIndex = 0;
    }

    final selectedCategory = categories[selectedIndex];
    final services = groupedData[selectedCategory]!;

    final totalItems = Cart.getTotalItems("Education");

    return Scaffold(
      backgroundColor: Colors.grey[100],

      /// 🔝 APP BAR
      appBar: AppBar(
        title: const Text("Education Services"),
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH BAR (IMPROVED UI)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search courses or category...",
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                  selectedIndex = 0;
                });
              },
            ),
          ),

          Expanded(
            child: Row(
              children: [

                /// 📂 LEFT CATEGORY PANEL (IMPROVED)
                Container(
                  width: MediaQuery.of(context).size.width * 0.28,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedIndex == index;

                      final firstImage =
                          groupedData[category]!.first.image;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage:
                                    AssetImage(firstImage),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  category,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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

                /// 📄 RIGHT PANEL (SERVICES)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        8, 8, 8, 80),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return EducationServiceCard(
                        service: services[index],
                        onUpdate: refresh,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// 🟣 BOTTOM CART BAR (IMPROVED)
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFAE91BA),
                ),
                child: Row(
                  children: [
                    Text(
                      "$totalItems courses selected",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartPage(
                              service: "Education",
                              serviceName: '',
                              cart: [],
                            ),
                          ),
                        ).then((_) => refresh());
                      },
                      child: const Text(
                        "View Courses",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}