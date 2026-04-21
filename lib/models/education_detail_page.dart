import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class EducationDetailPage extends StatelessWidget {
  final EducationService service;

  const EducationDetailPage({
    super.key,
    required this.service,
  });

  /// 🎨 SAME COLOR LOGIC AS CARD
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

  Widget buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ",
                    style: TextStyle(fontSize: 14)),
                Expanded(child: Text(e)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(service.name),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🖼 IMAGE + TITLE
            Stack(
              children: [
                Image.asset(
                  service.image,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            /// 📦 CONTENT
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// ⏱ DURATION
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("Duration: ${service.duration}"),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// 💰 PRICE (NO DISCOUNT UI)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            blurRadius: 4,
                            color: Colors.black12)
                      ],
                    ),
                    child: Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 📄 DESCRIPTION
                  const Text(
                    "About this course",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(service.description),

                  const SizedBox(height: 16),

                  /// ✅ INCLUDES
                  buildSection("What you'll learn", service.includes),

                  /// ❌ EXCLUDES
                  if (service.excludes.isNotEmpty)
                    buildSection("Not included", service.excludes),

                  /// 🔄 STEPS
                  if (service.steps.isNotEmpty)
                    buildSection("Course flow", service.steps),

                  /// 🧰 TOOLS
                  if (service.tools.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tools & Materials",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(service.tools),
                        const SizedBox(height: 16),
                      ],
                    ),

                  /// 🛡 WARRANTY
                  if (service.warranty.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Support",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(service.warranty),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// 🔻 SINGLE ACTION (FINAL FLOW)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: SizedBox(
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  getButtonColor(service.category),
            ),
            onPressed: () {

              /// ADD TO CART
              Cart.addEducation(
                id: service.id,
                name: service.name,
                price: service.finalPrice,
                category: service.category,
                image: service.image,
              );

              /// SNACKBAR
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text("${service.name} added"),
                  action: SnackBarAction(
                    label: "View Courses",
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
            child: const Text("Enquiry"),
          ),
        ),
      ),
    );
  }
}