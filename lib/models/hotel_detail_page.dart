import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'package:callme/bookings/hotel_booking_page.dart';

class HotelDetailPage extends StatefulWidget {
  final HotelData hotel;

  const HotelDetailPage({super.key, required this.hotel});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // ✅ Reads from the hotel model — works for every hotel automatically
  List<Map<String, String>> get _galleryImages => widget.hotel.images;

  // ══════════════════════════════════════════════════════════════════
  // FIX (DARK THEME): every surface/text color in this page used to be a
  // hardcoded light-mode value (Colors.white, Colors.grey.shadeXXX,
  // Colors.black87, or a literal hex), so the page never actually
  // responded to Theme.of(context).brightness — it stayed light no
  // matter what the app's theme mode was set to.
  //
  // These getters read brightness once per build and every card/text/
  // placeholder below now goes through them instead of a hardcoded
  // color. Brand/status accents (red app bar, red CTA, green price,
  // orange rating, orange rule icon) are left as-is — they read fine on
  // both light and dark surfaces.
  // ══════════════════════════════════════════════════════════════════
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg =>
      _isDark ? const Color(0xFF121016) : const Color(0xFFF5F6FA);
  Color get _cardBg =>
      _isDark ? const Color(0xFF1E1B27) : Colors.white;
  Color get _textHigh =>
      _isDark ? Colors.white : Colors.black87;
  Color get _textMid =>
      _isDark ? Colors.white70 : Colors.grey.shade800;
  Color get _textLow =>
      _isDark ? Colors.white54 : Colors.grey.shade600;
  Color get _textFaint =>
      _isDark ? Colors.white38 : Colors.grey.shade500;
  Color get _divider =>
      _isDark ? Colors.white24 : Colors.grey.shade300;
  Color get _imgPlaceholder =>
      _isDark ? Colors.white10 : Colors.grey.shade200;
  Color get _imgPlaceholderIcon =>
      _isDark ? Colors.white24 : Colors.grey.shade400;
  // Used for the light-red "Room Types" / highlight-icon chips — the
  // original Colors.red.shade50 is nearly white and would look like a
  // glaring mistake on a dark card.
  Color get _redChipBg =>
      _isDark ? Colors.red.withOpacity(0.18) : Colors.red.shade50;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final discountedPrice =
        hotel.price - (hotel.price * hotel.discount ~/ 100);

