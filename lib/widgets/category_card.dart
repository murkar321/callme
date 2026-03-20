import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;

  /// HomePage
  final String? imagePath;

  /// BusinessPage
  final IconData? icon;

  /// Layout
  final bool showName;

  /// 🔥 NEW: navigation callback
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.name,
    this.imagePath,
    this.icon,
    this.showName = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    /// 🔹 HORIZONTAL CARD
    if (showName) {
      content = Container(
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
              child: _buildImageOrIcon(context, 55),
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

    /// 🔹 VERTICAL CARD
    else {
      content = Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼 Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImageOrIcon(context, double.infinity),
            ),

            /// 📄 Info
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

    /// 🔥 MAKE CARD CLICKABLE
    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }

  /// 🔥 SAFE IMAGE BUILDER (prevents crash)
  Widget _buildImageOrIcon(BuildContext context, double size) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        height: size == double.infinity ? null : size,
        width: size == double.infinity ? double.infinity : size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          icon ?? Icons.miscellaneous_services,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    return Icon(
      icon ?? Icons.miscellaneous_services,
      size: 40,
      color: Theme.of(context).primaryColor,
    );
  }
}
