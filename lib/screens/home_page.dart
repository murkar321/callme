import 'package:flutter/material.dart';
import 'package:callme/models/service_category.dart';
import 'package:callme/screens/service_detail_page.dart';
import 'package:callme/screens/real_estate_interactive_page.dart';
import 'package:callme/widgets/category_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _offset = 0.0;

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Bakery', imagePath: 'assets/bakery.png'),
    ServiceCategory(name: 'Photography', imagePath: 'assets/photo.png'),
    ServiceCategory(name: 'Cleaning', imagePath: 'assets/k1.jpg'),
    ServiceCategory(name: 'Carpenter', imagePath: 'assets/carpt.png'),
    ServiceCategory(name: 'Gym', imagePath: 'assets/gym.jfif'),
    ServiceCategory(name: 'Laundry', imagePath: 'assets/laundary.png'),
    ServiceCategory(name: 'Mechanic', imagePath: 'assets/mechanic.png'),
    ServiceCategory(name: 'Water Service', imagePath: 'assets/water.png'),
    ServiceCategory(name: 'Real Estate', imagePath: 'assets/real_estate.png'), // ✅ added
  ];

  String searchQuery = '';
  String selectedCategory = '';

  List<ServiceCategory> get filteredCategories {
    return categories.where((category) {
      final matchesSearch = category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());

      final matchesSelected =
          selectedCategory.isEmpty || category.name == selectedCategory;

      return matchesSearch && matchesSelected;
    }).toList();
  }

  List<ServiceCategory> get filteredHorizontal {
    return categories.where((category) {
      return category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (mounted) {
        setState(() => _offset = _scrollController.offset);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), autoScroll);
  }

  void autoScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    double next = _scrollController.offset + 120;

    if (next >= max) next = 0;

    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(seconds: 4), autoScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'CallMe Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for a service...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  selectedCategory = '';
                });
              },
            ),

            const SizedBox(height: 12),

            // 🔹 Horizontal category list
            SizedBox(
              height: 110,
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  setState(() => _offset = scroll.metrics.pixels);
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredHorizontal.length,
                  itemBuilder: (context, index) {
                    final category = filteredHorizontal[index];
                    final isSelected = selectedCategory == category.name;

                    final width = 106.0;
                    final scale = 1 -
                        (((_offset / width) - index).abs() * 0.18)
                            .clamp(0.0, 0.18);

                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = isSelected ? '' : category.name;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: CategoryCard(
                            name: category.name,
                            imagePath: category.imagePath,
                            showName: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Vertical category list
            Expanded(
              child: ListView.builder(
                itemCount: filteredCategories.length,
                cacheExtent: 700,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () {
                        // ✅ Custom navigation for Real Estate
                      if (category.name == 'Real Estate') {
                          Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RealEstateInteractivePage()),
                  );
                }
                else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailPage(
                                serviceName: category.name,
                              ),
                            ),
                          );
                        }
                      },
                      child: CategoryCard(
                        name: category.name,
                        imagePath: category.imagePath,
                        showName: false,
                      ),
                    ),
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
