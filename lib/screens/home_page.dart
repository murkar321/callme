import 'package:flutter/material.dart';
import 'package:callme/screens/booking_page.dart';
import 'package:callme/widgets/app_drawer.dart';
import '../models/service_category.dart';
import '../widgets/category_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Cleaning', imagePath: 'assets/cleaning.jfif'),
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/plumbing.jfif'),
    ServiceCategory(name: 'Electrician', imagePath: 'assets/electrician.jfif'),
    ServiceCategory(name: 'Salon', imagePath: 'assets/salon.jfif'),
    ServiceCategory(name: 'Painting', imagePath: 'assets/painting.jfif'),
    ServiceCategory(name: 'AC Repair', imagePath: 'assets/ac.jfif'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(), // ✅ DRAWER ADDED
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
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75, // image + button balanced
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return CategoryCard(
              name: category.name,
              imagePath: category.imagePath,
              onTap: () {
                // optional category details page
              },
              onBook: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(serviceName: category.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
