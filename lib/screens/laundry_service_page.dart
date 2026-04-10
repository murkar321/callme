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

  /// 🧺 FABRIC BOTTOM SHEET
  void showFabricPopup(ServiceProduct product) {

    int selectedPrice = 50;
    String selectedFabric = "Cotton";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setModalState) {

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.all(16),

              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),

              child: Column(
                children: [

                  /// HANDLE
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// HEADER
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      const Text(
                        "Laundry Guide",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),

                  const Divider(),

                  /// FABRICS
                  Expanded(
                    child: ListView(
                      children: [
                        fabricTile("Cotton", 50, selectedFabric, setModalState),
                        fabricTile("Silk", 70, selectedFabric, setModalState),
                        fabricTile("Wool", 80, selectedFabric, setModalState),
                        fabricTile("Denim", 60, selectedFabric, setModalState),
                        fabricTile("Curtains", 90, selectedFabric, setModalState),
                        fabricTile("Shoes", 100, selectedFabric, setModalState),
                      ],
                    ),
                  ),

                  /// TOTAL
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "Total ₹${product.calculatedFinalPrice + selectedPrice}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// ADD TO CART
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {

                        Cart.addLaundry(
                          id: product.id,
                          name: "${product.name} ($selectedFabric)",
                          price: product.calculatedFinalPrice + selectedPrice,
                          category: selectedCategory,
                          image: product.imagePath,
                        );

                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFAE91BA),
                      ),
                      child: const Text(
                        "ADD TO CART",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// VIEW CART
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {

                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CartPage(
                              service: "Laundry",
                              serviceName: "Laundry",
                              cart: Cart.getItems("Laundry"),
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: const Text("VIEW CART"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget fabricTile(
    String name,
    int price,
    String selected,
    StateSetter setModalState,
  ) {
    return ListTile(
      title: Text(name),
      trailing: Text("₹$price"),
      leading: Radio(
        value: name,
        groupValue: selected,
        onChanged: (val) {
          setModalState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    int cartCount = Cart.totalItems("Laundry");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Laundry"),
        backgroundColor: const Color(0xFFAE91BA),
        centerTitle: true,
      ),

      body: Row(
        children: [

          /// 🔵 LEFT CIRCLE CATEGORY
          Container(
            width: 90,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: laundryData.keys.map((category) {

                bool isSelected =
                    selectedCategory == category;

                String image =
                    laundryData[category]!.first.imagePath;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isSelected
                              ? const Color(0xFFAE91BA)
                              : Colors.grey.shade200,

                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(image),
                          ),
                        ),

                        const SizedBox(height: 6),

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
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          /// 🧾 RIGHT GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount:
                  laundryData[selectedCategory]!.length,

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),

              itemBuilder: (context, index) {

                final product =
                    laundryData[selectedCategory]![index];

                return LaundryCard(
                  product: product,
                  category: selectedCategory,

                  onAdd: () {
                    showFabricPopup(product);
                  },

                  onView: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LaundryDetailPage(
                          product: product,
                          category: selectedCategory,
                          serviceName: "Laundry",
                        ),
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
                        cart: Cart.getItems("Laundry"),
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