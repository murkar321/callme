import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String name;

  /// HomePage
  final String? imagePath;

  /// BusinessPage / service-specific icon (used as fallback when the
  /// image asset fails to load, and as the leading icon on vertical cards)
  final IconData? icon;

  /// Layout
  final bool showName;

  /// 🔥 NEW: navigation callback
  final VoidCallback? onTap;

  /// 🔥 NEW: adaptive width for the horizontal chip card.
  /// Falls back to 90 (original fixed width) if not provided.
  final double? cardWidth;

  const CategoryCard({
    super.key,
    required this.name,
    this.imagePath,
    this.icon,
    this.showName = true,
    this.onTap,
    this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    /// 🔹 HORIZONTAL CARD
    if (showName) {
      final width = cardWidth ?? 90.0;
      content = Container(
        width: width,
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
              child: _buildImageOrIcon(context, width * 0.6),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
                      // 🔥 FIX: previously always fell back to the same
                      // generic icon because callers never passed `icon`.
                      // Now every service gets its own icon from HomePage.
                      icon ?? Icons.miscellaneous_services_rounded,
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
          // 🔥 FIX: fallback now uses the service-specific icon too.
          icon ?? Icons.miscellaneous_services_rounded,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    return Icon(
      icon ?? Icons.miscellaneous_services_rounded,
      size: 40,
      color: Theme.of(context).primaryColor,
    );
  }
}