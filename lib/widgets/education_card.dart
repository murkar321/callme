import 'package:callme/models/cart.dart';
import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../models/education_detail_page.dart';
import '../models/cart_page.dart';

class EducationServiceCard extends StatelessWidget {
  final EducationService service;
  final VoidCallback onUpdate;

  const EducationServiceCard({
    super.key,
    required this.service,
    required this.onUpdate,
  });

  double getRating() {
    return 4.0 + (service.id.hashCode % 10) / 10;
  }

  /// 🎨 COLOR LOGIC
  Color getButtonColor(String category) {
    final cat = category.toLowerCase();

    if (cat.contains("beautician")) {
      return const Color(0xFFE91E63);
    }

    if (cat.contains("network") ||
        cat.contains("data") ||
        cat.contains("software")) {
      return Colors.blue;
    }

    return const Color(0xFFAE91BA);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🖼 IMAGE (IMPROVED)
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.asset(
                  service.image,
                  height: width * 0.42, // responsive height
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// ⏱ DURATION BADGE
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
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          service.duration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 📄 CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                /// DESCRIPTION
                Text(
                  service.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                /// ⭐ RATING + 💰 PRICE (ONE LINE)
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      getRating().toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
                    ),

                    const Spacer(),

                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// 🔘 BUTTONS (SMALL + CLEAN)
                Row(
                  children: [

                    /// VIEW
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side:
                                const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EducationDetailPage(
                                        service: service),
                              ),
                            );
                          },
                          child: const Text(
                            "View",
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// ENQUIRY
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor:
                                getButtonColor(service.category),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Cart.addEducation(
                              id: service.id,
                              name: service.name,
                              price: service.finalPrice,
                              category: service.category,
                              image: service.image,
                            );

                            onUpdate();

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                    Text("${service.name} added"),
                                action: SnackBarAction(
                                  label: "View",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CartPage(
                                          service: "Education", serviceName: '', cart: [],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Enquiry",
                            style: TextStyle(fontSize: 13),
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