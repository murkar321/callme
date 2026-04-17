import 'package:callme/data/education_data.dart';
import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/education_detail_page.dart';

class EducationServiceCard extends StatelessWidget {
  final EducationService service;
  final VoidCallback? onUpdate;

  const EducationServiceCard({
    super.key,
    required this.service,
    this.onUpdate,
  });

  double getRating() {
    return 4.0 + (service.id.hashCode % 10) / 10;
  }

  @override
  Widget build(BuildContext context) {
    final qty = Cart.getQuantity(service.id, "Education");

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 IMAGE + TIME BADGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          service.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                /// CATEGORY + RATING
                Row(
                  children: [
                    Text(
                      service.category,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 3),
                    Text(
                      getRating().toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// 🔹 ONE LINE DESCRIPTION
                Text(
                  service.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                /// PRICE
                Text(
                  "₹${service.price}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 BUTTONS
                Row(
                  children: [

                    /// VIEW DETAILS
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EducationDetailPage(
                                  service: service,
                                ),
                              ),
                            ).then((_) => onUpdate?.call());
                          },
                          child: const Text("View"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// ADD TO CART (BOOK)
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            Cart.addItem(
                              id: service.id,
                              name: service.name,
                              price: service.price,
                              service: "Education",
                              category: service.category,
                              image: service.image,
                            );

                            /// 🔥 Refresh UI
                            onUpdate?.call();

                            /// 🔔 Feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "${service.name} added to cart"),
                                duration:
                                    const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(
                            qty == 0 ? "Book" : "Added ($qty)",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}