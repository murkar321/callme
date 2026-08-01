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

    const Color themeColor = Color(0xFFAE91BA);

    // ── DARK MODE AWARENESS ────────────────────────────────────────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF121016) : Colors.grey[100]!;
    final Color panelBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color searchFieldBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color categoryTextColor = isDark ? Colors.white70 : Colors.black87;
    final Color categoryTextColorSelected = isDark ? Colors.white : Colors.black87;
    final Color inputTextColor = isDark ? Colors.white : Colors.black87;
    final Color hintTextColor = isDark ? Colors.white38 : Colors.black38;

    /// 🛑 EMPTY STATE
    if (categories.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(title: const Text("Education Services")),
        body: Center(
          child: Text(
            "No services found",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      );
    }

    /// ⚠️ SAFE INDEX FIX
    if (selectedIndex >= categories.length) {
      selectedIndex = 0;
    }

    final selectedCategory = categories[selectedIndex];
    final services = groupedData[selectedCategory]!;

    final totalItems = Cart.getTotalItems("Education");
    final totalPrice = Cart.getTotal("Education");

    return Scaffold(
      backgroundColor: scaffoldBg,

      /// 🔝 APP BAR
      appBar: AppBar(
        title: const Text("Education Services"),
        backgroundColor: themeColor,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          /// 🛒 CART BADGE — top-right of AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: totalItems > 0
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartPage(
                            service: "Education",
                            serviceName: "Education",
                            cart: [], providerId: '',
                          ),
                        ),
                      ).then((_) => refresh());
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                    size: 26,
                  ),
                  if (totalItems > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            totalItems > 99
                                ? "99+"
                                : "$totalItems",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              style: TextStyle(color: inputTextColor),
              cursorColor: themeColor,
              decoration: InputDecoration(
                hintText: "Search courses or category...",
                hintStyle: TextStyle(color: hintTextColor),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: searchFieldBg,
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

                /// 📂 LEFT CATEGORY PANEL
                Container(
                  width: MediaQuery.of(context).size.width * 0.28,
                  color: panelBg,
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
                                ? themeColor.withOpacity(isDark ? 0.22 : 0.12)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? themeColor
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
                                    color: isSelected
                                        ? categoryTextColorSelected
                                        : categoryTextColor,
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
                    padding: EdgeInsets.fromLTRB(
                      8,
                      8,
                      8,
                      totalItems > 0 ? 110 : 20,
                    ),
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

      /// 🟣 BOTTOM CART BAR — disappears instantly when cart is empty
      bottomNavigationBar: totalItems > 0
          ? SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: themeColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$totalItems course${totalItems == 1 ? '' : 's'} • ₹$totalPrice",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartPage(
                                service: "Education",
                                serviceName: "Education",
                                cart: [], providerId: '',
                              ),
                            ),
                          ).then((_) => refresh());
                        },
                        child: const Text("View Cart"),
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