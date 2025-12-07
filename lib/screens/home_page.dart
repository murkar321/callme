import 'package:flutter/material.dart';
import '../models/service_category.dart';
import '../widgets/category_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Cleaning', imagePath: 'assets/icons/cleaning.png'),
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/icons/plumbing.png'),
    ServiceCategory(name: 'Electrician', imagePath: 'assets/icons/electrician.png'),
    ServiceCategory(name: 'Salon', imagePath: 'assets/icons/salon.png'),
    ServiceCategory(name: 'Painting', imagePath: 'assets/icons/painting.png'),
    ServiceCategory(name: 'AC Repair', imagePath: 'assets/icons/ac.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Services'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              name: category.name,
              imagePath: category.imagePath,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${category.name} clicked!')),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
