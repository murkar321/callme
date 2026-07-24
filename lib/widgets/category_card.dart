// lib/widgets/category_card.dart
import 'package:flutter/material.dart';

class CategoryCard extends StatefulWidget {
  final String name;

  /// HomePage
  final String? imagePath;

  /// BusinessPage / service-specific icon (used as fallback when the
  /// image asset fails to load, and as the leading icon on vertical cards)
  final IconData? icon;

  /// Layout
  final bool showName;

  /// Navigation callback
  final VoidCallback? onTap;

  /// Adaptive width for the horizontal chip card.
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
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;

  /// Soft pastel palette — one is picked deterministically per category
  /// name so the same service always gets the same tint.
  static const List<Color> _pastelPalette = [
    Color(0xFFFFE1E6), // blush pink
    Color(0xFFDCEEFF), // sky blue
    Color(0xFFE1F5E5), // mint
    Color(0xFFFFF1DC), // peach
    Color(0xFFEFE3FB), // lavender
    Color(0xFFFFF9D6), // butter
    Color(0xFFDFF7F5), // aqua
    Color(0xFFFBE3EE), // rose
  ];

  /// Short, friendly subtitles shown on vertical cards instead of the
  /// (now-removed) name label. Falls back to a generic line.
  static const Map<String, String> _subtitles = {
    'Education': 'Courses & tutors, any level',
    'Salon': 'Certified stylists near you',
    'Cleaning': 'Spotless homes, on demand',
    'Resorts': 'Getaways worth booking',
    'Plumbing': 'Fast fixes, trusted hands',
    'Laundry': 'Wash, fold & done',
    'Hotel': 'Comfortable stays, easy booking',
    'Water': 'Reliable water services',
    'Civil Services': 'Skilled work, done right',
  };

  Color _accentFor(String name) =>
      _pastelPalette[name.hashCode.abs() % _pastelPalette.length];

  String _subtitleFor(String name) =>
      _subtitles[name] ?? 'Available nearby • Fast service';

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(widget.name);
    Widget content;

    /// 🔹 HORIZONTAL CARD (keeps the name — this is the quick-pick chip)
    if (widget.showName) {
      final width = widget.cardWidth ?? 90.0;

      // The whole chip body is wrapped in a FittedBox(scaleDown) below.
      // That means no matter how tall the content naturally wants to be
      // (large system font size, long localized names, small screens,
      // etc.) it will shrink to fit instead of overflowing — this is
      // what eliminates the "bottom overflowed by X pixels" error.
      final chipBody = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImageOrIcon(context, width * 0.55, accent),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A2E5C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

      content = Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Guarantees the chip never overflows its allotted height.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: chipBody,
        ),
      );
    }

    /// 🔹 VERTICAL CARD — name removed (already shown above in the chips).
    /// Replaced with a pastel-tinted subtitle + icon badge so the card
    /// still feels distinct and informative, not redundant.
    else {
      content = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼 Thumbnail with a soft gradient + icon badge overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildImageOrIcon(context, double.infinity, accent),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      widget.icon ?? Icons.miscellaneous_services_rounded,
                      size: 16,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ],
            ),

            /// 📄 Info row — subtitle only, no name
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _subtitleFor(widget.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF3A2E5C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    /// 🔥 Tactile press animation for a bit of "liveness"
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: content,
      ),
    );
  }

  /// SAFE IMAGE BUILDER (prevents crash)
  Widget _buildImageOrIcon(BuildContext context, double size, Color accent) {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.asset(
        widget.imagePath!,
        height: size == double.infinity ? null : size,
        width: size == double.infinity ? double.infinity : size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: accent.withOpacity(0.4),
          alignment: Alignment.center,
          child: Icon(
            widget.icon ?? Icons.miscellaneous_services_rounded,
            size: 36,
            color: const Color(0xFF6C5CE7),
          ),
        ),
      );
    }

    return Container(
      color: accent.withOpacity(0.4),
      alignment: Alignment.center,
      child: Icon(
        widget.icon ?? Icons.miscellaneous_services_rounded,
        size: 36,
        color: const Color(0xFF6C5CE7),
      ),
    );
  }
}