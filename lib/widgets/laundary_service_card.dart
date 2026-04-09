import 'package:flutter/material.dart';
import 'package:callme/models/luandary_detail_page.dart';
import 'package:callme/models/service_product.dart';

class LaundryServiceCard extends StatelessWidget {
  final ServiceProduct service;
  final String serviceName;
  final String category;

  const LaundryServiceCard({
    super.key,
    required this.service,
    required this.serviceName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => LaundryDetailPage(
            product: service,
            serviceName: serviceName,
            category: category,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            )
          ],
        ),
        child: Row(
          children: [

            /// 🖼 IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                service.imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 12),

            /// 📄 DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// DESCRIPTION
                  Text(
                    service.description ??
                        "Laundry Service",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  /// PRICE
                  Text(
                    "₹${service.calculatedFinalPrice}",
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            /// ➡️ VIEW ICON
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}