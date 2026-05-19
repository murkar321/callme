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

  Color getButtonColor(String category) {
    final cat = category.toLowerCase();

    if (cat.contains("beauty")) {
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔥 IMAGE SECTION
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Container(
              height: 190,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Stack(
                children: [

                  /// 🔥 BLURRED BACKGROUND IMAGE
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.18,
                      child: Image.asset(
                        service.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  /// 🔥 MAIN IMAGE
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        service.image,

                        /// PERFECT FOR MIXED RATIOS
                        fit: BoxFit.contain,
                        alignment: Alignment.center,

                        errorBuilder: (_, __, ___) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 45,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  /// 🔥 GRADIENT OVERLAY
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// ⏱ DURATION BADGE
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.duration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 📄 CONTENT SECTION
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TITLE
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                /// DESCRIPTION
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                /// RATING + PRICE
                Row(
                  children: [

                    const Icon(
                      Icons.star,
                      size: 15,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      getRating().toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// BUTTONS
                Row(
                  children: [

                    /// VIEW BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EducationDetailPage(
                                  service: service,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "View",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// ENQUIRY BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                getButtonColor(service.category),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
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
                                content: Text(
                                  "${service.name} added",
                                ),
                                action: SnackBarAction(
                                  label: "View",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CartPage(
                                          service: "Education",
                                          serviceName: '',
                                          cart: [],
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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