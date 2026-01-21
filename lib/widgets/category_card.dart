import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final String name;
  final String imagePath;
  final bool showName; // true for horizontal, false for vertical

  const CategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.showName = true,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  final double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    // 🔹 Determine size dynamically
    double cardWidth;
    double cardHeight;

    if (widget.showName) {
      // Horizontal cards: fixed width, smaller height
      cardWidth = 90;
      cardHeight = 110;
    } else {
      // Vertical cards: adapt to screen width, maintain 16:9 aspect ratio
      final screenWidth = MediaQuery.of(context).size.width;
      cardWidth = screenWidth * 0.9; // 90% of screen width
      cardHeight = cardWidth * 9 / 16; // 16:9 aspect ratio
    }

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.85, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 130),
          scale: _scale,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 🔹 Image fills container and keeps aspect ratio
              Positioned.fill(
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              // 🔹 Optional name text (horizontal cards)
              if (widget.showName)
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
