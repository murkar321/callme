import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_product.dart';
import '../models/cart_provider.dart';
import 'resort_detail.dart';

class ResortListPage extends StatefulWidget {
  const ResortListPage({super.key});

  @override
  State<ResortListPage> createState() => _ResortListPageState();
}

class _ResortListPageState extends State<ResortListPage> {
  final Color primaryColor = const Color(0xffAE91BA);

  String selectedLocation = 'Virar';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  final Map<String, List<ServiceProduct>> resorts = {
    'Vasai': [
      ServiceProduct(
        name: 'Rajhans Water Park',
        price: 700,
        finalPrice: 600,
        discount: 10,
        rating: 3.5,
        imagePath: 'assets/rajhans.jfif',
        time: 'Full Day',
        description: 'Enjoy water rides, swimming & relaxing stay.',
        includes: [
          'Water Park Access',
          'Lockers',
          'A/C & Non A/C Rooms',
          'Bar Facility',
        ],
        id: '',
        service: '',
      ),
      ServiceProduct(
        name: 'Sagar Resort',
        price: 700,
        finalPrice: 600,
        discount: 10,
        rating: 3.8,
        imagePath: 'assets/sagar.jfif',
        time: 'Full Day',
        description: 'Peaceful and relaxing environment.',
        includes: [
          'Lockers',
          'A/C & Non A/C Rooms',
          'Bar Facility',
          'Garden Area',
        ],
        id: '',
        service: '',
      ),
    ],
    'Virar': [
      ServiceProduct(
        name: 'Hill View Resort',
        price: 900,
        finalPrice: 800,
        discount: 12,
        rating: 4.2,
        imagePath: 'assets/hillview.jfif',
        time: 'Full Day',
        description: 'Beautiful hill views and relaxing stay.',
        includes: [
          'Swimming Pool',
          'A/C & Non A/C Rooms',
          'Restaurant',
          'Hill View',
        ],
        id: '',
        service: '',
      ),
      ServiceProduct(
        name: 'Green Valley Resort',
        price: 950,
        finalPrice: 850,
        discount: 10,
        rating: 4.3,
        imagePath: 'assets/green valley.jfif',
        time: 'Full Day',
        description: 'Green and peaceful atmosphere.',
        includes: [
          'Swimming Pool',
          'Garden View',
          'Restaurant',
          'Parking',
        ],
        id: '',
        service: '',
      ),
    ],
    'Safale': [
      ServiceProduct(
        name: 'Beach Side Resort',
        price: 1000,
        finalPrice: 900,
        discount: 15,
        rating: 4.5,
        imagePath: 'assets/beachside.jfif',
        time: 'Full Day',
        description: 'Beachfront stay with sea view.',
        includes: [
          'Sea View Rooms',
          'A/C & Non A/C Rooms',
          'Bar Facility',
          'Beach Access',
        ],
        id: '',
        service: '',
      ),
      ServiceProduct(
        name: 'Ocean Paradise Resort',
        price: 1400,
        finalPrice: 1200,
        discount: 15,
        rating: 4.8,
        imagePath: 'assets/ocean.jfif',
        time: 'Full Day',
        description: 'Luxury stay with premium facilities.',
        includes: [
          'Sea View Rooms',
          'Swimming Pool',
          'Bar Facility',
          'Luxury Rooms',
        ],
        id: '',
        service: '',
      ),
    ],
    'Palghar': [
      ServiceProduct(
        name: 'Lake View Resort',
        price: 800,
        finalPrice: 700,
        discount: 10,
        rating: 3.9,
        imagePath: 'assets/lakeview.jfif',
        time: 'Full Day',
        description: 'Lake view and peaceful stay.',
        includes: [
          'Lake View',
          'A/C & Non A/C Rooms',
          'Restaurant',
          'Garden Area',
        ],
        id: '',
        service: '',
      ),
      ServiceProduct(
        name: 'Paradise Resort',
        price: 850,
        finalPrice: 750,
        discount: 12,
        rating: 4.0,
        imagePath: 'assets/paradise.jfif',
        time: 'Full Day',
        description: 'Great for parties and outings.',
        includes: [
          'Swimming Pool',
          'A/C Rooms',
          'Restaurant',
          'Party Area',
        ],
        id: '',
        service: '',
      ),
    ],
    'Nalasopara': [
      ServiceProduct(
        name: 'Lake View Resort',
        price: 800,
        finalPrice: 700,
        discount: 10,
        rating: 3.9,
        imagePath: 'assets/lakeview.jfif',
        time: 'Full Day',
        description: 'Lake view and peaceful stay.',
        includes: [
          'Lake View',
          'A/C & Non A/C Rooms',
          'Restaurant',
          'Garden Area',
        ],
        id: '',
        service: '',
      ),
      ServiceProduct(
        name: 'Paradise Resort',
        price: 850,
        finalPrice: 750,
        discount: 12,
        rating: 4.0,
        imagePath: 'assets/paradise.jfif',
        time: 'Full Day',
        description: 'Great for parties and outings.',
        includes: [
          'Swimming Pool',
          'A/C Rooms',
          'Restaurant',
          'Party Area',
        ],
        id: '',
        service: '',
      ),
    ],
  };

  /// ✅ CLEAN FILTER
  List<ServiceProduct> getFilteredList() {
    if (searchQuery.isEmpty) {
      return resorts[selectedLocation] ?? [];
    }

    return resorts.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
        .expand((e) => e.value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final list = getFilteredList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      /// 🔹 APPBAR
      appBar: AppBar(
        title: const Text("Resorts"),
        backgroundColor: primaryColor,
      ),

      /// 🔹 BODY
      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() {
                    searchQuery = val;
                  });
                });
              },
              decoration: InputDecoration(
                hintText: "Enter Your City",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// LOCATION CHIPS
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: resorts.keys.map((loc) {
                final isSelected = loc == selectedLocation;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLocation = loc;
                      searchQuery = '';
                      searchController.clear();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loc,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color.fromARGB(255, 189, 166, 219),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          /// MAIN
          Expanded(
            child: Row(
              children: [
                /// LEFT PANEL
                SizedBox(
                  width: 90,
                  child: ListView(
                    children: const [
                      _SideItem("Rooms"),
                      _SideItem("Lockers"),
                      _SideItem("Bar"),
                      _SideItem("Event Hall"),
                      _SideItem("Costume"),
                    ],
                  ),
                ),

                /// RIGHT GRID
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text("No Data"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: list.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, i) {
                            return _Card(item: list[i]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// CART BAR
      bottomNavigationBar: cart.count == 0
          ? null
          : Container(
              padding: const EdgeInsets.all(15),
              color: Colors.blue,
              child: Text(
                "View Cart (${cart.count})",
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}

/// LEFT ITEM
class _SideItem extends StatelessWidget {
  final String title;
  const _SideItem(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const CircleAvatar(radius: 18),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// CARD (NO STACK = NO OVERFLOW)
class _Card extends StatelessWidget {
  final ServiceProduct item;
  const _Card({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isAdded = cart.isAdded(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),

          /// BUTTONS ROW (SAFE)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    cart.toggle(item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdded
                        ? Colors.green
                        : const Color.fromARGB(255, 153, 149, 149),
                  ),
                  child: Text(isAdded ? "Added" : "Add"),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResortDetailPage(service: item),
                      ),
                    );
                  },
                  child: const Text("View"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
