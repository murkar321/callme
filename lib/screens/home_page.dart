import 'package:callme/models/service_category.dart';
import 'package:flutter/material.dart';
import 'package:callme/screens/booking_page.dart';
import 'package:callme/widgets/app_drawer.dart';
import '../widgets/category_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Classes', imagePath: 'assets/class.jpg'),
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
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
