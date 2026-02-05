import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;

  // HomePage uses this
  final String? imagePath;

  // BusinessPage uses this
  final IconData? icon;

  final bool showName; // true = horizontal, false = vertical

  const CategoryCard({
    super.key,
    required this.name,
    this.imagePath,
    this.icon,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 HORIZONTAL CARD
    if (showName) {
      return Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.22),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (imagePath != null && imagePath!.isNotEmpty)
                  ? Image.asset(
                      imagePath!,
                      height: 55,
                      width: 55,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      icon ?? Icons.miscellaneous_services,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 🔹 VERTICAL CARD
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(
              child: (imagePath != null && imagePath!.isNotEmpty)
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Icon(
                      icon ?? Icons.miscellaneous_services,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
          ),

          // 📄 Info section
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    icon ?? Icons.miscellaneous_services,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available nearby • Fast service',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
