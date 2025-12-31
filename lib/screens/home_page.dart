import 'package:callme/models/service_category.dart';
import 'package:flutter/material.dart';
import 'package:callme/screens/booking_page.dart';
import 'package:callme/widgets/app_drawer.dart';
import '../widgets/category_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _offset = 0.0;

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Classes', imagePath: 'assets/class.jpg'),
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/plumbing.jfif'),
    ServiceCategory(name: 'Electrician', imagePath: 'assets/electrician.jfif'),
    ServiceCategory(name: 'Salon', imagePath: 'assets/salon.jfif'),
    ServiceCategory(name: 'Painting', imagePath: 'assets/painting.jfif'),
    ServiceCategory(name: 'AC Repair', imagePath: 'assets/ac.jfif'),
    ServiceCategory(name: 'Carpenter', imagePath: 'assets/carpenter.jfif'),
    ServiceCategory(name: 'Cleaning', imagePath: 'assets/cleaning.jfif'),
    ServiceCategory(name: 'Technician', imagePath: 'assets/technician.jfif'),
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

    double max = _scrollController.position.maxScrollExtent;
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
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Home Services',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Box
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
                  // Clear selected category when typing
                  if (selectedCategory.isNotEmpty) selectedCategory = '';
                });
              },
            ),
            const SizedBox(height: 12),

            // 🔹 Horizontal Carousel
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
                  padding: const EdgeInsets.only(left: 6),
                  itemCount: filteredHorizontal.length,
                  itemBuilder: (context, index) {
                    final category = filteredHorizontal[index];
                    final isSelected = selectedCategory == category.name;

                    final width = 90.0 + 16.0;
                    final scale = 1 -
                        (((_offset / width) - index).abs() * 0.18)
                            .clamp(0.0, 0.18);

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: 1.0,
                      child: Transform.scale(
                        scale: scale,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory =
                                    selectedCategory == category.name
                                        ? ''
                                        : category.name;
                              });
                            },
                            child: Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.22),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      category.imagePath,
                                      height: 55,
                                      width: 55,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Vertical List – Clickable + Navigates
            Expanded(
              child: ListView.builder(
                itemCount: filteredCategories.length,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(serviceName: category.name),
                          ),
                        );
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