    return Scaffold(
      // FIX (DARK THEME): was const Color(0xFFF5F6FA).
      backgroundColor: _pageBg,

      /// ================= APP BAR =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.red,
        title: Text(
          hotel.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= IMAGE CAROUSEL =================
            // FIX: removed the large hotel-name overlay text that used to sit
            // at bottom:48 — it visually collided with the image label chip
            // right above it (bottom:52). The AppBar already shows the hotel
            // name, so it was redundant. The gradient + label chip now have
            // the full image height to themselves.
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
                            // FIX (DARK THEME): placeholder colors were
                            // Colors.grey.shade200/400 — now adaptive.
                            errorBuilder: (_, __, ___) => Container(
                              color: _imgPlaceholder,
                              child: Icon(Icons.image,
                                  size: 60, color: _imgPlaceholderIcon),
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
                          // ✅ Label chip now sits comfortably near the bottom
                          // with no competing overlay text behind it.
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
                if (hotel.discount > 0)
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
                        "${hotel.discount}% OFF",
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
              // FIX (DARK THEME): was Colors.white.
              color: _cardBg,
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
                              ? Colors.red
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
                            color: _imgPlaceholder,
                            child: Icon(Icons.image,
                                size: 24, color: _imgPlaceholderIcon),
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

                  /// ================= LOCATION + RATING =================
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      // FIX (DARK THEME): was Colors.white.
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hotel.location,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  // FIX (DARK THEME): had no color before
                                  // (defaulted to black) — now explicit
                                  // and adaptive.
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _textHigh,
                                  ),
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
                              hotel.rating.toString(),
                              // FIX (DARK THEME): had no color before.
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textHigh,
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
                      // FIX (DARK THEME): was Colors.white.
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹$discountedPrice",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // FIX (DARK THEME): dropped `const` — the "/ night"
                        // text was Colors.grey (fixed), now adaptive.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "/ night",
                            style: TextStyle(
                                color: _textLow, fontSize: 15),
                          ),
                        ),
                        const Spacer(),
                        if (hotel.discount > 0)
                          Text(
                            "₹${hotel.originalPrice}",
                            // FIX (DARK THEME): was Colors.grey.shade500.
                            style: TextStyle(
                              color: _textFaint,
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ================= ROOM HIGHLIGHTS =================
                  _sectionTitle("Room Highlights"),
                  const SizedBox(height: 12),
                  _buildHighlightsGrid(),

                  const SizedBox(height: 24),

                  /// ================= ROOM TYPES (from facilities) =================
                  _sectionTitle("Room Types"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: hotel.facilities.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          // FIX (DARK THEME): was Colors.red.shade50 —
                          // near-white, invisible against a dark card.
                          color: _redChipBg,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          f,
                          // FIX (DARK THEME): dropped `const`, added an
                          // explicit color so text stays legible on the
                          // adaptive chip background.
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _textHigh),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  /// ================= WHAT'S INCLUDED =================
                  _sectionTitle("What's Included"),
                  const SizedBox(height: 12),
                  _buildInclusionsList(),

                  const SizedBox(height: 24),

                  /// ================= DESCRIPTION =================
                  _sectionTitle("Description"),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      // FIX (DARK THEME): was Colors.white.
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      hotel.description,
                      // FIX (DARK THEME): was Colors.grey.shade800.
                      style: TextStyle(
                        fontSize: 15,
                        color: _textMid,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= TIMINGS & RULES =================
                  _sectionTitle("Hotel Timings & Rules"),
                  const SizedBox(height: 12),
                  _buildTimingCard(),
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
            // FIX (DARK THEME): was Colors.white.
            color: _cardBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                  builder: (_) => HotelBookingPage(
                    hotel: hotel,
                    products: [],
                    initialProviderId: hotel.providerId,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= ROOM HIGHLIGHTS GRID =================
  Widget _buildHighlightsGrid() {
    final highlights = [
      {'icon': Icons.king_bed,      'label': 'King Bed',      'sub': 'Premium comfort'},
      {'icon': Icons.wifi,          'label': 'Free WiFi',     'sub': 'High speed'},
      {'icon': Icons.ac_unit,       'label': 'AC Room',       'sub': 'Climate control'},
      {'icon': Icons.restaurant,    'label': 'Breakfast',     'sub': 'Complimentary'},
      {'icon': Icons.local_parking, 'label': 'Parking',       'sub': 'Free parking'},
      {'icon': Icons.room_service,  'label': 'Room Service',  'sub': '24-hour'},
    ];

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
            // FIX (DARK THEME): was Colors.white.
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  // FIX (DARK THEME): was Colors.red.shade50.
                  color: _redChipBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: Colors.red.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                textAlign: TextAlign.center,
                // FIX (DARK THEME): dropped `const`, added explicit color
                // (previously defaulted to black).
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textHigh),
              ),
              const SizedBox(height: 2),
              Text(
                item['sub'] as String,
                textAlign: TextAlign.center,
                // FIX (DARK THEME): was Colors.grey.shade500.
                style: TextStyle(fontSize: 10, color: _textFaint),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= INCLUSIONS LIST =================
  Widget _buildInclusionsList() {
    final inclusions = [
      'Complimentary breakfast for 2 guests',
      'Free high-speed WiFi throughout the stay',
      'Access to banquet & conference facilities',
      'Free parking for registered guests',
      'Welcome drink & complimentary toiletries',
      '24-hour room service & front desk support',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // FIX (DARK THEME): was Colors.white.
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
                    // FIX (DARK THEME): was Colors.grey.shade800.
                    style: TextStyle(fontSize: 14, color: _textMid),
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
  Widget _buildTimingCard() {
    final timings = [
      {'icon': Icons.login,       'label': 'Check-in',   'value': '12:00 PM'},
      {'icon': Icons.logout,      'label': 'Check-out',  'value': '11:00 AM'},
      {'icon': Icons.restaurant,  'label': 'Breakfast',  'value': '7:00 AM – 10:30 AM'},
      {'icon': Icons.local_bar,   'label': 'Bar Hours',  'value': '11:00 AM – 11:00 PM'},
      {'icon': Icons.room_service,'label': 'Room Svc',   'value': '24 Hours'},
    ];

    final rules = [
      'Valid government ID is mandatory at check-in',
      'Outside food & beverages are not permitted',
      'Pets are not allowed on the premises',
      'Smoking is prohibited in all indoor areas',
      'Management reserves the right of admission',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // FIX (DARK THEME): was Colors.white.
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
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
                  Icon(item['icon'] as IconData,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Text(
                      item['label'] as String,
                      // FIX (DARK THEME): dropped `const`, added explicit
                      // color (previously defaulted to black).
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textHigh),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['value'] as String,
                      // FIX (DARK THEME): was Colors.grey.shade700.
                      style: TextStyle(fontSize: 13, color: _textMid),
                    ),
                  ),
                ],
              ),
            );
          }),

          // FIX (DARK THEME): dropped `const`, gave the divider an
          // explicit adaptive color.
          Divider(height: 24, color: _divider),

          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 8),
              // FIX (DARK THEME): dropped `const`, added explicit color
              // (previously defaulted to black).
              Text(
                "Important Rules",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textHigh),
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
                  const Text("• ",
                      style: TextStyle(
                          fontSize: 15, color: Colors.orange)),
                  Expanded(
                    child: Text(
                      rule,
                      // FIX (DARK THEME): was Colors.grey.shade700.
                      style: TextStyle(fontSize: 13, color: _textMid),
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
  Widget _sectionTitle(String title) {
    return Text(
      title,
      // FIX (DARK THEME): dropped `const`, added explicit color
      // (previously defaulted to black).
      style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: _textHigh),
    );
  }
}