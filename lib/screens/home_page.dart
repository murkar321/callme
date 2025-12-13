import 'package:flutter/material.dart';
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

