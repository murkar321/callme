import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/models/luandary_detail_page.dart';
import '../data/laundary_data.dart';
import '../models/service_product.dart';
import '../widgets/laundary_card.dart';

class LaundryServicePage extends StatefulWidget {
  const LaundryServicePage({super.key});

  @override
  State<LaundryServicePage> createState() =>
      _LaundryServicePageState();
}

class _LaundryServicePageState
    extends State<LaundryServicePage> {

  final Map<String, List<ServiceProduct>> laundryData =
      serviceProducts['Laundry']!;

  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = laundryData.keys.first;
  }

  IconData getIcon(String category) {
    switch (category) {
      case "Washing":
        return Icons.local_laundry_service;
      case "Dry Cleaning":
        return Icons.dry_cleaning;
      case "Ironing":
        return Icons.iron;
      case "Curtain Cleaning":
        return Icons.curtains;
      case "Shoe Cleaning":
        return Icons.sports_soccer;
      case "Bedsheet Cleaning":
        return Icons.bed;
      default:
        return Icons.local_laundry_service;
    }
  }

  @override
  Widget build(BuildContext context) {

    int cartCount = Cart.totalItems("Laundry");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Laundry"),
        centerTitle: true,
        backgroundColor: const Color(0xFFAE91BA),
      ),

      body: Row(
        children: [

          /// LEFT MENU
          Container(
            width: MediaQuery.of(context).size.width * 0.28,
            color: Colors.white,
            child: ListView(
              children: laundryData.keys.map((category) {

                bool isSelected =
                    selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFAE91BA)
                              .withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected
                              ? const Color(0xFFAE91BA)
                              : Colors.grey.shade200,
                          child: Icon(
                            getIcon(category),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          category,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFFAE91BA)
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          /// RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount:
                  laundryData[selectedCategory]!.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {

                final product =
                    laundryData[selectedCategory]![index];

                return LaundryCard(
                  product: product,
                  category: selectedCategory,

                  onAdd: () async {

                    await showDialog(
                      context: context,
                      builder: (_) => LaundryDetailPage(
                        product: product,
                        category: selectedCategory,
                        serviceName: "Laundry",
                      ),
                    );

                    setState(() {});
                  },

                  onView: () {
                    showDialog(
                      context: context,
                      builder: (_) => LaundryDetailPage(
                        product: product,
                        category: selectedCategory,
                        serviceName: "Laundry",
                      ),
                    );
                  }, onTap: () {  },
                );
              },
            ),
          ),
        ],
      ),

      /// 🛒 CART BAR
      bottomNavigationBar: cartCount > 0
          ? Container(
              height: 60,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFAE91BA),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(
                        service: "Laundry",
                        serviceName: "Laundry",
                        cart:
                            Cart.getItems("Laundry"),
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [

                    Padding(
                      padding:
                          const EdgeInsets.all(12),
                      child: Text(
                        "$cartCount items added",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.all(12),
                      child: Text(
                        "VIEW CART",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
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