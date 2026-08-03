import 'package:flutter/material.dart';
import 'package:callme/bookings/resort_booking.dart';
import '../data/resorts_data.dart';

class ResortDetailPage extends StatefulWidget {
  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort,
  });

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  List<Map<String, String>> get _galleryImages => widget.resort.images;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resort = widget.resort;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ THEME FIX: every background/text/border color below now branches
    // on isDark instead of the previous hardcoded light-mode values
    // (Color(0xFFF5F6FA), Colors.white, Colors.black87, etc).
    final Color scaffoldBg =
        isDark ? const Color(0xFF121016) : const Color(0xFFF5F6FA);
    final Color cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText =
        isDark ? Colors.white70 : Colors.grey.shade800;
    final Color mutedText = isDark ? Colors.white54 : Colors.grey.shade600;
    final Color shadowColor = Colors.black.withOpacity(isDark ? 0.35 : 0.04);
    final Color thumbStripBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color placeholderBg =
        isDark ? const Color(0xFF262430) : Colors.grey.shade200;
    final Color placeholderIcon =
        isDark ? Colors.white24 : Colors.grey.shade400;
    final Color facilityChipBg = isDark
        ? Colors.blue.withOpacity(0.15)
        : Colors.blue.shade50;
    final Color facilityChipText = isDark ? Colors.blue.shade200 : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: Text(
          resort.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= IMAGE CAROUSEL =================
            Stack(
              children: [

                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _galleryImages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [

                          // ✅ BLUR FIX: FilterQuality.high replaces the
                          // default FilterQuality.low bilinear filter, which
                          // looked soft/blurry whenever the source image was
                          // scaled to fit this box. gaplessPlayback avoids a
                          // blank flash while swapping pages.
                          Image.asset(
                            _galleryImages[index]['path']!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => Container(
                              color: placeholderBg,
                              child: Icon(Icons.image,
                                  size: 60, color: placeholderIcon),
                            ),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.55),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          Positioned(
                            left: 16,
                            bottom: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _galleryImages[index]['label']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                /// DISCOUNT BADGE
                if (resort.discount > 0)
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "${resort.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                /// DOT INDICATORS
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _galleryImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentImageIndex == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                /// LEFT ARROW
                if (_currentImageIndex > 0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),

                /// RIGHT ARROW
                if (_currentImageIndex < _galleryImages.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// ================= THUMBNAIL STRIP =================
            Container(
              height: 72,
              color: thumbStripBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // ✅ BLUR FIX: same FilterQuality.high treatment for
                        // the small thumbnails, which showed the softness
                        // most obviously since they're scaled down hard.
                        child: Image.asset(
                          _galleryImages[index]['path']!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(
                            color: placeholderBg,
                            child: Icon(Icons.image,
                                size: 24, color: placeholderIcon),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ================= TAGLINE =================
                  Text(
                    resort.tagline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// ================= LOCATION + RATING =================
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      resort.location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: primaryText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  resort.rating.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: primaryText),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.directions,
                                color: mutedText, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                resort.distanceInfo,
                                style: TextStyle(
                                    fontSize: 12.5, color: mutedText),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// ================= PRICE =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${resort.price}",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "/ person",
                            style: TextStyle(color: mutedText, fontSize: 15),
                          ),
                        ),
                        const Spacer(),
                        if (resort.originalPrice > resort.price)
                          Text(
                            "₹${resort.originalPrice}",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500,
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ================= HIGHLIGHTS =================
                  _sectionTitle("Resort Highlights", primaryText),
                  const SizedBox(height: 12),
                  _buildHighlightsGrid(
                    resort.highlights,
                    isDark: isDark,
                    cardBg: cardBg,
                    shadowColor: shadowColor,
                    primaryText: primaryText,
                    mutedText: mutedText,
                  ),

                  const SizedBox(height: 24),

                  /// ================= FACILITIES =================
                  _sectionTitle("Facilities", primaryText),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: resort.facilities.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: facilityChipBg,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: facilityChipText)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  /// ================= WHAT'S INCLUDED =================
                  _sectionTitle("What's Included", primaryText),
                  const SizedBox(height: 12),
                  _buildInclusionsList(
                    resort.inclusions,
                    cardBg: cardBg,
                    shadowColor: shadowColor,
                    secondaryText: secondaryText,
                  ),

                  const SizedBox(height: 24),

                  /// ================= DESCRIPTION =================
                  _sectionTitle("Description", primaryText),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      resort.description,
                      style: TextStyle(
                          fontSize: 15, color: secondaryText, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= TIMINGS & RULES =================
                  _sectionTitle("Resort Timings & Rules", primaryText),
                  const SizedBox(height: 12),
                  _buildTimingCard(
                    resort.timings,
                    resort.rules,
                    isDark: isDark,
                    cardBg: cardBg,
                    shadowColor: shadowColor,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// ================= BOOK BUTTON =================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: cardBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ResortBookingPage(resort: widget.resort),
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HIGHLIGHTS GRID =================
  Widget _buildHighlightsGrid(
    List<HighlightItem> highlights, {
    required bool isDark,
    required Color cardBg,
    required Color shadowColor,
    required Color primaryText,
    required Color mutedText,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: highlights.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = highlights[index];
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 6),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                    size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryText),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: mutedText),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= INCLUSIONS LIST =================
  Widget _buildInclusionsList(
    List<String> inclusions, {
    required Color cardBg,
    required Color shadowColor,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8),
        ],
      ),
      child: Column(
        children: inclusions.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 14, color: secondaryText),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= TIMING CARD =================
  Widget _buildTimingCard(
    List<TimingItem> timings,
    List<String> rules, {
    required bool isDark,
    required Color cardBg,
    required Color shadowColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ...timings.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(item.icon,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade600,
                      size: 18),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryText),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: TextStyle(fontSize: 13, color: secondaryText),
                    ),
                  ),
                ],
              ),
            );
          }),

          Divider(
              height: 24, color: isDark ? Colors.white12 : null),

          Row(
            children: [
              Icon(Icons.info_outline,
                  color: isDark ? Colors.orange.shade300 : Colors.orange.shade600,
                  size: 18),
              const SizedBox(width: 8),
              Text(
                "Important Rules",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...rules.map((rule) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ",
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.orange.shade300
                              : Colors.orange)),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(fontSize: 13, color: secondaryText),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: color),
    );
  }
}