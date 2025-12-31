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
  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Classes', imagePath: 'assets/class.jpg'),
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/plumbing.jfif'),
    ServiceCategory(name: 'Electrician', imagePath: 'assets/electrician.jfif'),
    ServiceCategory(name: 'Salon', imagePath: 'assets/salon.jfif'),
    ServiceCategory(name: 'Painting', imagePath: 'assets/painting.jfif'),
    ServiceCategory(name: 'AC Repair', imagePath: 'assets/ac.jfif'),
  ];

  String searchQuery = '';
  String selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    // Filter grid items based on search or selected category
    final filteredCategories = categories.where((category) {
      final matchesSearch =
          category.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesSelected =
          selectedCategory.isEmpty || category.name == selectedCategory;
      return matchesSearch && matchesSelected;
    }).toList();

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
<<<<<<< HEAD
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CategoryCard(
                name: category.name,
                imagePath: category.imagePath,
                onTap: () {},
                onBook: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(serviceName: category.name),
=======
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar first
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
                });
              },
            ),

            const SizedBox(height: 12),

            // 🖼️ Horizontal category image list
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category.name;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedCategory == category.name) {
                          selectedCategory = ''; // unselect
                        } else {
                          selectedCategory = category.name;
                        }
                      });
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
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
>>>>>>> 0211842ef15b259eca8fadcec8edd7ce56098ee4
                    ),
                  );
                },
              ),
<<<<<<< HEAD
            );
          },
=======
            ),

            const SizedBox(height: 12),

            // 🧰 GridView for service cards
            Expanded(
              child: GridView.builder(
                itemCount: filteredCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  return CategoryCard(
                    name: category.name,
                    imagePath: category.imagePath,
                    onTap: () {},
                    onBook: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingPage(serviceName: category.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
>>>>>>> 0211842ef15b259eca8fadcec8edd7ce56098ee4
        ),
      ),
    );
  }
}
