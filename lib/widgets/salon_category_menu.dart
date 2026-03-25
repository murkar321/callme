import 'package:flutter/material.dart';
import '../data/salon_data.dart';

class SalonCategoryMenu extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final Color primaryColor;

  const SalonCategoryMenu({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    /// responsive menu width
    double menuWidth = 100;

    if (width < 600) {
      menuWidth = 85;
    } else if (width < 1000) {
      menuWidth = 95;
    } else {
      menuWidth = 110;
    }

    return Container(
      width: menuWidth,
      color: Colors.white,

      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,

        itemBuilder: (context, index) {

          final category = categories[index];
          final isSelected = category == selectedCategory;

          /// safe first service
          final firstService = salonServices
              .where((s) => s.category == category)
              .toList();

          final image = firstService.isNotEmpty
              ? firstService.first.image
              : "assets/salon.png";

          return InkWell(
            onTap: () => onCategorySelected(category),

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              margin: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),

              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 6,
              ),

              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.grey.shade200,
                ),
              ),

              child: Column(
                children: [

                  /// IMAGE
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: AssetImage(image),
                  ),

                  const SizedBox(height: 6),

                  /// CATEGORY TEXT
                  Text(
                    category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? primaryColor
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}