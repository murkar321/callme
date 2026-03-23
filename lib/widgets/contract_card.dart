import 'package:callme/models/civil_detail_page.dart';
import 'package:flutter/material.dart';
import '../models/service_product.dart';



class CivilServiceCard extends StatelessWidget {
  final ServiceProduct service;
  final VoidCallback onAddCart;

  const CivilServiceCard({super.key, required this.service, required this.onAddCart});

  @override
  Widget build(BuildContext context) {
    final String imagePath = service.imagePath.isNotEmpty ? service.imagePath : 'assets/civil.png';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(imagePath, height: 75, width: 75, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(service.slogan ?? "", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
                    Text("${service.price}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Text("Booking", style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 12)), onPressed: onAddCart, child: const Text("Add Booking", style: TextStyle(fontSize: 12))),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CivilDetailPage(service: service)));
                      },
                      child: const Text("View Details", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}