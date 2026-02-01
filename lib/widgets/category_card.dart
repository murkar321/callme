import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final bool showName; // true = horizontal, false = vertical

  const CategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showName) {
      // 🔹 HORIZONTAL CARD (UNCHANGED LOGIC)
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
              child: Image.asset(
                imagePath,
                height: 55,
                width: 55,
                fit: BoxFit.cover,
                cacheWidth: 200,
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

    // 🔹 VERTICAL CARD (YOUTUBE STYLE)
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
          // 🖼 Thumbnail (16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              cacheWidth: 800,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported),
              ),
            ),
          ),

          // 📄 Info section (like YouTube)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left icon (channel-style)
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.miscellaneous_services,
                    size: 18,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 10),

                // Title + subtitle
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

                // More options icon
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
