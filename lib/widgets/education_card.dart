import 'package:callme/models/cart.dart';
import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../models/education_detail_page.dart';

class EducationServiceCard extends StatelessWidget {
  final EducationService service;
  final VoidCallback onUpdate;

  const EducationServiceCard({
    super.key,
    required this.service,
    required this.onUpdate,
  });

  Color _accentColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("beauty")) return const Color(0xFFE91E63);
    if (cat.contains("network") ||
        cat.contains("data") ||
        cat.contains("software")) return const Color(0xFF2563EB);
    return const Color(0xFFAE91BA);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(service.category);
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    // Adaptive scaling — base 390w, 844h
    final double wScale = (sw / 390).clamp(0.75, 1.3);
    final double hScale = (sh / 844).clamp(0.75, 1.3);

    // Adaptive image height: ~21% of screen height, clamped
    final double imageHeight = (sh * 0.21).clamp(140.0, 220.0);

    // Adaptive font sizes
    final double titleSize = (15 * wScale).clamp(13.0, 18.0);
    final double descSize = (12.5 * wScale).clamp(11.0, 15.0);
    final double btnFontSize = (13 * wScale).clamp(11.5, 15.0);
    final double chipFontSize = (10 * wScale).clamp(9.0, 12.0);
    final double badgeFontSize = (11 * wScale).clamp(9.5, 13.0);

    // Adaptive button height
    final double btnHeight = (42 * hScale).clamp(38.0, 52.0);

    // Adaptive padding
    final double cardPadding = (14 * wScale).clamp(10.0, 18.0);
    final double contentGap = (5 * hScale).clamp(4.0, 8.0);
    final double sectionGap = (14 * hScale).clamp(10.0, 20.0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: (12 * wScale).clamp(8.0, 16.0),
        vertical: (8 * hScale).clamp(6.0, 12.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((20 * wScale).clamp(14.0, 26.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ prevents unbounded height overflow
        children: [

          // ── IMAGE ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular((20 * wScale).clamp(14.0, 26.0)),
            ),
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  // Blurred bg
                  Opacity(
                    opacity: 0.18,
                    child: Image.asset(service.image, fit: BoxFit.cover),
                  ),

                  // Main image contained
                  Padding(
                    padding: EdgeInsets.all((10 * wScale).clamp(6.0, 14.0)),
                    child: Image.asset(
                      service.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: (40 * wScale).clamp(28.0, 52.0),
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.38),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Category chip — top left
                  Positioned(
                    top: (10 * hScale).clamp(6.0, 14.0),
                    left: (10 * wScale).clamp(6.0, 14.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (10 * wScale).clamp(7.0, 14.0),
                        vertical: (4 * hScale).clamp(3.0, 6.0),
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.category,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: chipFontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Duration badge — bottom right
                  Positioned(
                    bottom: (10 * hScale).clamp(6.0, 14.0),
                    right: (10 * wScale).clamp(6.0, 14.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (9 * wScale).clamp(6.0, 12.0),
                        vertical: (4 * hScale).clamp(3.0, 6.0),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: (11 * wScale).clamp(9.0, 14.0),
                            color: Colors.white,
                          ),
                          SizedBox(width: (4 * wScale).clamp(2.0, 6.0)),
                          Text(
                            service.duration,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: badgeFontSize,
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

          // ── CONTENT ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              cardPadding,
              cardPadding,
              cardPadding,
              cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ no overflow in column
              children: [

                // Course name
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),

                SizedBox(height: contentGap),

                // Description
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: descSize,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),

                SizedBox(height: sectionGap),

                // ── BUTTONS ──────────────────────────────────────────
                IntrinsicHeight( // ✅ keeps both buttons same height safely
                  child: Row(
                    children: [

                      // View Details
                      Expanded(
                        child: SizedBox(
                          height: btnHeight,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (12 * wScale).clamp(8.0, 16.0),
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EducationDetailPage(service: service),
                                ),
                              );
                            },
                            child: Text(
                              "View",
                              style: TextStyle(
                                fontSize: btnFontSize,
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: (10 * wScale).clamp(6.0, 14.0)),

                      // Enquiry
                      Expanded(
                        child: SizedBox(
                          height: btnHeight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (12 * wScale).clamp(8.0, 16.0),
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              Cart.addEducation(
                                id: service.id,
                                name: service.name,
                                price: 0,
                                category: service.category,
                                image: service.image,
                              );
                              onUpdate();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_outlined,
                                  size: (14 * wScale).clamp(11.0, 18.0),
                                ),
                                SizedBox(width: (5 * wScale).clamp(3.0, 8.0)),
                                Text(
                                  "Enquiry",
                                  style: TextStyle(
                                    fontSize: btnFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}