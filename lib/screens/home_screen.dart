import 'package:flutter/material.dart';
import '../widgets/service_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Electrician wala', 'image': 'assets/electrician.png'},
      {'name': 'Plumber wala', 'image': 'assets/plumber.png'},
      {'name': 'Beautician', 'image': 'assets/beautician.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CallMe'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return ServiceCard(
                    name: services[index]['name']!,
                    imagePath: services[index]['image']!,
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
