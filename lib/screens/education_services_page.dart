import 'package:callme/models/cart_page.dart';
import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../widgets/education_card.dart';
import '../models/cart.dart';


class EducationServicesPage extends StatefulWidget {
  const EducationServicesPage({super.key});

  @override
  State<EducationServicesPage> createState() =>
      _EducationServicesPageState();
}

class _EducationServicesPageState
    extends State<EducationServicesPage> {
  int selectedIndex = 0;

  void refresh() => setState(() {});

  /// 🔹 GROUP DATA (NO DATA CHANGE NEEDED)
  Map<String, List<EducationService>> groupByCategory() {
    final Map<String, List<EducationService>> map = {};

    for (var service in educationServices) {
      if (!map.containsKey(service.category)) {
        map[service.category] = [];
      }
      map[service.category]!.add(service);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = groupByCategory();
    final categories = groupedData.keys.toList();

    final selectedCategory = categories[selectedIndex];
    final services = groupedData[selectedCategory]!;

    final totalItems = Cart.getTotalItems("Education");
    final totalPrice = Cart.getTotal("Education");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Education Services"),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [

                  /// 🔹 LEFT CATEGORY PANEL
                  Container(
                    width: 95,
                    color: Colors.grey.shade100,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final categoryName = categories[index];
                        final isSelected =
                            selectedIndex == index;

                        final firstImage =
                            groupedData[categoryName]!
                                .first
                                .image;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
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
                                  radius: 24,
                                  backgroundImage:
                                      AssetImage(firstImage),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4),
                                  child: Text(
                                    categoryName,
                                    textAlign:
                                        TextAlign.center,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
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

                  /// 🔹 RIGHT SERVICE LIST
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        10,
                        10,
                        totalItems > 0 ? 90 : 10,
                      ),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];

                        return EducationServiceCard(
                          service: service,
                          onUpdate: refresh,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 CART BAR
            if (totalItems > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                color: const Color.fromARGB(255, 181, 122, 204),
                child: Row(
                  children: [
                    Text(
                      "$totalItems items",
                      style: const TextStyle(
                          color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      "₹$totalPrice",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// 🔥 VIEW CART FIXED
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartPage(
                              serviceName: "Education",
                              cart: Cart.getItems("Education"), service: 'Education',
                            ),
                          ),
                        ).then((_) => refresh());
                      },
                      child: const Text("View Cart"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}